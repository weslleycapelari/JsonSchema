unit JsonSchema.Validation.Visitor.Applicator;

interface

uses
  System.JSON,
  System.Generics.Collections,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Types,
  JsonSchema.Validation.Interfaces;

type
  /// <summary>
  ///   Base visitor that handles the JSON Schema Applicator vocabulary keywords:
  ///   allOf, anyOf, oneOf, not, if/then/else, properties, items, and related keywords.
  /// </summary>
  TBaseApplicatorVisitor<T: IValidationVisitor<T>> = class(TBase<T>, IBaseApplicatorVisitor<T>)
    [VisitorKeyword('allOf')]
    procedure VisitAllOf(const pValue: TJSONArray);
    [VisitorKeyword('anyOf')]
    procedure VisitAnyOf(const pValue: TJSONArray);
    [VisitorKeyword('oneOf')]
    procedure VisitOneOf(const pValue: TJSONArray);
    [VisitorKeyword('not')]
    procedure VisitNot(const pValue: TJSONValue);

    // Condition
    [VisitorKeyword('if')]
    procedure VisitIf(const pValue: TJSONValue);
    [VisitorKeyword('then')]
    procedure VisitThen(const pValue: TJSONValue);
    [VisitorKeyword('else')]
    procedure VisitElse(const pValue: TJSONValue);

    // Objects
    [VisitorKeyword('properties')]
    procedure VisitProperties(const pValue: TJSONObject);
    [VisitorKeyword('patternProperties')]
    procedure VisitPatternProperties(const pValue: TJSONObject);
    [VisitorKeyword('additionalProperties')]
    procedure VisitAdditionalProperties(const pValue: TJSONValue);

    // Arrays
    [VisitorKeyword('items')]
    procedure VisitItems(const pValue: TJSONValue);
    [VisitorKeyword('additionalItems')]
    procedure VisitAdditionalItems(const pValue: TJSONValue);
    [VisitorKeyword('prefixItems')]
    procedure VisitPrefixItems(const pValue: TJSONArray);
  strict private
    procedure ReconstructParentScopeChain(const pChildVisitor: T);
    procedure CollectBranchEvaluatedProperties(const pBranchVisitor: T; const pBranchScope: TScope; const pParentInstancePath: string;
      pCombinedEvaluated: THashSet<string>);
    procedure MergeEvaluatedPropertiesIntoScope(pSource: THashSet<string>; var pScope: TScope);
    function NormalizeEvaluatedPropertyPath(const pProp, pInstancePath: string): string;
  end;

implementation

uses
  System.SysUtils,
  System.Math,
  System.RegularExpressions,
  JsonSchema.Translate.Types,
  JsonSchema.Common.Utils,
  JsonSchema.Walker,
  JsonSchema.Walker.Types;

{ TBaseApplicatorVisitor<T> }

function TBaseApplicatorVisitor<T>.NormalizeEvaluatedPropertyPath(const pProp, pInstancePath: string): string;
begin
  Result := pProp;
  if Result.IsEmpty then
    Exit;
  if (pInstancePath <> '#') and not Result.StartsWith(pInstancePath + '/') then
  begin
    if Result = '#' then
      Result := pInstancePath
    else if Result.StartsWith('#/') then
      Result := Result.Substring(1)
    else if Result.StartsWith('/') then
    begin
      // Paths starting with '/' are already absolute in the document.
    end
    else
      Result := pInstancePath + '/' + Result;
  end;
end;

procedure TBaseApplicatorVisitor<T>.ReconstructParentScopeChain(const pChildVisitor: T);
var
  lParentOffset: Integer;
  lParentMaxOffset: Integer;
  lParentScopeItem: TScope;
begin
  pChildVisitor.PopScope;
  lParentMaxOffset := -1;
  lParentOffset := 0;
  while Assigned(Visitor.CurrentScope(lParentOffset).SchemaNode) do
  begin
    lParentMaxOffset := lParentOffset;
    Inc(lParentOffset);
  end;
  for lParentOffset := lParentMaxOffset downto 0 do
  begin
    lParentScopeItem := Visitor.CurrentScope(lParentOffset);
    lParentScopeItem.EvaluatedPropertiesInScope := nil;
    pChildVisitor.PushScope(lParentScopeItem);
  end;
