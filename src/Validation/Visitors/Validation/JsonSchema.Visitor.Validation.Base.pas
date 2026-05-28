unit JsonSchema.Visitor.Validation.Base;

interface

uses
  System.JSON,
  System.Generics.Collections,
  JsonSchema.Types,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Types,
  JsonSchema.Validation.Base,
  JsonSchema.Validation.Interfaces,
  JsonSchema.Common.Utils,
  JsonSchema.FormatValidator,
  JsonSchema.JsonPathUtils,
  JsonSchema.Walker,
  JsonSchema.Walker.Types;

type
  /// <summary>
  ///   Base visitor that handles the JSON Schema Validation vocabulary keywords.
  ///   Provides default implementations for all validation keywords.
  ///   Draft‑specific visitors can override individual methods as needed.
  /// </summary>
  TBaseValidationVisitor<T: IValidationVisitor<T>> = class(TBase<T>, IBaseValidationVisitor<T>)
  protected
    /// <summary>Returns the typed validation visitor for error reporting and scope management.</summary>
    function GetValidationVisitor: IValidationVisitor<T>;

    /// <summary>Checks whether the validation vocabulary is in silent mode (no validation).</summary>
    function IsSilentMode: Boolean;

    /// <summary>Checks whether format assertions are enabled (only relevant for Draft 2020‑12).</summary>
    function IsFormatAssertionEnabled: Boolean;

    /// <summary>
    ///   Evaluates a sub‑schema against the current instance at a given path.
    ///   Creates a new scope and walks the sub‑schema.
    ///   Returns True if the sub‑validation succeeded.
    /// </summary>
    function EvaluateSubSchema(const pSubSchema: TJSONValue; const pInstanceNode: TJSONValue;
      const pSchemaPathSuffix, pInstancePathSuffix: string): Boolean;

    /// <summary>Normalises a scope's covered items/properties after a successful sub‑validation.</summary>
    procedure MergeSubScope(const pSubScope: TScope; var pParentScope: TScope);

    /// <summary>Adds an evaluated property path to the current scope and result.</summary>
    procedure AddEvaluatedProperty(const pPropertyPath: string);

    /// <summary>Adds a covered item index to the current scope.</summary>
    procedure AddCoveredItem(const pIndex: Integer);

    /// <summary>Adds a covered property name to the current scope.</summary>
    procedure AddCoveredProperty(const pPropertyName: string);
  public
    // General
    [VisitorKeyword('type')]
    procedure VisitType(const pValue: TJSONValue); virtual;

    [VisitorKeyword('enum')]
    procedure VisitEnum(const pValue: TJSONArray); virtual;

    [VisitorKeyword('const')]
    procedure VisitConst(const pValue: TJSONValue); virtual;

    // Content (annotation only in modern drafts, but validation in older)
    [VisitorKeyword('contentEncoding')]
    procedure VisitContentEncoding(const pValue: TJSONString); virtual;

    [VisitorKeyword('contentMediaType')]
    procedure VisitContentMediaType(const pValue: TJSONString); virtual;
  end;

implementation

uses
  System.SysUtils,
  System.Math,
  System.StrUtils,
  System.NetEncoding,
  System.RegularExpressions,
  System.TypInfo;

{ TBaseValidationVisitor<T> }

function TBaseValidationVisitor<T>.GetValidationVisitor: IValidationVisitor<T>;
begin
  Supports(Visitor, IValidationVisitor<T>, Result);
end;

function TBaseValidationVisitor<T>.IsSilentMode: Boolean;
var
  lMode: IDraft2019_09ValidationVocabularyMode;
begin
  Result := False;
  if Supports(Visitor, IDraft2019_09ValidationVocabularyMode, lMode) then
    Result := lMode.IsValidationVocabularySilent;
end;

function TBaseValidationVisitor<T>.IsFormatAssertionEnabled: Boolean;
var
  lMode: IDraftFormatAssertionMode;
begin
  Result := True; // Default for drafts prior to 2020‑12
  if Supports(Visitor, IDraftFormatAssertionMode, lMode) then
    Result := lMode.IsFormatAssertionEnabled;
end;

