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
  IDraft2020_12FormatAssertionMode = interface(IInterface)
    ['{1E9E0329-00E8-47F6-AB75-A0A33A3774E4}']
    function IsFormatAssertionEnabled: Boolean;
    procedure SetFormatAssertionEnabled(const AValue: Boolean);
  end;

  TDraft2020_12Visitor = class(TValidationVisitor<TDraft2020_12Visitor>)
  private
    FFormatAssertionEnabled: Boolean;
  public
    constructor Create(const ASchema, AData: TJSONValue; const ABaseURI: string; const ACustomHint: TJSONValue = nil);
    function New(const ASchema, AData: TJSONValue; const ABaseURI: string): TDraft2020_12Visitor; override;
    function KeywordPrecedence: TArray<string>; override;
    function IsFormatAssertionEnabled: Boolean;
    procedure SetFormatAssertionEnabled(const AValue: Boolean);
  end;

  IDraft2020_12CoreVisitor = interface(IBaseCoreVisitor<TDraft2020_12Visitor>)
    ['{D73FF534-BC9D-4673-8C79-EF7D745FF989}']
    procedure VisitSchema(const AValue: TJSONString);
    procedure VisitComment(const AValue: TJSONString);
    procedure VisitAnchor(const AValue: TJSONString);
    procedure VisitDynamicRef(const AValue: TJSONString);
    procedure VisitDynamicAnchor(const AValue: TJSONString);
    procedure VisitVocabulary(const AValue: TJSONObject);
  end;

  IDraft2020_12ApplicatorVisitor = interface(IBaseApplicatorVisitor<TDraft2020_12Visitor>)
    ['{93807819-1E9D-4017-A18B-67D5E9DDEC91}']
    procedure VisitItems(const AValue: TJSONValue);
    procedure VisitPrefixItems(const AValue: TJSONArray);
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
    [VisitorKeyword('$schema')]
    procedure VisitSchema(const AValue: TJSONString);
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
    [VisitorKeyword('items')]
    procedure VisitItems(const AValue: TJSONValue);
    [VisitorKeyword('prefixItems')]
    procedure VisitPrefixItems(const AValue: TJSONArray);
    [VisitorKeyword('dependentSchemas')]
    procedure VisitDependentSchemas(const AValue: TJSONObject);
    [VisitorKeyword('unevaluatedItems')]
    procedure VisitUnevaluatedItems(const AValue: TJSONValue);
    [VisitorKeyword('unevaluatedProperties')]
    procedure VisitUnevaluatedProperties(const AValue: TJSONValue);
  end;

  TDraft2020_12ValidationVisitor = class(TBaseValidationVisitor<TDraft2020_12Visitor>, IDraft2020_12ValidationVisitor)
    [VisitorKeyword('format')]
    procedure VisitFormat(const AValue: TJSONString);
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
  System.StrUtils,
  System.Generics.Collections,
  JsonSchema.Common.Utils,
  JsonSchema.Translate.Types,
  JsonSchema.Walker,
  JsonSchema.Registry.Resource,
  JsonSchema.Registry.Uri;

{ TDraft2020_12Visitor }

constructor TDraft2020_12Visitor.Create(const ASchema, AData: TJSONValue; const ABaseURI: string; const ACustomHint: TJSONValue);
begin
  inherited Create(ASchema, AData, ABaseURI, ACustomHint);

  FFormatAssertionEnabled := False;

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
  Result.FRegistry.Free;
  Result.FRegistry := FRegistry;
  Result.FOwnsRegistry := False;
  Result.FFormatAssertionEnabled := FFormatAssertionEnabled;
end;

function TDraft2020_12Visitor.IsFormatAssertionEnabled: Boolean;
begin
  Result := FFormatAssertionEnabled;
end;

procedure TDraft2020_12Visitor.SetFormatAssertionEnabled(const AValue: Boolean);
begin
  FFormatAssertionEnabled := AValue;
end;

{ TDraft2020_12CoreVisitor }

procedure TDraft2020_12CoreVisitor.VisitSchema(const AValue: TJSONString);
const
  CFormatAssertionVocabularyURI = 'https://json-schema.org/draft/2020-12/vocab/format-assertion';
var
  LScope: TScope;
  LSchemaURI: TURIReference;
  LMetaResource: TResource;
  LMetaSchemaRoot: TJSONValue;
  LVocabularyValue: TJSONValue;
  LFormatAssertionValue: TJSONValue;
  LFormatAssertionRequired: Boolean;
