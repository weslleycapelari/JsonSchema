unit JsonSchema.Validation.Draft7;

interface

uses
  System.JSON,
  JsonSchema.Types,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Visitors.Types,
  JsonSchema.Visitor.Core.Base,
  JsonSchema.Visitor.Applicator.Base,
  JsonSchema.Visitor.Validation.Base,
  JsonSchema.Visitor.RelativePointer.Stub,
  JsonSchema.Visitor.HyperSchema.Stub,
  JsonSchema.Validation.Base,
  JsonSchema.Validation.Interfaces;

type
  /// <summary>Main validation visitor for JSON Schema Draft 7.</summary>
  TDraft7Visitor = class(TValidationVisitor<TDraft7Visitor>)
  public
    constructor Create(const pSchema, pData: TJSONValue; const pBaseURI: string;
      const pCustomHint: TJSONValue = nil);
    function New(const pSchema, pData: TJSONValue; const pBaseURI: string): TDraft7Visitor; override;
    function KeywordPrecedence: TArray<string>; override;
  end;

  /// <summary>Core visitor for Draft 7, adding $comment support.</summary>
  TDraft7CoreVisitor = class(TBaseCoreVisitor<TDraft7Visitor>)
  public
    [VisitorKeyword('$comment')]
    procedure VisitComment(const pValue: TJSONString);
  end;

  /// <summary>Applicator visitor for Draft 7, adding if/then/else support.</summary>
  TDraft7ApplicatorVisitor = class(TBaseApplicatorVisitor<TDraft7Visitor>)
  private
    function EvaluateCondition(const pIfSchema: TJSONValue; out pSubScope: TScope): Boolean;
  public
    [VisitorKeyword('if')]
    procedure VisitIf(const pValue: TJSONValue); override;

    [VisitorKeyword('then')]
    procedure VisitThen(const pValue: TJSONValue); override;

    [VisitorKeyword('else')]
    procedure VisitElse(const pValue: TJSONValue); override;
  end;

  /// <summary>Validation visitor for Draft 7, adding contains support.</summary>
  TDraft7ValidationVisitor = class(TBaseValidationVisitor<TDraft7Visitor>)
  public
    [VisitorKeyword('contains')]
    procedure VisitContains(const pValue: TJSONValue); override;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  JsonSchema.Common.Utils,
  JsonSchema.JsonPathUtils,
  JsonSchema.Walker,
  JsonSchema.Walker.Types;

{ TDraft7CoreVisitor }

procedure TDraft7CoreVisitor.VisitComment(const pValue: TJSONString);
begin
  // $comment is purely informational – no validation action required
end;

{ TDraft7ApplicatorVisitor }

function TDraft7ApplicatorVisitor.EvaluateCondition(const pIfSchema: TJSONValue;
  out pSubScope: TScope): Boolean;
var
  lVisitor: IValidationVisitor<TDraft7Visitor>;
  lParentScope: TScope;
  lSubVisitor: TDraft7Visitor;
  lWalker: IWalker;
begin
  Result := False;
  lVisitor := Visitor;
  if not Assigned(lVisitor) then
    Exit;

  lParentScope := GetCurrentScope;
  pSubScope := lParentScope;
  pSubScope.SchemaNode := pIfSchema;
  pSubScope.SchemaPath := TJsonPathUtils.JoinPath(lParentScope.SchemaPath, 'if');
  pSubScope.CoveredItems := [];
  pSubScope.ContainsCount := 0;
  pSubScope.VisitedKeywords := [];
  pSubScope.CoveredProperties := [];
  pSubScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

  lSubVisitor := lVisitor.New(pIfSchema, lParentScope.InstanceNode, lParentScope.BaseURI);
  lSubVisitor.PushScope(pSubScope);
  try
    lWalker := TWalker<TDraft7Visitor>.Create(pIfSchema, lSubVisitor);
    lWalker.Walk;
    Result := lSubVisitor.Result.IsValid;
  finally
    pSubScope := lSubVisitor.PopScope;
  end;
end;

procedure TDraft7ApplicatorVisitor.VisitIf(const pValue: TJSONValue);
var
  lVisitor: IValidationVisitor<TDraft7Visitor>;
  lScope: TScope;
  lThenSchema: TJSONValue;
  lElseSchema: TJSONValue;
  lSubScope: TScope;
  lIfValid: Boolean;