end;

procedure TBaseApplicatorVisitor<T>.CollectBranchEvaluatedProperties(
  const pBranchVisitor: T;
  const pBranchScope: TScope;
  const pParentInstancePath: string;
  pCombinedEvaluated: THashSet<string>);
var
  lEvaluatedProperty: string;
  lNormalizedEvaluatedProperty: string;
begin
  if not Assigned(pBranchScope.EvaluatedPropertiesInScope) then
    Exit;

  for lEvaluatedProperty in pBranchVisitor.Result.EvaluatedProperties do
  begin
    lNormalizedEvaluatedProperty := NormalizeEvaluatedPropertyPath(lEvaluatedProperty, pParentInstancePath);
    pBranchScope.EvaluatedPropertiesInScope.Add(lNormalizedEvaluatedProperty);
  end;

  for lEvaluatedProperty in pBranchScope.EvaluatedPropertiesInScope do
  begin
    lNormalizedEvaluatedProperty := NormalizeEvaluatedPropertyPath(lEvaluatedProperty, pParentInstancePath);
    pCombinedEvaluated.Add(lNormalizedEvaluatedProperty);
    Visitor.Result.AddEvaluatedProperty(lNormalizedEvaluatedProperty);
  end;
end;

procedure TBaseApplicatorVisitor<T>.MergeEvaluatedPropertiesIntoScope(
  pSource: THashSet<string>;
  var pScope: TScope);
var
  lEvaluatedProperty: string;
begin
  if pSource.Count = 0 then
    Exit;
  if not Assigned(pScope.EvaluatedPropertiesInScope) then
    pScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
  for lEvaluatedProperty in pSource do
    pScope.EvaluatedPropertiesInScope.Add(lEvaluatedProperty);
end;

procedure TBaseApplicatorVisitor<T>.VisitAdditionalItems(const pValue: TJSONValue);
var
  lCount: Integer;
  lScope: TScope;
  lItems: TJSONValue;
  lWalker: IWalker;
  lCovered: TList<Integer>;
  lNewScope: TScope;
begin
  lScope := Visitor.CurrentScope;

  if TUtils.JsonGetType(lScope.InstanceNode) <> 'array' then
    Exit;

  if (not lScope.SchemaNode.TryGetValue('items', lItems)) or (TUtils.JsonGetType(lItems) <> 'array') then
    Exit;

  lCovered := TList<Integer>.Create(lScope.CoveredItems);
  try
    for lCount := 0 to TJSONArray(lScope.InstanceNode).Count - 1 do
    begin
      if lCovered.Contains(lCount) then
        Continue;

      lNewScope := lScope;
      lNewScope.SchemaPath        := Format('%s/additionalItems', [lNewScope.SchemaPath]);
      lNewScope.SchemaNode        := pValue;
      lNewScope.InstanceNode      := TJSONArray(lScope.InstanceNode)[lCount];
      lNewScope.InstancePath      := Format('%s/%d', [lNewScope.InstancePath, lCount]);
      lNewScope.CoveredItems      := [];
      lNewScope.ContainsCount     := 0;
      lNewScope.VisitedKeywords   := [];
      lNewScope.CoveredProperties := [];

      Visitor.PushScope(lNewScope);
      try
        lWalker := TWalker<T>.Create(pValue, Visitor);
        lWalker.Walk;
      finally
        Visitor.PopScope;
      end;

      TUtils.AddArray<Integer>(lScope.CoveredItems, lCount);
    end;
  finally
    lCovered.Free;
  end;

  Visitor.UpdateScope(lScope);
end;

procedure TBaseApplicatorVisitor<T>.VisitAdditionalProperties(const pValue: TJSONValue);
var
  lPair: TJSONPair;
  lScope: TScope;
  lWalker: IWalker;
  lCovered: TList<string>;
  lNewScope: TScope;
  lErrorCount: Integer;