function TBaseValidationVisitor<T>.EvaluateSubSchema(const pSubSchema, pInstanceNode: TJSONValue;
  const pSchemaPathSuffix, pInstancePathSuffix: string): Boolean;
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lSubVisitor: IValidationVisitor<T>;
  lWalker: IWalker;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit(False);

  lScope := lVisitor.CurrentScope;
  lSubVisitor := lVisitor.New(pSubSchema, pInstanceNode, lScope.BaseURI);

  // Prepare child scope
  lScope.SchemaPath := TJsonPathUtils.JoinPath(lScope.SchemaPath, pSchemaPathSuffix);
  lScope.SchemaNode := pSubSchema;
  lScope.InstancePath := TJsonPathUtils.JoinPath(lScope.InstancePath, pInstancePathSuffix);
  lScope.InstanceNode := pInstanceNode;
  lScope.CoveredItems := [];
  lScope.ContainsCount := 0;
  lScope.VisitedKeywords := [];
  lScope.CoveredProperties := [];
  lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

  // Copy parent evaluated properties (if any) into child scope
  if Assigned(lVisitor.CurrentScope(0).EvaluatedPropertiesInScope) then
    for var lProp in lVisitor.CurrentScope(0).EvaluatedPropertiesInScope do
      lScope.EvaluatedPropertiesInScope.Add(lProp);

  lSubVisitor.PushScope(lScope);
  try
    lWalker := TWalker<T>.Create(pSubSchema, lSubVisitor);
    lWalker.Walk;
    Result := lSubVisitor.Result.IsValid;
  finally
    lScope := lSubVisitor.PopScope;
    var lParentScope := lVisitor.CurrentScope(0);
    MergeSubScope(lScope, lParentScope);
    lVisitor.UpdateScope(lParentScope);
  end;
end;

procedure TBaseValidationVisitor<T>.MergeSubScope(const pSubScope: TScope; var pParentScope: TScope);
begin
  // Merge covered items and properties
  pParentScope.CoveredItems := TUtils.MergeArray<Integer>([pParentScope.CoveredItems, pSubScope.CoveredItems]);
  pParentScope.CoveredProperties := TUtils.MergeArray<string>([pParentScope.CoveredProperties, pSubScope.CoveredProperties]);

  // Merge evaluated properties
  if Assigned(pSubScope.EvaluatedPropertiesInScope) then
  begin
    if not Assigned(pParentScope.EvaluatedPropertiesInScope) then
      pParentScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
    for var lProp in pSubScope.EvaluatedPropertiesInScope do
      pParentScope.EvaluatedPropertiesInScope.Add(lProp);
  end;
end;

procedure TBaseValidationVisitor<T>.AddEvaluatedProperty(const pPropertyPath: string);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;
  lScope := lVisitor.CurrentScope;
  lVisitor.Result.AddEvaluatedProperty(pPropertyPath);
  if not Assigned(lScope.EvaluatedPropertiesInScope) then
    lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
  lScope.EvaluatedPropertiesInScope.Add(TJsonPathUtils.NormalizeToCanonical(pPropertyPath));
  lVisitor.UpdateScope(lScope);
end;

procedure TBaseValidationVisitor<T>.AddCoveredItem(const pIndex: Integer);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;
  lScope := lVisitor.CurrentScope;
  TUtils.AddArray<Integer>(lScope.CoveredItems, pIndex);
  lVisitor.UpdateScope(lScope);
end;

procedure TBaseValidationVisitor<T>.AddCoveredProperty(const pPropertyName: string);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;
  lScope := lVisitor.CurrentScope;
  TUtils.AddArray<string>(lScope.CoveredProperties, pPropertyName);
  lVisitor.UpdateScope(lScope);
end;

// General
procedure TBaseValidationVisitor<T>.VisitType(const pValue: TJSONValue);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lAllowedTypes: TList<string>;
  lType: TJSONValue;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  if IsSilentMode then
    Exit;

  lScope := lVisitor.CurrentScope;
  lAllowedTypes := TList<string>.Create;
  try
    if pValue is TJSONString then
    begin
      if TJSONString(pValue).Value = 'number' then
        lAllowedTypes.AddRange(['integer', 'number'])
      else
        lAllowedTypes.Add(TJSONString(pValue).Value.ToLower);
    end
    else if pValue is TJSONArray then
    begin
      for lType in TJSONArray(pValue) do
        if lType.Value = 'number' then
          lAllowedTypes.AddRange(['integer', 'number'])
        else
          lAllowedTypes.Add(lType.Value.ToLower);
    end;

    if not lAllowedTypes.Contains(TUtils.JsonGetType(lScope.InstanceNode)) then
      lVisitor.AddError(TErrorType.vetInvalidType,
        [string.Join(', ', lAllowedTypes.ToArray), TUtils.JsonGetType(lScope.InstanceNode)]);
  finally
    lAllowedTypes.Free;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitEnum(const pValue: TJSONArray);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lValid: Boolean;
  lEnumValue: TJSONValue;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  if IsSilentMode then
    Exit;

  lScope := lVisitor.CurrentScope;
  lValid := False;
  for lEnumValue in pValue do
    if TUtils.JsonEquals(lScope.InstanceNode, lEnumValue) then
    begin
      lValid := True;
      Break;
    end;

  if not lValid then
    lVisitor.AddError(TErrorType.vetEnumValueMismatch, [pValue.ToString]);
