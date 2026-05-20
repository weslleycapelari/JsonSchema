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

    // Numeric
    [VisitorKeyword('multipleOf')]
    procedure VisitMultipleOf(const pValue: TJSONNumber); virtual;

    [VisitorKeyword('maximum')]
    procedure VisitMaximum(const pValue: TJSONNumber); virtual;

    [VisitorKeyword('exclusiveMaximum')]
    procedure VisitExclusiveMaximum(const pValue: TJSONValue); virtual;

    [VisitorKeyword('minimum')]
    procedure VisitMinimum(const pValue: TJSONNumber); virtual;

    [VisitorKeyword('exclusiveMinimum')]
    procedure VisitExclusiveMinimum(const pValue: TJSONValue); virtual;

    // String
    [VisitorKeyword('maxLength')]
    procedure VisitMaxLength(const pValue: TJSONNumber); virtual;

    [VisitorKeyword('minLength')]
    procedure VisitMinLength(const pValue: TJSONNumber); virtual;

    [VisitorKeyword('pattern')]
    procedure VisitPattern(const pValue: TJSONString); virtual;

    [VisitorKeyword('format')]
    procedure VisitFormat(const pValue: TJSONString); virtual;

    // Array
    [VisitorKeyword('maxItems')]
    procedure VisitMaxItems(const pValue: TJSONNumber); virtual;

    [VisitorKeyword('minItems')]
    procedure VisitMinItems(const pValue: TJSONNumber); virtual;

    [VisitorKeyword('uniqueItems')]
    procedure VisitUniqueItems(const pValue: TJSONBool); virtual;

    [VisitorKeyword('contains')]
    procedure VisitContains(const pValue: TJSONValue); virtual;

    // Object
    [VisitorKeyword('maxProperties')]
    procedure VisitMaxProperties(const pValue: TJSONNumber); virtual;

    [VisitorKeyword('minProperties')]
    procedure VisitMinProperties(const pValue: TJSONNumber); virtual;

    [VisitorKeyword('required')]
    procedure VisitRequired(const pValue: TJSONArray); virtual;

    [VisitorKeyword('propertyNames')]
    procedure VisitPropertyNames(const pValue: TJSONValue); virtual;

    [VisitorKeyword('dependencies')]
    procedure VisitDependencies(const pValue: TJSONObject); virtual;

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

// Numeric
procedure TBaseValidationVisitor<T>.VisitMultipleOf(const pValue: TJSONNumber);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lValue: Extended;
  lDivisor: Extended;
  lDivision: Extended;
  lRounded: Extended;
  lEpsilon: Extended;
  lInverse: Extended;
  lInverseRounded: Extended;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  if IsSilentMode then
    Exit;

  lScope := lVisitor.CurrentScope;
  if not MatchStr(TUtils.JsonGetType(lScope.InstanceNode), ['number', 'integer']) then
    Exit;

  lValue := TUtils.JsonGetFloat(lScope.InstanceNode);
  lDivisor := TUtils.JsonGetFloat(pValue);
  if lDivisor = 0 then
    Exit;

  if TUtils.JsonGetType(lScope.InstanceNode) = 'integer' then
  begin
    lInverse := 1 / lDivisor;
    lInverseRounded := Round(lInverse);
    if Abs(lInverse - lInverseRounded) <= 1E-12 then
      Exit;
  end;

  if Abs(lValue) < 1E-15 then
    Exit;

  lDivision := lValue / lDivisor;
  if IsInfinite(lDivision) or IsNan(lDivision) then
  begin
    lVisitor.AddError(TErrorType.vetMultipleOf, [pValue.Value]);
    Exit;
  end;

  lRounded := Round(lDivision);
  if Abs(lValue) < 1E-15 then
    lEpsilon := Max(1E-30, Abs(lDivisor) * 1E-12)
  else
    lEpsilon := Max(1E-12, Abs(lDivision) * 1E-12);

  if Abs(lDivision - lRounded) > lEpsilon then
    lVisitor.AddError(TErrorType.vetMultipleOf, [pValue.Value]);
end;

procedure TBaseValidationVisitor<T>.VisitMaximum(const pValue: TJSONNumber);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lMax: Extended;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  if IsSilentMode then
    Exit;

  lScope := lVisitor.CurrentScope;
  if not MatchStr(TUtils.JsonGetType(lScope.InstanceNode), ['number', 'integer']) then
    Exit;

  lMax := TUtils.JsonGetFloat(pValue);
  if TUtils.JsonGetFloat(lScope.InstanceNode) > lMax then
    lVisitor.AddError(TErrorType.vetMaximum, [lMax.ToString]);