begin
  lScope := Visitor.CurrentScope;

  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

  lCovered := TList<string>.Create(lScope.CoveredProperties);
  try
    for lPair in TJSONObject(lScope.InstanceNode) do
    begin
      if lCovered.Contains(lPair.JsonString.Value) then
        Continue;

      lNewScope := lScope;
      lNewScope.SchemaPath        := Format('%s/additionalProperties', [lNewScope.SchemaPath]);
      lNewScope.SchemaNode        := pValue;
      lNewScope.InstanceNode      := lPair.JsonValue;
      lNewScope.InstancePath      := Format('%s/%s', [lNewScope.InstancePath, lPair.JsonString.Value]);
      lNewScope.CoveredItems      := [];
      lNewScope.ContainsCount     := 0;
      lNewScope.VisitedKeywords   := [];
      lNewScope.CoveredProperties := [];

      Visitor.PushScope(lNewScope);
      lErrorCount := Length(Visitor.Result.Errors);
      try
        lWalker := TWalker<T>.Create(pValue, Visitor);
        lWalker.Walk;
      finally
        Visitor.PopScope;
      end;

      TUtils.AddArray<string>(lScope.CoveredProperties, lPair.JsonString.Value);
      if Length(Visitor.Result.Errors) = lErrorCount then
      begin
        if not Assigned(lScope.EvaluatedPropertiesInScope) then
          lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
        lScope.EvaluatedPropertiesInScope.Add(Format('%s/%s', [lScope.InstancePath, lPair.JsonString.Value]));
        Visitor.Result.AddEvaluatedProperty(Format('%s/%s', [lScope.InstancePath, lPair.JsonString.Value]));
      end;
    end;
  finally
    lCovered.Free;
  end;

  Visitor.UpdateScope(lScope);
end;

procedure TBaseApplicatorVisitor<T>.VisitAllOf(const pValue: TJSONArray);
var
  lCount: Integer;
  lScope: TScope;
  lWalker: IWalker;
  lNewScope: TScope;
  lVisitor: T;
  lBranchValid: Boolean;
  lEvaluatedProperty: string;
  lCombinedCoveredItems: TArray<Integer>;
  lCombinedCoveredProperties: TArray<string>;
  lCombinedEvaluatedProperties: THashSet<string>;
begin
  lScope := Visitor.CurrentScope;
  lCombinedCoveredItems := lScope.CoveredItems;
  lCombinedCoveredProperties := lScope.CoveredProperties;
  lCombinedEvaluatedProperties := THashSet<string>.Create;
  try
    if Assigned(lScope.EvaluatedPropertiesInScope) then
      for lEvaluatedProperty in lScope.EvaluatedPropertiesInScope do
        lCombinedEvaluatedProperties.Add(lEvaluatedProperty);

    for lCount := 0 to pValue.Count - 1 do
    begin
      lNewScope := lScope;
      lNewScope.SchemaPath        := Format('%s/allOf/%d', [lNewScope.SchemaPath, lCount]);
      lNewScope.SchemaNode        := pValue[lCount];
      lNewScope.CoveredItems      := [];
      lNewScope.ContainsCount     := 0;
      lNewScope.VisitedKeywords   := [];
      lNewScope.CoveredProperties := [];

      lVisitor := Visitor.New(lNewScope.SchemaNode, lNewScope.InstanceNode, lScope.BaseURI);
      ReconstructParentScopeChain(lVisitor);

      lVisitor.PushScope(lNewScope);
      lWalker := TWalker<T>.Create(lNewScope.SchemaNode, lVisitor);
      lWalker.Walk;

      lNewScope := lVisitor.PopScope;
      lBranchValid := lVisitor.Result.IsValid;

      if not lBranchValid then
      begin
        Visitor.AddError(vetAllOf, [lCount]);
        Exit;
      end;

      // Em allOf, apenas branches válidos podem promover anotações.
      if not Assigned(lNewScope.EvaluatedPropertiesInScope) then
        lNewScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

      lCombinedCoveredItems := TUtils.MergeArray<Integer>([lCombinedCoveredItems, lNewScope.CoveredItems]);
      lCombinedCoveredProperties := TUtils.MergeArray<string>([lCombinedCoveredProperties, lNewScope.CoveredProperties]);

      CollectBranchEvaluatedProperties(lVisitor, lNewScope, lScope.InstancePath, lCombinedEvaluatedProperties);
    end;

    lScope.CoveredItems := lCombinedCoveredItems;
    lScope.CoveredProperties := lCombinedCoveredProperties;
    MergeEvaluatedPropertiesIntoScope(lCombinedEvaluatedProperties, lScope);
    Visitor.UpdateScope(lScope);
  finally
    lCombinedEvaluatedProperties.Free;
  end;
