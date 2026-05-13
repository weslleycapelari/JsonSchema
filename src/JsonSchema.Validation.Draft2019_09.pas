unit JsonSchema.Validation.Draft2019_09;

interface

uses
  System.JSON,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Types,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Validation.Base,
  JsonSchema.Validation.Interfaces;

type
  TDraft2019_09Visitor = class(TValidationVisitor<TDraft2019_09Visitor>)
  public
    constructor Create(const ASchema, AData: TJSONValue; const ABaseURI: string; const ACustomHint: TJSONValue = nil);
    function New(const ASchema, AData: TJSONValue; const ABaseURI: string): TDraft2019_09Visitor; override;
    function KeywordPrecedence: TArray<string>; override;
  end;

  IDraft2019_09CoreVisitor = interface(IBaseCoreVisitor<TDraft2019_09Visitor>)
    ['{4B72E0CE-AFBF-4C25-92CC-EA0509595809}']
    procedure VisitComment(const AValue: TJSONString);
    procedure VisitAnchor(const AValue: TJSONString);
    procedure VisitRecursiveRef(const AValue: TJSONString);
    procedure VisitRecursiveAnchor(const AValue: TJSONBool);
    procedure VisitVocabulary(const AValue: TJSONObject);
  end;

  IDraft2019_09ApplicatorVisitor = interface(IBaseApplicatorVisitor<TDraft2019_09Visitor>)
    ['{44142A26-AC72-414C-BB83-75DA511A0A36}']
    procedure VisitDependentSchemas(const AValue: TJSONObject);
    procedure VisitUnevaluatedItems(const AValue: TJSONValue);
    procedure VisitUnevaluatedProperties(const AValue: TJSONValue);
  end;

  IDraft2019_09ValidationVisitor = interface(IBaseValidationVisitor<TDraft2019_09Visitor>)
    ['{E995D611-5477-4970-B791-81A4555AF554}']
    procedure VisitContains(const AValue: TJSONValue);
    procedure VisitPropertyNames(const AValue: TJSONValue);
    procedure VisitDependentRequired(const AValue: TJSONObject);
    procedure VisitMaxContains(const AValue: TJSONNumber);
    procedure VisitMinContains(const AValue: TJSONNumber);
  end;

  IDraft2019_09HyperSchemaVisitor = interface(IBaseHyperSchemaVisitor<TDraft2019_09Visitor>)
    procedure VisitRel(const AValue: TJSONString);
    procedure VisitTitle(const AValue: TJSONString);
    procedure VisitAnchor(const AValue: TJSONString);
    procedure VisitAnchorPointer(const AValue: TJSONString);
    procedure VisitTemplatePointers(const AValue: TJSONObject);
    procedure VisitTemplateRequired(const AValue: TJSONArray);
    procedure VisitDescription(const AValue: TJSONString);
    procedure VisitTargetMediaType(const AValue: TJSONString);
    procedure VisitTargetHints(const AValue: TJSONObject);
    procedure VisitHeaderSchema(const AValue: TJSONValue);
    procedure VisitSubmissionMediaType(const AValue: TJSONString);
  end;

  IDraft2019_09RelativeJsonPointer = interface(IBaseRelativeJsonPointer<TDraft2019_09Visitor>)
    ['{E40B5CE3-7207-430E-81BA-07A8E798EC60}']
  end;

  TDraft2019_09CoreVisitor = class(TBaseCoreVisitor<TDraft2019_09Visitor>, IDraft2019_09CoreVisitor)
    [VisitorKeyword('$comment')]
    procedure VisitComment(const AValue: TJSONString);
    [VisitorKeyword('$anchor')]
    procedure VisitAnchor(const AValue: TJSONString);
    [VisitorKeyword('$recursiveRef')]
    procedure VisitRecursiveRef(const AValue: TJSONString);
    [VisitorKeyword('$recursiveAnchor')]
    procedure VisitRecursiveAnchor(const AValue: TJSONBool);
    [VisitorKeyword('$vocabulary')]
    procedure VisitVocabulary(const AValue: TJSONObject);
  end;

  TDraft2019_09ApplicatorVisitor = class(TBaseApplicatorVisitor<TDraft2019_09Visitor>, IDraft2019_09ApplicatorVisitor)
    [VisitorKeyword('dependentSchemas')]
    procedure VisitDependentSchemas(const AValue: TJSONObject);
    [VisitorKeyword('unevaluatedItems')]
    procedure VisitUnevaluatedItems(const AValue: TJSONValue);
    [VisitorKeyword('unevaluatedProperties')]
    procedure VisitUnevaluatedProperties(const AValue: TJSONValue);
  end;

  TDraft2019_09ValidationVisitor = class(TBaseValidationVisitor<TDraft2019_09Visitor>, IDraft2019_09ValidationVisitor)
    [VisitorKeyword('contains')]
    procedure VisitContains(const AValue: TJSONValue);
    [VisitorKeyword('propertyNames')]
    procedure VisitPropertyNames(const AValue: TJSONValue);
    [VisitorKeyword('dependentRequired')]
    procedure VisitDependentRequired(const AValue: TJSONObject);
    [VisitorKeyword('maxContains')]
    procedure VisitMaxContains(const AValue: TJSONNumber);
    [VisitorKeyword('minContains')]
    procedure VisitMinContains(const AValue: TJSONNumber);
  end;

  TDraft2019_09HyperSchemaVisitor = class(TBaseHyperSchemaVisitor<TDraft2019_09Visitor>, IDraft2019_09HyperSchemaVisitor)
    [VisitorKeyword('rel')]
    procedure VisitRel(const AValue: TJSONString);
    [VisitorKeyword('title')]
    procedure VisitTitle(const AValue: TJSONString);
    [VisitorKeyword('anchor')]
    procedure VisitAnchor(const AValue: TJSONString);
    [VisitorKeyword('anchorPointer')]
    procedure VisitAnchorPointer(const AValue: TJSONString);
    [VisitorKeyword('templatePointers')]
    procedure VisitTemplatePointers(const AValue: TJSONObject);
    [VisitorKeyword('templateRequired')]
    procedure VisitTemplateRequired(const AValue: TJSONArray);
    [VisitorKeyword('description')]
    procedure VisitDescription(const AValue: TJSONString);
    [VisitorKeyword('targetMediaType')]
    procedure VisitTargetMediaType(const AValue: TJSONString);
    [VisitorKeyword('targetHints')]
    procedure VisitTargetHints(const AValue: TJSONObject);
    [VisitorKeyword('headerSchema')]
    procedure VisitHeaderSchema(const AValue: TJSONValue);
    [VisitorKeyword('submissionMediaType')]
    procedure VisitSubmissionMediaType(const AValue: TJSONString);
  end;

  TDraft2019_09RelativeJsonPointer = class(TBaseRelativeJsonPointer<TDraft2019_09Visitor>, IDraft2019_09RelativeJsonPointer)
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  System.Generics.Collections,
  JsonSchema.Common.Utils,
  JsonSchema.Translate.Types,
  JsonSchema.Walker;