end;

procedure TBaseValidationVisitor<T>.VisitExclusiveMaximum(const pValue: TJSONValue);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lLimitValue: Extended;
  lIsExclusive: Boolean;
  lLimitSchema: TJSONValue;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  if IsSilentMode then
    Exit;

  lScope := lVisitor.CurrentScope;
  if not MatchStr(TUtils.JsonGetType(lScope.InstanceNode), ['number', 'integer']) then
    Exit;

  if pValue is TJSONNumber then
  begin
    lLimitValue := TUtils.JsonGetFloat(pValue);
    lIsExclusive := True;
  end
  else if pValue is TJSONBool then
  begin
    lIsExclusive := TJSONBool(pValue).AsBoolean;
    if not lIsExclusive then
      Exit;

    if not ((lScope.SchemaNode is TJSONObject) and
            TJSONObject(lScope.SchemaNode).TryGetValue('maximum', lLimitSchema) and
            (lLimitSchema is TJSONNumber)) then
      Exit;

    lLimitValue := TUtils.JsonGetFloat(lLimitSchema);
  end
  else
    Exit;

  if lIsExclusive and (TUtils.JsonGetFloat(lScope.InstanceNode) >= lLimitValue) then
    lVisitor.AddError(TErrorType.vetExclusiveMaximum, [lLimitValue.ToString]);
end;

procedure TBaseValidationVisitor<T>.VisitMinimum(const pValue: TJSONNumber);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lMin: Extended;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  if IsSilentMode then
    Exit;

  lScope := lVisitor.CurrentScope;
  if not MatchStr(TUtils.JsonGetType(lScope.InstanceNode), ['number', 'integer']) then
    Exit;

  lMin := TUtils.JsonGetFloat(pValue);
  if TUtils.JsonGetFloat(lScope.InstanceNode) < lMin then
    lVisitor.AddError(TErrorType.vetMinimum, [lMin.ToString]);
end;

procedure TBaseValidationVisitor<T>.VisitExclusiveMinimum(const pValue: TJSONValue);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lLimitValue: Extended;
  lIsExclusive: Boolean;
  lLimitSchema: TJSONValue;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  if IsSilentMode then
    Exit;

  lScope := lVisitor.CurrentScope;
  if not MatchStr(TUtils.JsonGetType(lScope.InstanceNode), ['number', 'integer']) then
    Exit;

  if pValue is TJSONNumber then
  begin
    lLimitValue := TUtils.JsonGetFloat(pValue);
    lIsExclusive := True;
  end
  else if pValue is TJSONBool then
  begin
    lIsExclusive := TJSONBool(pValue).AsBoolean;
    if not lIsExclusive then
      Exit;

    if not ((lScope.SchemaNode is TJSONObject) and
            TJSONObject(lScope.SchemaNode).TryGetValue('minimum', lLimitSchema) and
            (lLimitSchema is TJSONNumber)) then
      Exit;

    lLimitValue := TUtils.JsonGetFloat(lLimitSchema);
  end
  else
    Exit;

  if lIsExclusive and (TUtils.JsonGetFloat(lScope.InstanceNode) <= lLimitValue) then
    lVisitor.AddError(TErrorType.vetExclusiveMinimum, [lLimitValue.ToString]);
end;

// String
procedure TBaseValidationVisitor<T>.VisitMaxLength(const pValue: TJSONNumber);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lMax: Integer;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  if IsSilentMode then
    Exit;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'string' then
    Exit;

  lMax := TUtils.JsonGetInteger(pValue);
  if Length(TUtils.Utf32Encode(TJSONString(lScope.InstanceNode).Value)) > lMax then
    lVisitor.AddError(TErrorType.vetMaxLength, [lMax]);
end;

procedure TBaseValidationVisitor<T>.VisitMinLength(const pValue: TJSONNumber);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lMin: Integer;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  if IsSilentMode then
    Exit;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'string' then
    Exit;

  lMin := TUtils.JsonGetInteger(pValue);
  if Length(TUtils.Utf32Encode(TJSONString(lScope.InstanceNode).Value)) < lMin then
    lVisitor.AddError(TErrorType.vetMinLength, [lMin]);