end;

procedure TBaseApplicatorVisitor<T>.VisitAnyOf(const pValue: TJSONArray);
var
  lCount: Integer;
  lScope: TScope;
  lWalker: IWalker;
  lVisitor: T;
  lNewScope: TScope;
  lBranchValid: Boolean;
  lAnyBranchValid: Boolean;
  lEvaluatedProperty: string;
  lNormalizedEvaluatedProperty: string;
begin
  lScope := Visitor.CurrentScope;
  lAnyBranchValid := False;

  for lCount := 0 to pValue.Count - 1 do
  begin
    lNewScope := lScope;
    lNewScope.SchemaPath        := Format('%s/anyOf/%d', [lNewScope.SchemaPath, lCount]);
    lNewScope.SchemaNode        := pValue[lCount];
    lNewScope.CoveredItems      := [];
    lNewScope.ContainsCount     := 0;
    lNewScope.VisitedKeywords   := [];
    lNewScope.CoveredProperties := [];
    lNewScope.EvaluatedPropertiesInScope := nil;

    lVisitor := Visitor.New(lNewScope.SchemaNode, lNewScope.InstanceNode, lScope.BaseURI);
    ReconstructParentScopeChain(lVisitor);
    lVisitor.PushScope(lNewScope);
    try
      lWalker := TWalker<T>.Create(lNewScope.SchemaNode, lVisitor);
      lWalker.Walk;
    finally
      lNewScope := lVisitor.PopScope;
      lBranchValid := lVisitor.Result.IsValid;

      if lBranchValid then
      begin
        lAnyBranchValid := True;
        lScope.CoveredItems      := TUtils.MergeArray<Integer>([lScope.CoveredItems, lNewScope.CoveredItems]);
        lScope.CoveredProperties := TUtils.MergeArray<string>([lScope.CoveredProperties, lNewScope.CoveredProperties]);
        if not Assigned(lScope.EvaluatedPropertiesInScope) then
          lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

        for lEvaluatedProperty in lVisitor.Result.EvaluatedProperties do
        begin
          lNormalizedEvaluatedProperty := NormalizeEvaluatedPropertyPath(lEvaluatedProperty, lScope.InstancePath);

          lScope.EvaluatedPropertiesInScope.Add(lNormalizedEvaluatedProperty);
          Visitor.Result.AddEvaluatedProperty(lNormalizedEvaluatedProperty);
        end;
      end;
    end;

    Visitor.UpdateScope(lScope);
  end;

  if not lAnyBranchValid then
    Visitor.AddError(vetAnyOf);
end;

procedure TBaseApplicatorVisitor<T>.VisitElse(const pValue: TJSONValue);
var
  lScope: TScope;
  lWalker: IWalker;
  lNewScope: TScope;
  lErrorCount: Integer;
  lEvaluatedProperty: string;
begin
  lScope := Visitor.CurrentScope;
  if lScope.SchemaNode.FindValue('if') = nil then
    Exit;

  lNewScope := lScope;
  lNewScope.SchemaPath        := Format('%s/else', [lNewScope.SchemaPath]);
  lNewScope.SchemaNode        := pValue;
  lNewScope.CoveredItems      := [];
  lNewScope.ContainsCount     := 0;
  lNewScope.VisitedKeywords   := [];
  lNewScope.CoveredProperties := [];

  Visitor.PushScope(lNewScope);
  lErrorCount := Length(Visitor.Result.Errors);
  try
    lWalker := TWalker<T>.Create(lNewScope.SchemaNode, Visitor);
    lWalker.Walk;
  finally
    lNewScope := Visitor.PopScope;
  end;

  if Length(Visitor.Result.Errors) = lErrorCount then
  begin
    lScope.CoveredItems      := TUtils.MergeArray<Integer>([lScope.CoveredItems, lNewScope.CoveredItems]);
    lScope.CoveredProperties := TUtils.MergeArray<string>([lScope.CoveredProperties, lNewScope.CoveredProperties]);
    if Assigned(lNewScope.EvaluatedPropertiesInScope) then
    begin
      if not Assigned(lScope.EvaluatedPropertiesInScope) then
        lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

      for lEvaluatedProperty in lNewScope.EvaluatedPropertiesInScope do
      begin
        lScope.EvaluatedPropertiesInScope.Add(lEvaluatedProperty);
        Visitor.Result.AddEvaluatedProperty(lEvaluatedProperty);
      end;
    end;
  end;

  Visitor.UpdateScope(lScope);