{ TDraft2019_09Visitor }

constructor TDraft2019_09Visitor.Create(const ASchema, AData: TJSONValue; const ABaseURI: string; const ACustomHint: TJSONValue);
begin
  inherited Create(ASchema, AData, ABaseURI, ACustomHint);

  FCore                := TDraft2019_09CoreVisitor.Create(Self);
  FApplicator          := TDraft2019_09ApplicatorVisitor.Create(Self);
  FValidation          := TDraft2019_09ValidationVisitor.Create(Self);
  FHyperSchema         := TDraft2019_09HyperSchemaVisitor.Create(Self);
  FRelativeJsonPointer := TDraft2019_09RelativeJsonPointer.Create(Self);
end;

function TDraft2019_09Visitor.KeywordPrecedence: TArray<string>;
begin
  Result := [
    '$schema',
    '$id',
    '$ref',
    '$recursiveRef',
    '$anchor',
    '$recursiveAnchor',
    'properties',
    'patternProperties',
    'additionalProperties',
    'prefixItems',
    'items',
    'contains',
    'additionalItems',
    'if',
    'allOf',
    'anyOf',
    'oneOf',
    'unevaluatedProperties',
    'unevaluatedItems'
  ];
end;

function TDraft2019_09Visitor.New(const ASchema, AData: TJSONValue; const ABaseURI: string): TDraft2019_09Visitor;
begin
  Result := TDraft2019_09Visitor.Create(ASchema, AData, ABaseURI, FCustomHint);
