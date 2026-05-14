unit JsonSchema.Validation.Draft7;

interface

uses
  System.JSON,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Types,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Validation.Base,
  JsonSchema.Validation.Interfaces;

type
  TDraft7Visitor = class(TValidationVisitor<TDraft7Visitor>)
  public
    constructor Create(const ASchema, AData: TJSONValue; const ABaseURI: string; const ACustomHint: TJSONValue = nil);
    function New(const ASchema, AData: TJSONValue; const ABaseURI: string): TDraft7Visitor; override;
    function KeywordPrecedence: TArray<string>; override;
  end;

  IDraft7CoreVisitor = interface(IBaseCoreVisitor<TDraft7Visitor>)
    ['{2F760166-4F1C-4493-966C-2D42C0419A00}']
    procedure VisitComment(const AValue: TJSONString);
  end;

  IDraft7ApplicatorVisitor = interface(IBaseApplicatorVisitor<TDraft7Visitor>)
    ['{CC689354-8C13-42BD-A0AE-9C408FE5D95D}']
    procedure VisitIf(const AValue: TJSONValue);
    procedure VisitThen(const AValue: TJSONValue);
    procedure VisitElse(const AValue: TJSONValue);
  end;

  IDraft7ValidationVisitor = interface(IBaseValidationVisitor<TDraft7Visitor>)
    ['{D1BBFC58-5212-4322-83D2-CD7B211B3969}']
    procedure VisitConst(const AValue: TJSONValue);
    procedure VisitContains(const AValue: TJSONValue);
    procedure VisitPropertyNames(const AValue: TJSONValue);
    procedure VisitDependencies(const AValue: TJSONObject);
  end;

  IDraft7HyperSchemaVisitor = interface(IBaseHyperSchemaVisitor<TDraft7Visitor>)
    ['{A0C4CC5A-0A72-4F6C-AD6E-5DE40B5ED8E1}']
    procedure VisitReadOnly(const AValue: TJSONBool);

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

  IDraft7RelativeJsonPointer = interface(IBaseRelativeJsonPointer<TDraft7Visitor>)
    ['{2DDD2C75-0B7F-4C9A-8D13-A611019E580D}']
  end;

  TDraft7CoreVisitor = class(TBaseCoreVisitor<TDraft7Visitor>, IDraft7CoreVisitor)
    procedure VisitComment(const AValue: TJSONString);
  end;

  TDraft7ApplicatorVisitor = class(TBaseApplicatorVisitor<TDraft7Visitor>, IDraft7ApplicatorVisitor)
    [VisitorKeyword('if')]
    procedure VisitIf(const AValue: TJSONValue);
    [VisitorKeyword('then')]
    procedure VisitThen(const AValue: TJSONValue);
    [VisitorKeyword('else')]
    procedure VisitElse(const AValue: TJSONValue);
  end;

  TDraft7ValidationVisitor = class(TBaseValidationVisitor<TDraft7Visitor>, IDraft7ValidationVisitor)
    [VisitorKeyword('const')]
    procedure VisitConst(const AValue: TJSONValue);
    [VisitorKeyword('contains')]
    procedure VisitContains(const AValue: TJSONValue);
    [VisitorKeyword('propertyNames')]
    procedure VisitPropertyNames(const AValue: TJSONValue);
    [VisitorKeyword('dependencies')]
    procedure VisitDependencies(const AValue: TJSONObject);
  end;

  TDraft7HyperSchemaVisitor = class(TBaseHyperSchemaVisitor<TDraft7Visitor>, IDraft7HyperSchemaVisitor)
    [VisitorKeyword('readOnly')]
    procedure VisitReadOnly(const AValue: TJSONBool);

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

  TDraft7RelativeJsonPointer = class(TBaseRelativeJsonPointer<TDraft7Visitor>, IDraft7RelativeJsonPointer)
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  JsonSchema.Common.Utils,
  JsonSchema.Translate.Types,
  JsonSchema.Walker;

{ TDraft7Visitor }

constructor TDraft7Visitor.Create(const ASchema, AData: TJSONValue; const ABaseURI: string; const ACustomHint: TJSONValue);
begin
  inherited Create(ASchema, AData, ABaseURI, ACustomHint);

  FCore                := TDraft7CoreVisitor.Create(Self);
  FApplicator          := TDraft7ApplicatorVisitor.Create(Self);
  FValidation          := TDraft7ValidationVisitor.Create(Self);
  FHyperSchema         := TDraft7HyperSchemaVisitor.Create(Self);
  FRelativeJsonPointer := TDraft7RelativeJsonPointer.Create(Self);
end;

function TDraft7Visitor.KeywordPrecedence: TArray<string>;
begin
  Result := [
    '$schema',
    '$id',
    'id',
    '$ref',
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
    'oneOf'
  ];
end;