end;

procedure TBaseApplicatorVisitor<T>.VisitIf(const pValue: TJSONValue);
var
  lScope: TScope;
  lWalker: IWalker;
  lSchema: TJSONValue;
  lVisitor: T;
  lNewScope: TScope;
  lEvaluatedProperty: string;
begin
  lScope := Visitor.CurrentScope;

  lNewScope := lScope;
  lNewScope.SchemaPath        := Format('%s/if', [lNewScope.SchemaPath]);
  lNewScope.SchemaNode        := pValue;
  lNewScope.CoveredItems      := [];
  lNewScope.ContainsCount     := 0;
  lNewScope.VisitedKeywords   := [];
  lNewScope.CoveredProperties := [];


  lVisitor := Visitor.New(lNewScope.SchemaNode, lNewScope.InstanceNode, lScope.BaseURI);
  lVisitor.PushScope(lNewScope);
  try
    lWalker := TWalker<T>.Create(lNewScope.SchemaNode, lVisitor);
    lWalker.Walk;
  finally
    lNewScope := lVisitor.PopScope;
    if lVisitor.Result.IsValid then
    begin
      lScope.CoveredItems      := TUtils.MergeArray<Integer>([lScope.CoveredItems, lNewScope.CoveredItems]);
      lScope.CoveredProperties := TUtils.MergeArray<string>([lScope.CoveredProperties, lNewScope.CoveredProperties]);
      if Assigned(lNewScope.EvaluatedPropertiesInScope) then
      begin
        if not Assigned(lScope.EvaluatedPropertiesInScope) then
          lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

        for lEvaluatedProperty in lNewScope.EvaluatedPropertiesInScope do
        begin
          lScope.EvaluatedPropertiesInScope.Add(lEvaluatedProperty);
          Visitor.Result.AddEvaluatedProperty(lEvaluatedProperty);
        end;
      end;
    end;
  end;

  Visitor.UpdateScope(lScope);

  if lVisitor.Result.IsValid and lScope.SchemaNode.TryGetValue('then', lSchema) then
    VisitThen(lSchema)
  else if (not lVisitor.Result.IsValid) and lScope.SchemaNode.TryGetValue('else', lSchema) then
    VisitElse(lSchema);

  Visitor
    .AddVisitedKeyword('then')
    .AddVisitedKeyword('else');
end;

procedure TBaseApplicatorVisitor<T>.VisitItems(const pValue: TJSONValue);
var
  lCount: Integer;
  lScope: TScope;
  lWalker: IWalker;
  lCovered: TList<Integer>;
  lNewScope: TScope;
  lInstance: TJSONArray;
  lSchema: TJSONValue;
  lMaxCount: Integer;
begin
  lScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'array' then
    Exit;

  lCovered := TList<Integer>.Create(lScope.CoveredItems);
  try
    lInstance := TJSONArray(lScope.InstanceNode);

    if TUtils.JsonGetType(pValue) = 'array' then
    begin
      lMaxCount := Min(lInstance.Count, TJSONArray(pValue).Count);
      lSchema   := nil;
    end
    else
    begin
      lMaxCount := lInstance.Count;
      lSchema   := pValue;
    end;

    for lCount := 1 to lMaxCount do
    begin
      if lCovered.Contains(lCount - 1) then
        Continue;

      if TUtils.JsonGetType(pValue) = 'array' then
        lSchema := TJSONArray(pValue)[lCount - 1];

      lNewScope := lScope;
      lNewScope.SchemaPath        := Format('%s/items/%d', [lNewScope.SchemaPath, lCount - 1]);
      lNewScope.SchemaNode        := lSchema;
      lNewScope.InstanceNode      := lInstance[lCount - 1];
      lNewScope.InstancePath      := Format('%s/%d', [lNewScope.InstancePath, lCount - 1]);
      lNewScope.CoveredItems      := [];
      lNewScope.ContainsCount     := 0;
      lNewScope.VisitedKeywords   := [];
      lNewScope.CoveredProperties := [];

      Visitor.PushScope(lNewScope);
      try
        lWalker := TWalker<T>.Create(lNewScope.SchemaNode, Visitor);
        lWalker.Walk;
      finally
        Visitor.PopScope;
      end;

      TUtils.AddArray<Integer>(lScope.CoveredItems, lCount - 1);
    end;
  finally
    lCovered.Free;
  end;

  Visitor.UpdateScope(lScope);