end;

{ TDraft2019_09CoreVisitor }

procedure TDraft2019_09CoreVisitor.VisitAnchor(const AValue: TJSONString);
begin

end;

procedure TDraft2019_09CoreVisitor.VisitComment(const AValue: TJSONString);
begin

end;

procedure TDraft2019_09CoreVisitor.VisitRecursiveAnchor(const AValue: TJSONBool);
begin

end;

procedure TDraft2019_09CoreVisitor.VisitRecursiveRef(const AValue: TJSONString);
begin

end;

procedure TDraft2019_09CoreVisitor.VisitVocabulary(const AValue: TJSONObject);
begin

end;

{ TDraft2019_09ValidationVisitor }

procedure TDraft2019_09ValidationVisitor.VisitContains(const AValue: TJSONValue);
var
  LScope: TScope;
  LCount: Integer;
  LWalker: IWalker;
  LSchema: TJSONNumber;
  LVisitor: TDraft2019_09Visitor;
  LNewScope: TScope;
  LInstance: TJSONArray;
begin
  LScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(LScope.InstanceNode) <> 'array' then
    Exit;

  if AValue is TJSONBool then
  begin
    if TJSONBool(AValue).AsBoolean and (TJSONArray(LScope.InstanceNode).Count > 0) then
      Exit;

    if not TJSONBool(AValue).AsBoolean then
    begin
       Visitor.AddError(vetContains);
       Exit;
    end;
  end;

  LInstance := TJSONArray(LScope.InstanceNode);
  for LCount := 0 to LInstance.Count - 1 do
  begin
    LNewScope := LScope;
    with LNewScope do
    begin
      SchemaPath        := Format('%s/contains', [LScope.SchemaPath]);
      SchemaNode        := AValue;
      InstanceNode      := LInstance[LCount];
      InstancePath      := Format('%s/%d', [LScope.InstancePath, LCount]);
      CoveredItems      := [];
      ContainsCount     := 0;
      VisitedKeywords   := [];
      CoveredProperties := [];
    end;

    Visitor.PushScope(LNewScope);
    LVisitor := Visitor.New(AValue, LInstance[LCount], LScope.BaseURI);
    try
      LWalker := TWalker<TDraft2019_09Visitor>.Create(AValue, LVisitor);
      LWalker.Walk;
    finally
      Visitor.PopScope;
    end;

    if LVisitor.Result.IsValid then
      Inc(LScope.ContainsCount);
  end;

  Visitor.UpdateScope(LScope);

  if not LScope.SchemaNode.TryGetValue('minContains', LSchema) then
    LSchema := TJSONNumber.Create(1);

  VisitMinContains(LSchema);

  if LScope.SchemaNode.TryGetValue('maxContains', LSchema) then
    VisitMaxContains(LSchema);

  Visitor
    .AddVisitedKeyword('minContains')
    .AddVisitedKeyword('maxContains');
end;

procedure TDraft2019_09ValidationVisitor.VisitDependentRequired(const AValue: TJSONObject);
begin

end;

procedure TDraft2019_09ValidationVisitor.VisitMaxContains(const AValue: TJSONNumber);
var
  LScope: TScope;
  LMaximum: Integer;
begin
  LScope := Visitor.CurrentScope;
  if LScope.SchemaNode.FindValue('contains') = nil then
    Exit;

  LMaximum := TUtils.JsonGetInteger(AValue);
  if LScope.ContainsCount > LMaximum then
    Visitor.AddError(vetMaxContains, [LMaximum, LScope.ContainsCount]);