end;

procedure TBaseValidationVisitor<T>.VisitPattern(const pValue: TJSONString);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lPattern: string;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  if IsSilentMode then
    Exit;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'string' then
    Exit;

  lPattern := TUtils.RegexNormalizePattern(pValue.Value);
  if not TRegEx.IsMatch(TJSONString(lScope.InstanceNode).Value, lPattern, [roCompiled]) then
    lVisitor.AddError(TErrorType.vetPattern, [lPattern]);
end;

procedure TBaseValidationVisitor<T>.VisitFormat(const pValue: TJSONString);
begin
  // Default implementation: delegate to TFormatValidator if assertion enabled.
  // Overridden in Draft 2020‑12 to respect format-assertion vocabulary.
  if not IsFormatAssertionEnabled then
    Exit;

  if IsSilentMode then
    Exit;

  var lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  var lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'string' then
    Exit;

  var lFormatName := LowerCase(pValue.Value);
  var lInstanceValue := TJSONString(lScope.InstanceNode).Value;
  var lIsValid := True;

  if lFormatName = 'ipv4' then
    lIsValid := TFormatValidator.IsIPv4(lInstanceValue)
  else if lFormatName = 'ipv6' then
    lIsValid := TFormatValidator.IsIPv6(lInstanceValue)
  else if lFormatName = 'date-time' then
    lIsValid := TFormatValidator.IsDateTime(lInstanceValue)
  else if lFormatName = 'duration' then
    lIsValid := TFormatValidator.IsDuration(lInstanceValue)
  else if lFormatName = 'date' then
    lIsValid := TFormatValidator.IsDate(lInstanceValue)
  else if lFormatName = 'time' then
    lIsValid := TFormatValidator.IsTime(lInstanceValue)
  else if lFormatName = 'email' then
    lIsValid := TFormatValidator.IsEmail(lInstanceValue)
  else if lFormatName = 'idn-email' then
    lIsValid := TFormatValidator.IsIDNEmail(lInstanceValue)
  else if lFormatName = 'idn-hostname' then
    lIsValid := TFormatValidator.IsIDNHostname(lInstanceValue)
  else if lFormatName = 'json-pointer' then
    lIsValid := TFormatValidator.IsJSONPointer(lInstanceValue)
  else if lFormatName = 'uri-reference' then
    lIsValid := TFormatValidator.IsURIReference(lInstanceValue)
  else if lFormatName = 'uri' then
    lIsValid := TFormatValidator.IsURI(lInstanceValue)
  else if lFormatName = 'iri-reference' then
    lIsValid := TFormatValidator.IsIRIReference(lInstanceValue)
  else if lFormatName = 'iri' then
    lIsValid := TFormatValidator.IsIRI(lInstanceValue)
  else if lFormatName = 'uri-template' then
    lIsValid := TFormatValidator.IsURITemplate(lInstanceValue)
  else if lFormatName = 'relative-json-pointer' then
    lIsValid := TFormatValidator.IsRelativeJSONPointer(lInstanceValue)
  else if lFormatName = 'regex' then
    lIsValid := TFormatValidator.IsRegex(lInstanceValue)
  else if lFormatName = 'hostname' then
    lIsValid := TFormatValidator.IsHostname(lInstanceValue)
  else if lFormatName = 'uuid' then
    lIsValid := TFormatValidator.IsUUID(lInstanceValue);

  if not lIsValid then
    lVisitor.AddError(TErrorType.vetInvalidFormat, [pValue.Value]);
end;

// Array
procedure TBaseValidationVisitor<T>.VisitMaxItems(const pValue: TJSONNumber);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lMax: Integer;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  if IsSilentMode then
    Exit;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'array' then
    Exit;

  lMax := TUtils.JsonGetInteger(pValue);
  if TJSONArray(lScope.InstanceNode).Count > lMax then
    lVisitor.AddError(TErrorType.vetMaxItems, [lMax]);
end;

procedure TBaseValidationVisitor<T>.VisitMinItems(const pValue: TJSONNumber);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lMin: Integer;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  if IsSilentMode then
    Exit;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'array' then
    Exit;

  lMin := TUtils.JsonGetInteger(pValue);
  if TJSONArray(lScope.InstanceNode).Count < lMin then
    lVisitor.AddError(TErrorType.vetMinItems, [lMin]);
end;