begin
  LScope := Visitor.CurrentScope;
  LSchemaURI := TURIReference.From(AValue.Value).ResolveWith(TURIReference.From(LScope.BaseURI));

  if not Visitor.Registry.TryFindResource(LSchemaURI.Unsplit, LMetaResource) then
    Exit;

  LMetaSchemaRoot := LMetaResource.ResolveFragment('');
  if not (LMetaSchemaRoot is TJSONObject) then
    Exit;

  LFormatAssertionRequired := False;
  if TJSONObject(LMetaSchemaRoot).TryGetValue('$vocabulary', LVocabularyValue) and (LVocabularyValue is TJSONObject) and
     TJSONObject(LVocabularyValue).TryGetValue(CFormatAssertionVocabularyURI, LFormatAssertionValue) and
     (LFormatAssertionValue is TJSONBool) then
    LFormatAssertionRequired := TJSONBool(LFormatAssertionValue).AsBoolean;

  TDraft2020_12Visitor(Visitor).SetFormatAssertionEnabled(LFormatAssertionRequired);
  if not LFormatAssertionRequired then
    Visitor.AddVisitedKeyword('format');
end;

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
var
  LScope: TScope;
  LFinalURI: TURIReference;
  LTargetResource: TResource;
  LTargetSchema: TJSONValue;
  LResolvedBaseURI: string;
  LDynamicAnchorName: string;
  LDynamicAnchorValue: TJSONValue;
  LScopeAnchorValue: TJSONValue;
  LOffset: Integer;
  LDynamicBaseURI: string;
  LDynamicRefValue: TJSONString;
  LOriginalScope: TScope;
  LScopeAfterRef: TScope;
begin
  LScope := Visitor.CurrentScope;
  LFinalURI := TURIReference.From(AValue.Value).ResolveWith(TURIReference.From(LScope.BaseURI));
  LDynamicAnchorName := LFinalURI.Fragment;

  if LDynamicAnchorName.IsEmpty or LDynamicAnchorName.StartsWith('/') then
  begin
    LOriginalScope := Visitor.CurrentScope;
    try
      inherited VisitRef(AValue);
    finally
      LScopeAfterRef := Visitor.CurrentScope;
      if not SameText(LScopeAfterRef.BaseURI, LOriginalScope.BaseURI) then
      begin
        LScopeAfterRef.BaseURI := LOriginalScope.BaseURI;
        Visitor.UpdateScope(LScopeAfterRef);
      end;
    end;
    Exit;
  end;

  if not Visitor.Registry.TryFindResource(LFinalURI.Unsplit, LTargetResource) then
  begin
    LOriginalScope := Visitor.CurrentScope;
    try
      inherited VisitRef(AValue);
    finally
      LScopeAfterRef := Visitor.CurrentScope;
      if not SameText(LScopeAfterRef.BaseURI, LOriginalScope.BaseURI) then
      begin
        LScopeAfterRef.BaseURI := LOriginalScope.BaseURI;
        Visitor.UpdateScope(LScopeAfterRef);
      end;
    end;
    Exit;
  end;

  LTargetSchema := LTargetResource.ResolveFragment(LDynamicAnchorName, LResolvedBaseURI);
  if not Assigned(LTargetSchema) then
  begin
    LOriginalScope := Visitor.CurrentScope;
    try
      inherited VisitRef(AValue);
    finally
      LScopeAfterRef := Visitor.CurrentScope;
      if not SameText(LScopeAfterRef.BaseURI, LOriginalScope.BaseURI) then
      begin
        LScopeAfterRef.BaseURI := LOriginalScope.BaseURI;
        Visitor.UpdateScope(LScopeAfterRef);
      end;
    end;
    Exit;
  end;

  if not ((LTargetSchema is TJSONObject) and
          TJSONObject(LTargetSchema).TryGetValue('$dynamicAnchor', LDynamicAnchorValue) and
          (LDynamicAnchorValue is TJSONString) and
          SameText(TJSONString(LDynamicAnchorValue).Value, LDynamicAnchorName)) then
  begin
    LOriginalScope := Visitor.CurrentScope;
    try
      inherited VisitRef(AValue);
    finally
      LScopeAfterRef := Visitor.CurrentScope;
      if not SameText(LScopeAfterRef.BaseURI, LOriginalScope.BaseURI) then
      begin
        LScopeAfterRef.BaseURI := LOriginalScope.BaseURI;
        Visitor.UpdateScope(LScopeAfterRef);
      end;
    end;
    Exit;
  end;

  LDynamicBaseURI := '';
  LOffset := 0;
  while Assigned(Visitor.CurrentScope(LOffset).SchemaNode) do
  begin
    LScope := Visitor.CurrentScope(LOffset);
    if (LScope.SchemaNode is TJSONObject) and
       TJSONObject(LScope.SchemaNode).TryGetValue('$dynamicAnchor', LScopeAnchorValue) and
       (LScopeAnchorValue is TJSONString) and
       SameText(TJSONString(LScopeAnchorValue).Value, LDynamicAnchorName) then
    begin
      LDynamicBaseURI := LScope.BaseURI;
      Break;
    end;
    Inc(LOffset);
  end;

  if LDynamicBaseURI.IsEmpty then
  begin
    LOriginalScope := Visitor.CurrentScope;
    try
      inherited VisitRef(AValue);
    finally
      LScopeAfterRef := Visitor.CurrentScope;
      if not SameText(LScopeAfterRef.BaseURI, LOriginalScope.BaseURI) then
      begin
        LScopeAfterRef.BaseURI := LOriginalScope.BaseURI;
        Visitor.UpdateScope(LScopeAfterRef);
      end;
    end;
    Exit;
  end;

  LDynamicRefValue := TJSONString.Create(LDynamicBaseURI + '#' + LDynamicAnchorName);
  try
    LOriginalScope := Visitor.CurrentScope;
    try
      inherited VisitRef(LDynamicRefValue);
    finally
      LScopeAfterRef := Visitor.CurrentScope;
      if not SameText(LScopeAfterRef.BaseURI, LOriginalScope.BaseURI) then
      begin
        LScopeAfterRef.BaseURI := LOriginalScope.BaseURI;
        Visitor.UpdateScope(LScopeAfterRef);
      end;
    end;
  finally
    LDynamicRefValue.Free;
  end;