end;

procedure TDraft2019_09ValidationVisitor.VisitMinContains(const AValue: TJSONNumber);
var
  LScope: TScope;
  LMinimum: Integer;
begin
  LScope := Visitor.CurrentScope;
  if LScope.SchemaNode.FindValue('contains') = nil then
    Exit;

  LMinimum := TUtils.JsonGetInteger(AValue);
  if LScope.ContainsCount < LMinimum then
    if LMinimum = 1 then
      Visitor.AddError(vetContains)
    else
      Visitor.AddError(vetMinContains, [LMinimum, LScope.ContainsCount]);
end;

procedure TDraft2019_09ValidationVisitor.VisitPropertyNames(const AValue: TJSONValue);
var
  LPair: TJSONPair;
  LScope: TScope;
  LWalker: IWalker;
  LVisitor: TDraft2019_09Visitor;
  LNewScope: TScope;
begin
  LScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(LScope.InstanceNode) <> 'object' then
    Exit;

  for LPair in TJSONObject(LScope.InstanceNode) do
  begin
    LNewScope := LScope;
    with LNewScope do
    begin
      SchemaPath        := Format('%s/propertyNames', [SchemaPath]);
      SchemaNode        := AValue;
      InstanceNode      := LPair.JsonString;
      InstancePath      := Format('%s/%s', [InstancePath, LPair.JsonString.Value]);
      CoveredItems      := [];
      ContainsCount     := 0;
      VisitedKeywords   := [];
      CoveredProperties := [];
    end;

    Visitor.PushScope(LNewScope);
    LVisitor := Visitor.New(LNewScope.SchemaNode, LNewScope.InstanceNode, LScope.BaseURI);
    try
      LWalker := TWalker<TDraft2019_09Visitor>.Create(LNewScope.SchemaNode, LVisitor);
      LWalker.Walk;
    finally
      Visitor.PopScope;
    end;

    if not LVisitor.Result.IsValid then
      Visitor.AddError(vetInvalidPropertyName, [LPair.JsonString.Value]);
  end;
end;

{ TDraft2019_09HyperSchemaVisitor }

procedure TDraft2019_09HyperSchemaVisitor.VisitAnchor(const AValue: TJSONString);
begin

end;

procedure TDraft2019_09HyperSchemaVisitor.VisitAnchorPointer(const AValue: TJSONString);
begin

end;

procedure TDraft2019_09HyperSchemaVisitor.VisitDescription(const AValue: TJSONString);
begin

end;

procedure TDraft2019_09HyperSchemaVisitor.VisitHeaderSchema(const AValue: TJSONValue);
begin

end;

procedure TDraft2019_09HyperSchemaVisitor.VisitRel(const AValue: TJSONString);
begin

end;

procedure TDraft2019_09HyperSchemaVisitor.VisitSubmissionMediaType(const AValue: TJSONString);
begin

end;

procedure TDraft2019_09HyperSchemaVisitor.VisitTargetHints(const AValue: TJSONObject);
begin

end;

procedure TDraft2019_09HyperSchemaVisitor.VisitTargetMediaType(const AValue: TJSONString);
begin

end;

procedure TDraft2019_09HyperSchemaVisitor.VisitTemplatePointers(const AValue: TJSONObject);
begin

end;

procedure TDraft2019_09HyperSchemaVisitor.VisitTemplateRequired(const AValue: TJSONArray);
begin

end;

procedure TDraft2019_09HyperSchemaVisitor.VisitTitle(const AValue: TJSONString);
begin

end;

{ TDraft2019_09ApplicatorVisitor }

procedure TDraft2019_09ApplicatorVisitor.VisitDependentSchemas(const AValue: TJSONObject);
var
  LScope: TScope;
  LInstance: TJSONObject;
  LDependencyPair: TJSONPair;
  LSubSchema: TJSONValue;
  LNewScope: TScope;
  LWalker: IWalker;