procedure TBaseValidationVisitor<T>.VisitUniqueItems(const pValue: TJSONBool);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lArray: TJSONArray;
  lI: Integer;
  lJ: Integer;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  if IsSilentMode then
    Exit;

  if not pValue.AsBoolean then
    Exit;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'array' then
    Exit;

  lArray := TJSONArray(lScope.InstanceNode);
  for lI := 0 to lArray.Count - 2 do
    for lJ := lI + 1 to lArray.Count - 1 do
      if TUtils.JsonEquals(lArray.Items[lI], lArray.Items[lJ]) then
      begin
        lVisitor.AddError(TErrorType.vetUniqueItems, [lArray.Items[lI].ToString]);
        Exit;
      end;
end;

procedure TBaseValidationVisitor<T>.VisitContains(const pValue: TJSONValue);
begin
  // Default implementation – should be overridden in concrete visitors
  // because contains behaviour changed between drafts.
  // Base implementation does nothing to avoid duplication.
end;

// Object
procedure TBaseValidationVisitor<T>.VisitMaxProperties(const pValue: TJSONNumber);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lMax: Integer;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  if IsSilentMode then
    Exit;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

  lMax := TUtils.JsonGetInteger(pValue);
  if TJSONObject(lScope.InstanceNode).Count > lMax then
    lVisitor.AddError(TErrorType.vetMaxProperties, [lMax]);
end;

procedure TBaseValidationVisitor<T>.VisitMinProperties(const pValue: TJSONNumber);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lMin: Integer;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  if IsSilentMode then
    Exit;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

  lMin := TUtils.JsonGetInteger(pValue);
  if TJSONObject(lScope.InstanceNode).Count < lMin then
    lVisitor.AddError(TErrorType.vetMinProperties, [lMin]);
end;

procedure TBaseValidationVisitor<T>.VisitRequired(const pValue: TJSONArray);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lInstance: TJSONObject;
  lRequired: TJSONValue;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  if IsSilentMode then
    Exit;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

  lInstance := TJSONObject(lScope.InstanceNode);
  for lRequired in pValue do
    if lInstance.FindValue(lRequired.Value) = nil then
      lVisitor.AddError(TErrorType.vetRequiredPropertyMissing, [lRequired.Value]);
end;

procedure TBaseValidationVisitor<T>.VisitPropertyNames(const pValue: TJSONValue);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lInstance: TJSONObject;
  lPair: TJSONPair;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  if IsSilentMode then
    Exit;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

  lInstance := TJSONObject(lScope.InstanceNode);
  for lPair in lInstance do
    if not EvaluateSubSchema(pValue, lPair.JsonString, 'propertyNames', TJsonPathUtils.JoinPath(lScope.InstancePath, lPair.JsonString.Value)) then
      lVisitor.AddError(TErrorType.vetInvalidPropertyName, [lPair.JsonString.Value]);
end;

procedure TBaseValidationVisitor<T>.VisitDependencies(const pValue: TJSONObject);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lInstance: TJSONObject;
  lDependencyPair: TJSONPair;
  lDependencyValue: TJSONValue;
  lRequiredList: TJSONArray;
  lRequiredValue: TJSONValue;
  lRequiredName: string;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  if IsSilentMode then
    Exit;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

  lInstance := TJSONObject(lScope.InstanceNode);
  for lDependencyPair in pValue do
  begin
    if lInstance.FindValue(lDependencyPair.JsonString.Value) = nil then
      Continue;

    lDependencyValue := lDependencyPair.JsonValue;

    if lDependencyValue is TJSONArray then
    begin
      lRequiredList := TJSONArray(lDependencyValue);
      for lRequiredValue in lRequiredList do
      begin
        if not (lRequiredValue is TJSONString) then
          Continue;
        lRequiredName := TJSONString(lRequiredValue).Value;
        if lInstance.FindValue(lRequiredName) = nil then
          lVisitor.AddError(TErrorType.vetDependentRequired, [lDependencyPair.JsonString.Value, lRequiredName]);
      end;
    end
    else if (lDependencyValue is TJSONObject) or (lDependencyValue is TJSONBool) then
    begin
      if not EvaluateSubSchema(lDependencyValue, lScope.InstanceNode,
        Format('dependencies/%s', [lDependencyPair.JsonString.Value]), lScope.InstancePath) then
      begin
        // Errors are already added by the sub‑visitor
      end;
    end;
  end;
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