function TDraft7Visitor.New(const ASchema, AData: TJSONValue; const ABaseURI: string): TDraft7Visitor;
begin
  Result := TDraft7Visitor.Create(ASchema, AData, ABaseURI, FCustomHint);
  Result.FRegistry.Free;
  Result.FRegistry := FRegistry;
  Result.FOwnsRegistry := False;
end;

{ TDraft7CoreVisitor }

procedure TDraft7CoreVisitor.VisitComment(const AValue: TJSONString);
begin

end;

{ TDraft7ApplicatorVisitor }

procedure TDraft7ApplicatorVisitor.VisitElse(const AValue: TJSONValue);
var
  LScope: TScope;
  LWalker: IWalker;
  LNewScope: TScope;
begin
  LScope := Visitor.CurrentScope;
  if LScope.SchemaNode.FindValue('if') = nil then
    Exit;

  LNewScope := LScope;
  with LNewScope do
  begin
    SchemaPath        := Format('%s/else', [SchemaPath]);
    SchemaNode        := AValue;
    InstanceNode      := InstanceNode;
    InstancePath      := Format('%s', [InstancePath]);
    CoveredItems      := [];
    ContainsCount     := 0;
    VisitedKeywords   := [];
    CoveredProperties := [];
  end;

  Visitor.PushScope(LNewScope);
  try
    LWalker := TWalker<TDraft7Visitor>.Create(LNewScope.SchemaNode, Visitor);
    LWalker.Walk;
  finally
    Visitor.PopScope;
  end;
end;

procedure TDraft7ApplicatorVisitor.VisitIf(const AValue: TJSONValue);
var
  LScope: TScope;
  LWalker: IWalker;
  LSchema: TJSONValue;
  LSubVisitor: TDraft7Visitor;
  LNewScope: TScope;
begin
  LScope := Visitor.CurrentScope;

  LNewScope := LScope;
  with LNewScope do
  begin
    SchemaPath        := Format('%s/if', [SchemaPath]);
    SchemaNode        := AValue;
    InstanceNode      := InstanceNode;
    InstancePath      := Format('%s', [InstancePath]);
    CoveredItems      := [];
    ContainsCount     := 0;
    VisitedKeywords   := [];
    CoveredProperties := [];
  end;

  LSubVisitor := Visitor.New(LNewScope.SchemaNode, LNewScope.InstanceNode, LScope.BaseURI);
  LSubVisitor.PushScope(LNewScope);
  try
    LWalker := TWalker<TDraft7Visitor>.Create(LNewScope.SchemaNode, LSubVisitor);
    LWalker.Walk;
  finally
    LNewScope := LSubVisitor.PopScope;
    LScope.CoveredItems      := TUtils.MergeArray<Integer>([LScope.CoveredItems, LNewScope.CoveredItems]);
    LScope.CoveredProperties := TUtils.MergeArray<string>([LScope.CoveredProperties, LNewScope.CoveredProperties]);
  end;

  Visitor.UpdateScope(LScope);

  if LSubVisitor.Result.IsValid and LScope.SchemaNode.TryGetValue('then', LSchema) then
    VisitThen(LSchema)
  else if (not LSubVisitor.Result.IsValid) and LScope.SchemaNode.TryGetValue('else', LSchema) then
    VisitElse(LSchema);

  Visitor
    .AddVisitedKeyword('then')
    .AddVisitedKeyword('else');
end;

procedure TDraft7ApplicatorVisitor.VisitThen(const AValue: TJSONValue);
var
  LScope: TScope;
  LWalker: IWalker;
  LNewScope: TScope;
begin
  LScope := Visitor.CurrentScope;
  if LScope.SchemaNode.FindValue('if') = nil then
    Exit;

  LNewScope := LScope;
  with LNewScope do
  begin
    SchemaPath        := Format('%s/then', [SchemaPath]);
    SchemaNode        := AValue;
    InstanceNode      := InstanceNode;
    InstancePath      := Format('%s', [InstancePath]);
    CoveredItems      := [];
    ContainsCount     := 0;
    VisitedKeywords   := [];
    CoveredProperties := [];
  end;

  Visitor.PushScope(LNewScope);
  try
    LWalker := TWalker<TDraft7Visitor>.Create(LNewScope.SchemaNode, Visitor);
    LWalker.Walk;
  finally
    Visitor.PopScope;
  end;
end;

{ TDraft7ValidationVisitor }

procedure TDraft7ValidationVisitor.VisitConst(const AValue: TJSONValue);
begin
  inherited VisitConst(AValue);
end;

procedure TDraft7ValidationVisitor.VisitContains(const AValue: TJSONValue);
var
  LScope: TScope;
  LCount: Integer;
  LWalker: IWalker;
  LVisitor: TDraft7Visitor;
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
      LWalker := TWalker<TDraft7Visitor>.Create(AValue, LVisitor);
      LWalker.Walk;
    finally
      Visitor.PopScope;
    end;

    if LVisitor.Result.IsValid then
      Inc(LScope.ContainsCount);
  end;

  Visitor.UpdateScope(LScope);
  if LScope.ContainsCount = 0 then
    Visitor.AddError(vetContains);