begin
  LScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(LScope.InstanceNode) <> 'object' then
    Exit;

  LInstance := TJSONObject(LScope.InstanceNode);
  for LDependencyPair in AValue do
  begin
    if LInstance.FindValue(LDependencyPair.JsonString.Value) <> nil then
    begin
      LSubSchema := LDependencyPair.JsonValue;

      LNewScope := LScope;
      with LNewScope do
      begin
        SchemaPath   := Format('%s/dependentSchemas/%s', [LScope.SchemaPath, LDependencyPair.JsonString.Value]);
        SchemaNode   := LSubSchema;
        InstanceNode := InstanceNode;
        InstancePath := Format('%s', [InstancePath]);
      end;

      Visitor.PushScope(LNewScope);
      try
        LWalker := TWalker<TDraft2019_09Visitor>.Create(LSubSchema, Visitor);
        LWalker.Walk;
      finally
        Visitor.PopScope;
      end;
    end;
  end;
end;

procedure TDraft2019_09ApplicatorVisitor.VisitUnevaluatedItems(const AValue: TJSONValue);
var
  LCount: Integer;
  LScope: TScope;
  LWalker: IWalker;
  LCovered: TList<Integer>;
  LNewScope: TScope;
begin
  LScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(LScope.InstanceNode) <> 'array' then
    Exit;

  LCovered := TList<Integer>.Create(LScope.CoveredItems);
  try
    for LCount := 0 to TJSONArray(LScope.InstanceNode).Count - 1 do
    begin
      if LCovered.Contains(LCount) then
        Continue;

      LNewScope := LScope;
      with LNewScope do
      begin
        SchemaPath        := Format('%s/unevaluatedItems', [SchemaPath]);
        SchemaNode        := AValue;
        InstanceNode      := TJSONArray(InstanceNode)[LCount];
        InstancePath      := Format('%s/%d', [InstancePath, LCount]);
        CoveredItems      := [];
        ContainsCount     := 0;
        VisitedKeywords   := [];
        CoveredProperties := [];
      end;

      Visitor.PushScope(LNewScope);
      try
        LWalker := TWalker<TDraft2019_09Visitor>.Create(AValue, Visitor);
        LWalker.Walk;
      finally
        Visitor.PopScope;
      end;

      TUtils.AddArray<Integer>(LScope.CoveredItems, LCount);
    end;
  finally
    LCovered.Free;
  end;

  Visitor.UpdateScope(LScope);
end;

procedure TDraft2019_09ApplicatorVisitor.VisitUnevaluatedProperties(const AValue: TJSONValue);
var
  LPair: TJSONPair;
  LScope: TScope;
  LWalker: IWalker;
  LCovered: TList<string>;
  LNewScope: TScope;
begin
  LScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(LScope.InstanceNode) <> 'object' then
    Exit;

  LCovered := TList<string>.Create(LScope.CoveredProperties);
  try
    for LPair in TJSONObject(LScope.InstanceNode) do
    begin
      if LCovered.Contains(LPair.JsonString.Value) then
        Continue;

      LNewScope := LScope;
      with LNewScope do
      begin
        SchemaPath        := Format('%s/unevaluatedProperties', [SchemaPath]);
        SchemaNode        := AValue;
        InstanceNode      := LPair.JsonValue;
        InstancePath      := Format('%s/%s', [InstancePath, LPair.JsonString.Value]);
        CoveredItems      := [];
        ContainsCount     := 0;
        VisitedKeywords   := [];
        CoveredProperties := [];
      end;

      Visitor.PushScope(LNewScope);
      try
        LWalker := TWalker<TDraft2019_09Visitor>.Create(AValue, Visitor);
        LWalker.Walk;
      finally
        Visitor.PopScope;
      end;

      TUtils.AddArray<string>(LScope.CoveredProperties, LPair.JsonString.Value);
    end;
  finally
    LCovered.Free;
  end;

  Visitor.UpdateScope(LScope);
end;

end.