end;

procedure TBaseApplicatorVisitor<T>.VisitNot(const pValue: TJSONValue);
var
  lScope: TScope;
  lWalker: IWalker;
  lVisitor: T;
  lNewScope: TScope;
begin
  lScope := Visitor.CurrentScope;

  lNewScope := lScope;
  lNewScope.SchemaPath        := Format('%s/not', [lNewScope.SchemaPath]);
  lNewScope.SchemaNode        := pValue;
  lNewScope.CoveredItems      := [];
  lNewScope.ContainsCount     := 0;
  lNewScope.VisitedKeywords   := [];
  lNewScope.CoveredProperties := [];

  lVisitor := Visitor.New(lNewScope.SchemaNode, lNewScope.InstanceNode, lScope.BaseURI);
  lWalker := TWalker<T>.Create(lNewScope.SchemaNode, lVisitor);
  lWalker.Walk;

  if lVisitor.Result.IsValid then
    Visitor.AddError(vetNot);
end;

procedure TBaseApplicatorVisitor<T>.VisitOneOf(const pValue: TJSONArray);
var
  lCount: Integer;
  lScope: TScope;
  lWalker: IWalker;
  lVisitor: T;
  lMatches: Integer;
  lNewScope: TScope;
  lWinningCoveredItems: TArray<Integer>;
  lWinningCoveredProperties: TArray<string>;
  lWinningEvaluatedProperties: THashSet<string>;
  lEvaluatedProperty: string;
begin
  lScope := Visitor.CurrentScope;

  lMatches := 0;
  lWinningCoveredItems := [];
  lWinningCoveredProperties := [];
  lWinningEvaluatedProperties := THashSet<string>.Create;
  try
    for lCount := 0 to pValue.Count - 1 do
    begin
      lNewScope := lScope;
      lNewScope.SchemaPath        := Format('%s/oneOf/%d', [lNewScope.SchemaPath, lCount]);
      lNewScope.SchemaNode        := pValue[lCount];
      lNewScope.CoveredItems      := [];
      lNewScope.ContainsCount     := 0;
      lNewScope.VisitedKeywords   := [];
      lNewScope.CoveredProperties := [];
      lNewScope.EvaluatedPropertiesInScope := nil;

      lVisitor := Visitor.New(lNewScope.SchemaNode, lNewScope.InstanceNode, lScope.BaseURI);
      lVisitor.PushScope(lNewScope);
      try
        lWalker := TWalker<T>.Create(lNewScope.SchemaNode, lVisitor);
        lWalker.Walk;
      finally
        lNewScope := lVisitor.PopScope;
      end;

      if lVisitor.Result.IsValid then
      begin
        Inc(lMatches);

        if lMatches = 1 then
        begin
          lWinningCoveredItems := lNewScope.CoveredItems;
          lWinningCoveredProperties := lNewScope.CoveredProperties;
          lWinningEvaluatedProperties.Clear;

          if Assigned(lNewScope.EvaluatedPropertiesInScope) then
            for lEvaluatedProperty in lNewScope.EvaluatedPropertiesInScope do
              lWinningEvaluatedProperties.Add(lEvaluatedProperty);
        end;
      end;
    end;

    if lMatches = 0 then
      Visitor.AddError(vetOneOf_NoMatch)
    else if lMatches > 1 then
      Visitor.AddError(vetOneOf_MultipleMatches)
    else
    begin
      lScope.CoveredItems := TUtils.MergeArray<Integer>([lScope.CoveredItems, lWinningCoveredItems]);
      lScope.CoveredProperties := TUtils.MergeArray<string>([lScope.CoveredProperties, lWinningCoveredProperties]);
      if lWinningEvaluatedProperties.Count > 0 then
      begin
        if not Assigned(lScope.EvaluatedPropertiesInScope) then
          lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

        for lEvaluatedProperty in lWinningEvaluatedProperties do
        begin
          lScope.EvaluatedPropertiesInScope.Add(lEvaluatedProperty);
          Visitor.Result.AddEvaluatedProperty(lEvaluatedProperty);
        end;
      end;
      Visitor.UpdateScope(lScope);
    end;
  finally
    lWinningEvaluatedProperties.Free;
  end;