end;

procedure TDraft2020_12CoreVisitor.VisitVocabulary(const AValue: TJSONObject);
const
  CFormatAssertionVocabularyURI = 'https://json-schema.org/draft/2020-12/vocab/format-assertion';
var
  LFormatAssertionValue: TJSONValue;
begin
  if AValue.TryGetValue(CFormatAssertionVocabularyURI, LFormatAssertionValue) and
     (LFormatAssertionValue is TJSONBool) then
  begin
    TDraft2020_12Visitor(Visitor).SetFormatAssertionEnabled(TJSONBool(LFormatAssertionValue).AsBoolean);
    if not TJSONBool(LFormatAssertionValue).AsBoolean then
      Visitor.AddVisitedKeyword('format');
  end;
end;

{ TDraft2020_12ValidationVisitor }

procedure TDraft2020_12ValidationVisitor.VisitFormat(const AValue: TJSONString);
begin
  if not TDraft2020_12Visitor(Visitor).IsFormatAssertionEnabled then
    Exit;

  inherited VisitFormat(AValue);
end;

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
var
  LScope: TScope;
  LInstance: TJSONObject;
  LDependencyPair: TJSONPair;
  LRequiredList: TJSONArray;
  LRequiredValue: TJSONValue;
  LRequiredName: string;
begin
  LScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(LScope.InstanceNode) <> 'object' then
    Exit;

  LInstance := TJSONObject(LScope.InstanceNode);
  for LDependencyPair in AValue do
  begin
    if LInstance.FindValue(LDependencyPair.JsonString.Value) = nil then
      Continue;

    if not (LDependencyPair.JsonValue is TJSONArray) then
      Continue;

    LRequiredList := TJSONArray(LDependencyPair.JsonValue);
    for LRequiredValue in LRequiredList do
    begin
      if not (LRequiredValue is TJSONString) then
        Continue;

      LRequiredName := TJSONString(LRequiredValue).Value;
      if LInstance.FindValue(LRequiredName) = nil then
        Visitor.AddError(vetDependentRequired, [LDependencyPair.JsonString.Value, LRequiredName]);
    end;
  end;
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

procedure TDraft2020_12ApplicatorVisitor.VisitItems(const AValue: TJSONValue);
begin
  // Em 2020-12, tuple validation foi movida para prefixItems.
  if AValue is TJSONArray then
    Exit;

  inherited VisitItems(AValue);
end;

procedure TDraft2020_12ApplicatorVisitor.VisitPrefixItems(const AValue: TJSONArray);
begin
  inherited VisitPrefixItems(AValue);
end;

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