end;

procedure TBaseValidationVisitor<T>.VisitConst(const pValue: TJSONValue);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  if IsSilentMode then
    Exit;

  lScope := lVisitor.CurrentScope;
  if not TUtils.JsonEquals(lScope.InstanceNode, pValue) then
    lVisitor.AddError(TErrorType.vetConstValueMismatch, [pValue.ToString]);
end;

// Content
procedure TBaseValidationVisitor<T>.VisitContentEncoding(const pValue: TJSONString);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lInstanceValue: string;
  lIsAnnotationOnly: Boolean;
  lKey: string;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'string' then
    Exit;

  // Detect if this is a modern draft (2019‑09/2020‑12) where contentEncoding is annotation only
  lIsAnnotationOnly := False;
  for lKey in lVisitor.KeywordPrecedence do
    if (lKey = '$recursiveRef') or (lKey = '$dynamicRef') then
    begin
      lIsAnnotationOnly := True;
      Break;
    end;

  if lIsAnnotationOnly then
  begin
    lVisitor.Result.AddAnnotation('contentEncoding', pValue.Value);
    Exit;
  end;

  // Legacy validation: only base64 is supported
  if not SameText(pValue.Value, 'base64') then
    Exit;

  lInstanceValue := TJSONString(lScope.InstanceNode).Value;
  if not TRegEx.IsMatch(lInstanceValue, '^[A-Za-z0-9+/]*={0,2}$', [roCompiled]) then
    lVisitor.AddError(TErrorType.vetInvalidFormat, ['contentEncoding']);
end;

procedure TBaseValidationVisitor<T>.VisitContentMediaType(const pValue: TJSONString);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lMediaType: string;
  lInstanceValue: string;
  lEncoding: TJSONValue;
  lBytes: TBytes;
  lDecoded: string;
  lJsonValue: TJSONValue;
  lIsAnnotationOnly: Boolean;
  lKey: string;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'string' then
    Exit;

  lMediaType := LowerCase(pValue.Value);
  if lMediaType <> 'application/json' then
    Exit;

  // Detect if this is a modern draft (2019‑09/2020‑12) where contentMediaType is annotation only
  lIsAnnotationOnly := False;
  for lKey in lVisitor.KeywordPrecedence do
    if (lKey = '$recursiveRef') or (lKey = '$dynamicRef') then
    begin
      lIsAnnotationOnly := True;
      Break;
    end;

  if lIsAnnotationOnly then
  begin
    lVisitor.Result.AddAnnotation('contentMediaType', pValue.Value);
    Exit;
  end;

  lInstanceValue := TJSONString(lScope.InstanceNode).Value;
  lDecoded := lInstanceValue;

  // Apply contentEncoding if present
  lEncoding := nil;
  if (lScope.SchemaNode is TJSONObject) then
    lEncoding := TJSONObject(lScope.SchemaNode).FindValue('contentEncoding');

  if (lEncoding is TJSONString) and SameText(TJSONString(lEncoding).Value, 'base64') then
  begin
    if not TRegEx.IsMatch(lInstanceValue, '^[A-Za-z0-9+/]*={0,2}$', [roCompiled]) then
      Exit;
    try
      lBytes := TNetEncoding.Base64.DecodeStringToBytes(lInstanceValue);
      lDecoded := TEncoding.UTF8.GetString(lBytes);
    except
      Exit;
    end;
  end;

  lJsonValue := TJSONObject.ParseJSONValue(lDecoded);
  if lJsonValue = nil then
    lVisitor.AddError(TErrorType.vetInvalidFormat, ['contentMediaType'])
  else
    lJsonValue.Free;
end;

end.
