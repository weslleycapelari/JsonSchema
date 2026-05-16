unit JsonSchema.Validation.Draft2020_12;

interface

uses
  System.JSON,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Types,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Validation.Base,
  JsonSchema.Validation.Interfaces;

type
  TDraft2020_12Visitor = class(TValidationVisitor<TDraft2020_12Visitor>)
  public
    constructor Create(const ASchema, AData: TJSONValue; const ABaseURI: string; const ACustomHint: TJSONValue = nil);
    function New(const ASchema, AData: TJSONValue; const ABaseURI: string): TDraft2020_12Visitor; override;
    function KeywordPrecedence: TArray<string>; override;
  end;

  IDraft2020_12CoreVisitor = interface(IBaseCoreVisitor<TDraft2020_12Visitor>)
    ['{D73FF534-BC9D-4673-8C79-EF7D745FF989}']
    procedure VisitComment(const AValue: TJSONString);
    procedure VisitAnchor(const AValue: TJSONString);
    procedure VisitDynamicRef(const AValue: TJSONString);
    procedure VisitDynamicAnchor(const AValue: TJSONString);
    procedure VisitVocabulary(const AValue: TJSONObject);
  end;

  IDraft2020_12ApplicatorVisitor = interface(IBaseApplicatorVisitor<TDraft2020_12Visitor>)
    ['{93807819-1E9D-4017-A18B-67D5E9DDEC91}']
    procedure VisitDependentSchemas(const AValue: TJSONObject);
    procedure VisitUnevaluatedItems(const AValue: TJSONValue);
    procedure VisitUnevaluatedProperties(const AValue: TJSONValue);
  end;

  IDraft2020_12ValidationVisitor = interface(IBaseValidationVisitor<TDraft2020_12Visitor>)
    ['{5FCB391C-EA34-44F8-B46B-05423547C9F6}']
    procedure VisitContains(const AValue: TJSONValue);
    procedure VisitPropertyNames(const AValue: TJSONValue);
    procedure VisitDependentRequired(const AValue: TJSONObject);
    procedure VisitMaxContains(const AValue: TJSONNumber);
    procedure VisitMinContains(const AValue: TJSONNumber);
  end;

  IDraft2020_12RelativeJsonPointer = interface(IBaseRelativeJsonPointer<TDraft2020_12Visitor>)
    ['{B4EA36F6-247C-41AA-BCC6-5A83AC80CE1B}']
  end;

  TDraft2020_12CoreVisitor = class(TBaseCoreVisitor<TDraft2020_12Visitor>, IDraft2020_12CoreVisitor)
    [VisitorKeyword('$comment')]
    procedure VisitComment(const AValue: TJSONString);
    [VisitorKeyword('$anchor')]
    procedure VisitAnchor(const AValue: TJSONString);
    [VisitorKeyword('$dynamicRef')]
    procedure VisitDynamicRef(const AValue: TJSONString);
    [VisitorKeyword('$dynamicAnchor')]
    procedure VisitDynamicAnchor(const AValue: TJSONString);
    [VisitorKeyword('$vocabulary')]
    procedure VisitVocabulary(const AValue: TJSONObject);
  end;

  TDraft2020_12ApplicatorVisitor = class(TBaseApplicatorVisitor<TDraft2020_12Visitor>, IDraft2020_12ApplicatorVisitor)
    [VisitorKeyword('dependentSchemas')]
    procedure VisitDependentSchemas(const AValue: TJSONObject);
    [VisitorKeyword('unevaluatedItems')]
    procedure VisitUnevaluatedItems(const AValue: TJSONValue);
    [VisitorKeyword('unevaluatedProperties')]
    procedure VisitUnevaluatedProperties(const AValue: TJSONValue);
  end;

  TDraft2020_12ValidationVisitor = class(TBaseValidationVisitor<TDraft2020_12Visitor>, IDraft2020_12ValidationVisitor)
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

  TDraft2020_12RelativeJsonPointer = class(TBaseRelativeJsonPointer<TDraft2020_12Visitor>, IDraft2020_12RelativeJsonPointer)
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  System.Generics.Collections,
  JsonSchema.Common.Utils,
  JsonSchema.Translate.Types,
  JsonSchema.Walker;

{ TDraft2020_12Visitor }

constructor TDraft2020_12Visitor.Create(const ASchema, AData: TJSONValue; const ABaseURI: string; const ACustomHint: TJSONValue);
begin
  inherited Create(ASchema, AData, ABaseURI, ACustomHint);

  FCore                := TDraft2020_12CoreVisitor.Create(Self);
  FApplicator          := TDraft2020_12ApplicatorVisitor.Create(Self);
  FValidation          := TDraft2020_12ValidationVisitor.Create(Self);
  FRelativeJsonPointer := TDraft2020_12RelativeJsonPointer.Create(Self);
end;