end;

procedure TDraft7ValidationVisitor.VisitDependencies(const AValue: TJSONObject);
var
  LScope: TScope;
  LInstance: TJSONObject;
  LDependencyPair: TJSONPair;
  LDependencyValue: TJSONValue;
  LRequiredList: TJSONArray;
  LRequiredValue: TJSONValue;
  LRequiredName: string;
  LNewScope: TScope;
  LWalker: IWalker;
  LVisitor: TDraft7Visitor;
  LError: IError;
begin
  LScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(LScope.InstanceNode) <> 'object' then
    Exit;

  LInstance := TJSONObject(LScope.InstanceNode);
  for LDependencyPair in AValue do
  begin
    if LInstance.FindValue(LDependencyPair.JsonString.Value) = nil then
      Continue;

    LDependencyValue := LDependencyPair.JsonValue;

    if LDependencyValue is TJSONArray then
    begin
      LRequiredList := TJSONArray(LDependencyValue);
      for LRequiredValue in LRequiredList do
      begin
        if not (LRequiredValue is TJSONString) then
          Continue;

        LRequiredName := TJSONString(LRequiredValue).Value;
        if LInstance.FindValue(LRequiredName) = nil then
          Visitor.AddError(vetDependentRequired, [LDependencyPair.JsonString.Value, LRequiredName]);
      end;
      Continue;
    end;

    if (LDependencyValue is TJSONObject) or (LDependencyValue is TJSONBool) then
    begin
      LNewScope := LScope;
      with LNewScope do
      begin
        SchemaPath        := Format('%s/dependencies/%s', [LScope.SchemaPath, LDependencyPair.JsonString.Value]);
        SchemaNode        := LDependencyValue;
        InstanceNode      := LScope.InstanceNode;
        InstancePath      := LScope.InstancePath;
        CoveredItems      := [];
        ContainsCount     := 0;
        VisitedKeywords   := [];
        CoveredProperties := [];
      end;

      LVisitor := Visitor.New(LDependencyValue, LScope.InstanceNode, LScope.BaseURI);
      LVisitor.PushScope(LNewScope);
      try
        LWalker := TWalker<TDraft7Visitor>.Create(LDependencyValue, LVisitor);
        LWalker.Walk;
      finally
        LVisitor.PopScope;
      end;

      if not LVisitor.Result.IsValid then
        for LError in LVisitor.Result.Errors do
          Visitor.Result.AddError(LError);
    end;
  end;
end;

procedure TDraft7ValidationVisitor.VisitPropertyNames(const AValue: TJSONValue);
var
  LPair: TJSONPair;
  LScope: TScope;
  LWalker: IWalker;
  LVisitor: TDraft7Visitor;
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
      LWalker := TWalker<TDraft7Visitor>.Create(LNewScope.SchemaNode, LVisitor);
      LWalker.Walk;
    finally
      Visitor.PopScope;
    end;

    if not LVisitor.Result.IsValid then
      Visitor.AddError(vetInvalidPropertyName, [LPair.JsonString.Value]);
  end;
end;

{ TDraft7HyperSchemaVisitor }

procedure TDraft7HyperSchemaVisitor.VisitAnchor(const AValue: TJSONString);
begin

end;

procedure TDraft7HyperSchemaVisitor.VisitAnchorPointer(const AValue: TJSONString);
begin

end;

procedure TDraft7HyperSchemaVisitor.VisitDescription(const AValue: TJSONString);
begin

end;

procedure TDraft7HyperSchemaVisitor.VisitHeaderSchema(const AValue: TJSONValue);
begin

end;

procedure TDraft7HyperSchemaVisitor.VisitReadOnly(const AValue: TJSONBool);
begin

end;

procedure TDraft7HyperSchemaVisitor.VisitRel(const AValue: TJSONString);
begin

end;

procedure TDraft7HyperSchemaVisitor.VisitSubmissionMediaType(const AValue: TJSONString);
begin

end;

procedure TDraft7HyperSchemaVisitor.VisitTargetHints(const AValue: TJSONObject);
begin

end;

procedure TDraft7HyperSchemaVisitor.VisitTargetMediaType(const AValue: TJSONString);
begin

end;

procedure TDraft7HyperSchemaVisitor.VisitTemplatePointers(const AValue: TJSONObject);
begin

end;

procedure TDraft7HyperSchemaVisitor.VisitTemplateRequired(const AValue: TJSONArray);
begin

end;

procedure TDraft7HyperSchemaVisitor.VisitTitle(const AValue: TJSONString);
begin

end;

end.