begin
  lVisitor := Visitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := GetCurrentScope;
  lIfValid := EvaluateCondition(pValue, lSubScope);
  if lIfValid then
  begin
    MergeSubScope(lSubScope, lScope);
    UpdateScope(lScope);

    if (lScope.SchemaNode is TJSONObject) and
       TJSONObject(lScope.SchemaNode).TryGetValue('then', lThenSchema) then
      VisitThen(lThenSchema);
  end
  else
  begin
    if (lScope.SchemaNode is TJSONObject) and
       TJSONObject(lScope.SchemaNode).TryGetValue('else', lElseSchema) then
      VisitElse(lElseSchema);
  end;

  lVisitor.AddVisitedKeyword('then');
  lVisitor.AddVisitedKeyword('else');
end;

procedure TDraft7ApplicatorVisitor.VisitThen(const pValue: TJSONValue);
var
  lVisitor: IValidationVisitor<TDraft7Visitor>;
  lScope: TScope;
  lSubScope: TScope;
begin
  lVisitor := Visitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := GetCurrentScope;
  if EvaluateSubSchema(pValue, 'then', lSubScope) then
    MergeSubScope(lSubScope, lScope)
  else
  begin
    // Errors already added by sub‑visitor
  end;
  UpdateScope(lScope);
end;

procedure TDraft7ApplicatorVisitor.VisitElse(const pValue: TJSONValue);
var
  lVisitor: IValidationVisitor<TDraft7Visitor>;
  lScope: TScope;
  lSubScope: TScope;
begin
  lVisitor := Visitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := GetCurrentScope;
  if EvaluateSubSchema(pValue, 'else', lSubScope) then
    MergeSubScope(lSubScope, lScope);
  UpdateScope(lScope);
end;

{ TDraft7ValidationVisitor }

procedure TDraft7ValidationVisitor.VisitContains(const pValue: TJSONValue);
var
  lVisitor: IValidationVisitor<TDraft7Visitor>;
  lScope: TScope;
  lInstance: TJSONArray;
  lCount: Integer;
  lSubVisitor: TDraft7Visitor;
  lWalker: IWalker;
  lNewScope: TScope;
  lFound: Boolean;
  lItemPath: string;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'array' then
    Exit;

  lInstance := TJSONArray(lScope.InstanceNode);
  lFound := False;

  for lCount := 0 to lInstance.Count - 1 do
  begin
    lNewScope := lScope;
    lNewScope.SchemaNode := pValue;
    lNewScope.InstanceNode := lInstance[lCount];
    lNewScope.InstancePath := TJsonPathUtils.JoinPath(lScope.InstancePath, lCount.ToString);
    lNewScope.CoveredItems := [];
    lNewScope.ContainsCount := 0;
    lNewScope.VisitedKeywords := [];
    lNewScope.CoveredProperties := [];

    lSubVisitor := lVisitor.New(pValue, lInstance[lCount], lScope.BaseURI);
    lSubVisitor.PushScope(lNewScope);
    try
      lWalker := TWalker<TDraft7Visitor>.Create(pValue, lSubVisitor);
      lWalker.Walk;
    finally
      lSubVisitor.PopScope;
    end;

    if lSubVisitor.Result.IsValid then
    begin
      lFound := True;
      TUtils.AddArray<Integer>(lScope.CoveredItems, lCount);
      lItemPath := TJsonPathUtils.JoinPath(lScope.InstancePath, lCount.ToString);
      lVisitor.Result.AddEvaluatedProperty(lItemPath);
    end;
  end;

  if not lFound then
    lVisitor.AddError(TErrorType.vetContains);

  lVisitor.UpdateScope(lScope);
end;

{ TDraft7Visitor }

constructor TDraft7Visitor.Create(const pSchema, pData: TJSONValue; const pBaseURI: string;
  const pCustomHint: TJSONValue);
begin
  inherited Create(pSchema, pData, pBaseURI, pCustomHint);

  FCore := TDraft7CoreVisitor.Create(Self);
  FApplicator := TDraft7ApplicatorVisitor.Create(Self);
  FValidation := TDraft7ValidationVisitor.Create(Self);
  FHyperSchema := TStubHyperSchemaVisitor<TDraft7Visitor>.Create(Self);
  FRelativeJsonPointer := TStubRelativeJsonPointer<TDraft7Visitor>.Create(Self);
end;

function TDraft7Visitor.New(const pSchema, pData: TJSONValue; const pBaseURI: string): TDraft7Visitor;
begin
  Result := TDraft7Visitor.Create(pSchema, pData, pBaseURI, FCustomHint);
  Result.FRegistry := FRegistry;
  Result.FOwnsRegistry := False;
end;

function TDraft7Visitor.KeywordPrecedence: TArray<string>;
begin
  Result := [
    '$schema',
    '$id',
    '$ref',
    'properties',
    'patternProperties',
    'additionalProperties',
    'items',
    'additionalItems',
    'contains',
    'if',
    'allOf',
    'anyOf',
    'oneOf',
    'not'
  ];
end;

end.