function TDraft2020_12Visitor.KeywordPrecedence: TArray<string>;
begin
  Result := [
    '$schema',
    '$id',
    '$ref',
    '$dynamicRef',
    '$anchor',
    '$dynamicAnchor',
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

function TDraft2020_12Visitor.New(const ASchema, AData: TJSONValue; const ABaseURI: string): TDraft2020_12Visitor;
begin
  Result := TDraft2020_12Visitor.Create(ASchema, AData, ABaseURI, FCustomHint);
end;

{ TDraft2020_12CoreVisitor }

procedure TDraft2020_12CoreVisitor.VisitAnchor(const AValue: TJSONString);
begin

end;

procedure TDraft2020_12CoreVisitor.VisitComment(const AValue: TJSONString);
begin

end;

procedure TDraft2020_12CoreVisitor.VisitDynamicAnchor(const AValue: TJSONString);
begin

end;

procedure TDraft2020_12CoreVisitor.VisitDynamicRef(const AValue: TJSONString);
begin

end;

procedure TDraft2020_12CoreVisitor.VisitVocabulary(const AValue: TJSONObject);
begin

end;

{ TDraft2020_12ValidationVisitor }

procedure TDraft2020_12ValidationVisitor.VisitContains(const AValue: TJSONValue);
var
  LScope: TScope;
  LCount: Integer;
  LWalker: IWalker;
  LSchema: TJSONNumber;
  LVisitor: TDraft2020_12Visitor;
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
    LNewScope.SchemaPath        := Format('%s/contains', [LScope.SchemaPath]);
    LNewScope.SchemaNode        := AValue;
    LNewScope.InstanceNode      := LInstance[LCount];
    LNewScope.InstancePath      := Format('%s/%d', [LScope.InstancePath, LCount]);
    LNewScope.CoveredItems      := [];
    LNewScope.ContainsCount     := 0;
    LNewScope.VisitedKeywords   := [];
    LNewScope.CoveredProperties := [];

    Visitor.PushScope(LNewScope);
    LVisitor := Visitor.New(AValue, LInstance[LCount], LScope.BaseURI);
    try
      LWalker := TWalker<TDraft2020_12Visitor>.Create(AValue, LVisitor);
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

procedure TDraft2020_12ValidationVisitor.VisitDependentRequired(const AValue: TJSONObject);
begin

end;

procedure TDraft2020_12ValidationVisitor.VisitMaxContains(const AValue: TJSONNumber);
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

procedure TDraft2020_12ValidationVisitor.VisitMinContains(const AValue: TJSONNumber);
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

procedure TDraft2020_12ValidationVisitor.VisitPropertyNames(const AValue: TJSONValue);
begin
  inherited VisitPropertyNames(AValue);
end;

{ TDraft2020_12ApplicatorVisitor }

procedure TDraft2020_12ApplicatorVisitor.VisitDependentSchemas(const AValue: TJSONObject);
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
      LNewScope.SchemaPath   := Format('%s/dependentSchemas/%s', [LScope.SchemaPath, LDependencyPair.JsonString.Value]);
      LNewScope.SchemaNode   := LSubSchema;
      LNewScope.InstancePath := Format('%s', [LScope.InstancePath]);

      Visitor.PushScope(LNewScope);
      try
        LWalker := TWalker<TDraft2020_12Visitor>.Create(LSubSchema, Visitor);
        LWalker.Walk;
      finally
        Visitor.PopScope;
      end;
    end;
  end;
end;

procedure TDraft2020_12ApplicatorVisitor.VisitUnevaluatedItems(const AValue: TJSONValue);
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

  if (TUtils.JsonGetType(AValue) = 'boolean') and TJSONBool(AValue).AsBoolean then
    Exit;

  LCovered := TList<Integer>.Create(LScope.CoveredItems);
  try
    for LCount := 0 to TJSONArray(LScope.InstanceNode).Count - 1 do
    begin
      if LCovered.Contains(LCount) then
        Continue;

      LNewScope := LScope;
      LNewScope.SchemaPath        := Format('%s/unevaluatedItems', [LScope.SchemaPath]);
      LNewScope.SchemaNode        := AValue;
      LNewScope.InstanceNode      := TJSONArray(LScope.InstanceNode)[LCount];
      LNewScope.InstancePath      := Format('%s/%d', [LScope.InstancePath, LCount]);
      LNewScope.CoveredItems      := [];
      LNewScope.ContainsCount     := 0;
      LNewScope.VisitedKeywords   := [];
      LNewScope.CoveredProperties := [];

      Visitor.PushScope(LNewScope);
      try
        LWalker := TWalker<TDraft2020_12Visitor>.Create(AValue, Visitor);
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

procedure TDraft2020_12ApplicatorVisitor.VisitUnevaluatedProperties(const AValue: TJSONValue);
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

  if (TUtils.JsonGetType(AValue) = 'boolean') and TJSONBool(AValue).AsBoolean then
    Exit;

  LCovered := TList<string>.Create(LScope.CoveredProperties);
  try
    for LPair in TJSONObject(LScope.InstanceNode) do
    begin
      if LCovered.Contains(LPair.JsonString.Value) then
        Continue;

      LNewScope := LScope;
      LNewScope.SchemaPath        := Format('%s/unevaluatedProperties', [LScope.SchemaPath]);
      LNewScope.SchemaNode        := AValue;
      LNewScope.InstanceNode      := LPair.JsonValue;
      LNewScope.InstancePath      := Format('%s/%s', [LScope.InstancePath, LPair.JsonString.Value]);
      LNewScope.CoveredItems      := [];
      LNewScope.ContainsCount     := 0;
      LNewScope.VisitedKeywords   := [];
      LNewScope.CoveredProperties := [];

      Visitor.PushScope(LNewScope);
      try
        LWalker := TWalker<TDraft2020_12Visitor>.Create(AValue, Visitor);
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