end;

procedure TBaseApplicatorVisitor<T>.VisitPatternProperties(const pValue: TJSONObject);
var
  lPair: TJSONPair;
  lRegex: string;
  lScope: TScope;
  lWalker: IWalker;
  lPropName: string;
  lNewScope: TScope;
  lPatternPair: TJSONPair;
  lErrorCount: Integer;
begin
  lScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

  for lPair in TJSONObject(lScope.InstanceNode) do
  begin
    lPropName := lPair.JsonString.Value;

    for lPatternPair in pValue do
    begin
      lRegex := TUtils.RegexNormalizePattern(lPatternPair.JsonString.Value);
      if not TRegEx.IsMatch(lPropName, lRegex, [roCompiled]) then
        Continue;

      lNewScope := lScope;
      lNewScope.SchemaPath        := Format('%s/patternProperties/{%s}', [lNewScope.SchemaPath, lRegex]);
      lNewScope.SchemaNode        := lPatternPair.JsonValue;
      lNewScope.InstanceNode      := lPair.JsonValue;
      lNewScope.InstancePath      := Format('%s/properties/%s', [lNewScope.InstancePath, lPropName]);
      lNewScope.CoveredItems      := [];
      lNewScope.ContainsCount     := 0;
      lNewScope.VisitedKeywords   := [];
      lNewScope.CoveredProperties := [];

      Visitor.PushScope(lNewScope);
      lErrorCount := Length(Visitor.Result.Errors);
      try
        lWalker := TWalker<T>.Create(lNewScope.SchemaNode, Visitor);
        lWalker.Walk;
      finally
        Visitor.PopScope;
      end;

      TUtils.AddArray<string>(lScope.CoveredProperties, lPair.JsonString.Value);
      if Length(Visitor.Result.Errors) = lErrorCount then
      begin
        if not Assigned(lScope.EvaluatedPropertiesInScope) then
          lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
        lScope.EvaluatedPropertiesInScope.Add(Format('%s/%s', [lScope.InstancePath, lPair.JsonString.Value]));
        Visitor.Result.AddEvaluatedProperty(Format('%s/%s', [lScope.InstancePath, lPair.JsonString.Value]));
      end;
    end;
  end;

  Visitor.UpdateScope(lScope);
end;

procedure TBaseApplicatorVisitor<T>.VisitPrefixItems(const pValue: TJSONArray);
var
  lScope: TScope;
  lCount: Integer;
  lWalker: IWalker;
  lNewScope: TScope;
begin
  lScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'array' then
    Exit;

  for lCount := 0 to Min(TJSONArray(lScope.InstanceNode).Count - 1, pValue.Count - 1) do
  begin
    lNewScope := lScope;
    lNewScope.SchemaPath        := Format('%s/items/%d', [lNewScope.SchemaPath, lCount]);
    lNewScope.SchemaNode        := pValue[lCount];
    lNewScope.InstanceNode      := TJSONArray(lScope.InstanceNode)[lCount];
    lNewScope.InstancePath      := Format('%s/%d', [lNewScope.InstancePath, lCount]);
    lNewScope.CoveredItems      := [];
    lNewScope.ContainsCount     := 0;
    lNewScope.VisitedKeywords   := [];
    lNewScope.CoveredProperties := [];

    Visitor.PushScope(lNewScope);
    try
      lWalker := TWalker<T>.Create(lNewScope.SchemaNode, Visitor);
      lWalker.Walk;
    finally
      Visitor.PopScope;
    end;

    TUtils.AddArray<Integer>(lScope.CoveredItems, lCount);
  end;

  Visitor.UpdateScope(lScope);
end;

procedure TBaseApplicatorVisitor<T>.VisitProperties(const pValue: TJSONObject);
var
  lPair: TJSONPair;
  lScope: TScope;
  lWalker: IWalker;
  lNewScope: TScope;
  lSubInstance: TJSONValue;
  lErrorCount: Integer;
begin
  lScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

  for lPair in pValue do
  begin
    if not TJSONObject(lScope.InstanceNode).TryGetValue(lPair.JsonString.Value, lSubInstance) then
      Continue;

    lNewScope := lScope;
    lNewScope.SchemaPath        := Format('%s/properties/%s', [lNewScope.SchemaPath, lPair.JsonString.Value]);
    lNewScope.SchemaNode        := lPair.JsonValue;
    lNewScope.InstanceNode      := lSubInstance;
    lNewScope.InstancePath      := Format('%s.%s', [lNewScope.InstancePath, lPair.JsonString.Value]);
    lNewScope.CoveredItems      := [];
    lNewScope.ContainsCount     := 0;
    lNewScope.VisitedKeywords   := [];
    lNewScope.CoveredProperties := [];

    Visitor.PushScope(lNewScope);
    lErrorCount := Length(Visitor.Result.Errors);
    try
      lWalker := TWalker<T>.Create(lNewScope.SchemaNode, Visitor);
      lWalker.Walk;
    finally
      Visitor.PopScope;
    end;

    TUtils.AddArray<string>(lScope.CoveredProperties, lPair.JsonString.Value);
    if Length(Visitor.Result.Errors) = lErrorCount then
    begin
      if not Assigned(lScope.EvaluatedPropertiesInScope) then
        lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
      lScope.EvaluatedPropertiesInScope.Add(Format('%s/%s', [lScope.InstancePath, lPair.JsonString.Value]));
      Visitor.Result.AddEvaluatedProperty(Format('%s/%s', [lScope.InstancePath, lPair.JsonString.Value]));
    end;
    Visitor.UpdateScope(lScope);
  end;
end;

procedure TBaseApplicatorVisitor<T>.VisitThen(const pValue: TJSONValue);
var
  lScope: TScope;
  lWalker: IWalker;
  lNewScope: TScope;
  lErrorCount: Integer;
  lEvaluatedProperty: string;
begin
  lScope := Visitor.CurrentScope;
  if lScope.SchemaNode.FindValue('if') = nil then
    Exit;

  lNewScope := lScope;
  lNewScope.SchemaPath        := Format('%s/then', [lNewScope.SchemaPath]);
  lNewScope.SchemaNode        := pValue;
  lNewScope.CoveredItems      := [];
  lNewScope.ContainsCount     := 0;
  lNewScope.VisitedKeywords   := [];
  lNewScope.CoveredProperties := [];

  Visitor.PushScope(lNewScope);
  lErrorCount := Length(Visitor.Result.Errors);
  try
    lWalker := TWalker<T>.Create(lNewScope.SchemaNode, Visitor);
    lWalker.Walk;
  finally
    lNewScope := Visitor.PopScope;
  end;

  if Length(Visitor.Result.Errors) = lErrorCount then
  begin
    lScope.CoveredItems      := TUtils.MergeArray<Integer>([lScope.CoveredItems, lNewScope.CoveredItems]);
    lScope.CoveredProperties := TUtils.MergeArray<string>([lScope.CoveredProperties, lNewScope.CoveredProperties]);
    if Assigned(lNewScope.EvaluatedPropertiesInScope) then
    begin
      if not Assigned(lScope.EvaluatedPropertiesInScope) then
        lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

      for lEvaluatedProperty in lNewScope.EvaluatedPropertiesInScope do
      begin
        lScope.EvaluatedPropertiesInScope.Add(lEvaluatedProperty);
        Visitor.Result.AddEvaluatedProperty(lEvaluatedProperty);
      end;
    end;
  end;

  Visitor.UpdateScope(lScope);
end;

end.
