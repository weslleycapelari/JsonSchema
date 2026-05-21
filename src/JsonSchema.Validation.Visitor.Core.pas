unit JsonSchema.Validation.Visitor.Core;

interface

uses
  System.JSON,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Types,
  JsonSchema.Validation.Interfaces,
  JsonSchema.Registry.Base,
  JsonSchema.Registry.Uri,
  JsonSchema.Registry.Resource,
  JsonSchema.Walker.Types;

type
  /// <summary>
  ///   Base visitor that handles the JSON Schema Core vocabulary keywords:
  ///   $schema, $id, $ref, definitions, and boolean schemas.
  /// </summary>
  TBaseCoreVisitor<T: IValidationVisitor<T>> = class(TBase<T>, IBaseCoreVisitor<T>)
    [VisitorKeyword('$schema')]
    procedure VisitSchema(const pValue: TJSONString);
    [VisitorKeyword('id')]
    [VisitorKeyword('$id')]
    procedure VisitId(const pValue: TJSONString);
    [VisitorKeyword('$ref')]
    procedure VisitRef(const pValue: TJSONString);
    [VisitorKeyword('definitions')]
    [VisitorKeyword('$defs')]
    procedure VisitDefinitions(const pValue: TJSONObject);
    procedure VisitBooleanSchema(const pValue: TJSONBool);
  strict private
    function ResolveRefTarget(const pRefString, pBaseURI: string; out pFinalURI: TURIReference; out pResource: TResource;
      out pTargetSchema: TJSONValue; out pResolvedBaseURI: string): Boolean;
    function DetectTargetDraftVersion(const pFinalURI: TURIReference; const pTargetResource: TResource; out pTargetDraftVersion: TDraftVersion;
      out pCurrentHandlesNewDrafts: Boolean; out pCurrentDraftVersion: TDraftVersion): Boolean;
    procedure MergeRefEvaluatedProperties(const pNewScope: TScope; var pScope: TScope; const pValidationVisitor: IValidationVisitor<T>);
    function NormalizeEvaluatedPropertyPath(const pProp, pInstancePath: string): string;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  System.Generics.Collections,
  JsonSchema.Translate.Types,
  JsonSchema.Validation.Types,
  JsonSchema.Common.Utils,
  JsonSchema,
  JsonSchema.Walker;

{ TBaseCoreVisitor<T> }

function TBaseCoreVisitor<T>.NormalizeEvaluatedPropertyPath(const pProp, pInstancePath: string): string;
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
    else if Result.StartsWith('#.') then
      Result := pInstancePath + '/' +
        StringReplace(Result.Substring(2), '.', '/', [rfReplaceAll])
    else if Result.StartsWith('/') then
    begin
      // Paths starting with '/' are already absolute in the document.
    end
    else if Result.StartsWith('.') then
      Result := pInstancePath + '/' +
        StringReplace(Result.Substring(1), '.', '/', [rfReplaceAll])
    else
      Result := pInstancePath + '/' + Result;
  end;
end;

procedure TBaseCoreVisitor<T>.VisitBooleanSchema(const pValue: TJSONBool);
begin
  if not pValue.AsBoolean then
    Visitor.AddError(TErrorType.vetSchemaIsFalse);
end;

procedure TBaseCoreVisitor<T>.VisitDefinitions(const pValue: TJSONObject);
begin

end;

procedure TBaseCoreVisitor<T>.VisitId(const pValue: TJSONString);
var
  lScope: TScope;
  lResolvedURI: TURIReference;
begin
  lScope := Visitor.CurrentScope;
  lResolvedURI := TURIReference.From(pValue.Value).ResolveWith(TURIReference.From(lScope.BaseURI));
  lScope.BaseURI := lResolvedURI.Unsplit;

  Visitor.UpdateScope(lScope);
end;

function TBaseCoreVisitor<T>.ResolveRefTarget(
  const pRefString, pBaseURI: string;
  out pFinalURI: TURIReference;
  out pResource: TResource;
  out pTargetSchema: TJSONValue;
  out pResolvedBaseURI: string): Boolean;
var
  lValidationVisitor: IValidationVisitor<T>;
begin
  Result := False;
  pFinalURI := TURIReference.From(pRefString).ResolveWith(TURIReference.From(pBaseURI));

  if not Supports(Visitor, IValidationVisitor<T>, lValidationVisitor) then
    Exit;

  if not lValidationVisitor.Registry.TryFindResource(pFinalURI.Unsplit, pResource) then
  begin
    Visitor.AddError(TErrorType.vetUnresolvedReference, [pFinalURI.Unsplit]);
    Exit;
  end;

  pTargetSchema := pResource.ResolveFragment(pFinalURI.Fragment, pResolvedBaseURI);
  if not Assigned(pTargetSchema) then
  begin
    Visitor.AddError(TErrorType.vetUnresolvedReference, [pFinalURI.Unsplit]);
    Exit;
  end;

  Result := True;
end;

function TBaseCoreVisitor<T>.DetectTargetDraftVersion(
  const pFinalURI: TURIReference;
  const pTargetResource: TResource;
  out pTargetDraftVersion: TDraftVersion;
  out pCurrentHandlesNewDrafts: Boolean;
  out pCurrentDraftVersion: TDraftVersion): Boolean;
var
  lTargetRootSchema: TJSONValue;
  lTargetDraftSchema: string;
  lPrecedenceKey: string;
begin
  pTargetDraftVersion := TDraftVersion.dvUnknown;
  lTargetRootSchema := pTargetResource.ResolveFragment('');

  if (lTargetRootSchema is TJSONObject) and
     TJSONObject(lTargetRootSchema).TryGetValue<string>('$schema', lTargetDraftSchema) then
    pTargetDraftVersion := TDraftVersion.FromSchema(lTargetDraftSchema);

  if pTargetDraftVersion = TDraftVersion.dvUnknown then
  begin
    if ContainsText(pFinalURI.Unsplit, '/draft2019-09/') then
      pTargetDraftVersion := TDraftVersion.dvDraft2019_09
    else if ContainsText(pFinalURI.Unsplit, '/draft2020-12/') then
      pTargetDraftVersion := TDraftVersion.dvDraft2020_12;
  end;

  pCurrentHandlesNewDrafts := False;
  pCurrentDraftVersion := TDraftVersion.dvUnknown;
  for lPrecedenceKey in Visitor.KeywordPrecedence do
    if lPrecedenceKey = '$dynamicRef' then
    begin
      pCurrentHandlesNewDrafts := True;
      pCurrentDraftVersion := TDraftVersion.dvDraft2020_12;
      Break;
    end
    else if lPrecedenceKey = '$recursiveRef' then
    begin
      pCurrentHandlesNewDrafts := True;
      pCurrentDraftVersion := TDraftVersion.dvDraft2019_09;
      Break;
    end;

  Result := True;
end;

procedure TBaseCoreVisitor<T>.MergeRefEvaluatedProperties(
  const pNewScope: TScope;
  var pScope: TScope;
  const pValidationVisitor: IValidationVisitor<T>);
var
  lEvaluatedProperty: string;
  lNormalizedEvaluatedProperty: string;
  lRelativePath: string;
  lSegmentSeparator: Integer;
  lFirstSegment: string;
  lItemIndex: Integer;
begin
  pScope.CoveredItems      := TUtils.MergeArray<Integer>([pScope.CoveredItems, pNewScope.CoveredItems]);
  pScope.CoveredProperties := TUtils.MergeArray<string>([pScope.CoveredProperties, pNewScope.CoveredProperties]);
  if not Assigned(pNewScope.EvaluatedPropertiesInScope) then
    Exit;

  if not Assigned(pScope.EvaluatedPropertiesInScope) then
    pScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

  for lEvaluatedProperty in pNewScope.EvaluatedPropertiesInScope do
  begin
    lNormalizedEvaluatedProperty := NormalizeEvaluatedPropertyPath(lEvaluatedProperty, pScope.InstancePath);

    pScope.EvaluatedPropertiesInScope.Add(lNormalizedEvaluatedProperty);
    pValidationVisitor.Result.AddEvaluatedProperty(lNormalizedEvaluatedProperty);

    if ((pScope.InstancePath = '#') and lNormalizedEvaluatedProperty.StartsWith('/')) or
       ((pScope.InstancePath <> '#') and lNormalizedEvaluatedProperty.StartsWith(pScope.InstancePath + '/')) then
    begin
      if pScope.InstancePath = '#' then
        lRelativePath := lNormalizedEvaluatedProperty.Substring(1)
      else
        lRelativePath := lNormalizedEvaluatedProperty.Substring((pScope.InstancePath + '/').Length);
      lSegmentSeparator := Pos('/', lRelativePath);
      if lSegmentSeparator > 0 then
        lFirstSegment := Copy(lRelativePath, 1, lSegmentSeparator - 1)
      else
        lFirstSegment := lRelativePath;

      if TryStrToInt(lFirstSegment, lItemIndex) then
        TUtils.AddArray<Integer>(pScope.CoveredItems, lItemIndex)
      else if lFirstSegment <> '' then
        TUtils.AddArray<string>(pScope.CoveredProperties, lFirstSegment);
    end;
  end;
end;

procedure TBaseCoreVisitor<T>.VisitRef(const pValue: TJSONString);
var
  lScope: TScope;
  lFinalURI: TURIReference;
  lTargetResource: TResource;
  lTargetSchema: TJSONValue;
  lWalker: IWalker;
  lNewScope: TScope;
  lValidationVisitor: IValidationVisitor<T>;
  lResolvedBaseURI: string;
  lRefGuard: IRefResolutionGuard;
  lGuardReason: string;
  lGuardKey: string;
  lGuardEntered: Boolean;
  lTargetDraftVersion: TDraftVersion;
  lCrossDraftResult: IValidationResult;
  lCrossDraftError: IError;
  lDependentRequired: TJSONValue;
  lDependencyPair: TJSONPair;
  lRequiredArray: TJSONArray;
  lRequiredValue: TJSONValue;
  lInstanceObject: TJSONObject;
  lEvaluatedProperty: string;
  lNormalizedEvaluatedProperty: string;
  lRelativePath: string;
  lSegmentSeparator: Integer;
  lFirstSegment: string;
  lItemIndex: Integer;
  lCurrentHandlesNewDrafts: Boolean;
  lCurrentDraftVersion: TDraftVersion;
  lResultEvaluatedBefore: THashSet<string>;
begin
  if not Supports(Visitor, IValidationVisitor<T>, lValidationVisitor) then
    Exit; // Sanity check

  lScope := Visitor.CurrentScope;

  if not ResolveRefTarget(pValue.Value, lScope.BaseURI, lFinalURI, lTargetResource, lTargetSchema, lResolvedBaseURI) then
    Exit;

  lGuardKey := lFinalURI.Unsplit + '|' + lScope.InstancePath;
  lGuardEntered := False;

  if Supports(Visitor, IRefResolutionGuard, lRefGuard) then
  begin
    if not lRefGuard.TryEnterRefResolution(lGuardKey, lGuardReason) then
    begin
      Visitor.AddError(TErrorType.vetUnresolvedReference, [lGuardReason]);
      Exit;
    end;
    lGuardEntered := True;
  end;

  try
    DetectTargetDraftVersion(lFinalURI, lTargetResource, lTargetDraftVersion, lCurrentHandlesNewDrafts, lCurrentDraftVersion);

    if ((lTargetDraftVersion = TDraftVersion.dvDraft7) and lCurrentHandlesNewDrafts) or
       ((lTargetDraftVersion in [TDraftVersion.dvDraft2019_09, TDraftVersion.dvDraft2020_12]) and
        ((not lCurrentHandlesNewDrafts) or (lCurrentDraftVersion <> lTargetDraftVersion))) then
    begin
      lCrossDraftResult := TJsonSchema.Validate(lTargetSchema, lScope.InstanceNode, lTargetDraftVersion);

      if not Assigned(lScope.EvaluatedPropertiesInScope) then
        lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
      for lEvaluatedProperty in lCrossDraftResult.EvaluatedProperties do
      begin
        lNormalizedEvaluatedProperty := NormalizeEvaluatedPropertyPath(lEvaluatedProperty, lScope.InstancePath);

        lScope.EvaluatedPropertiesInScope.Add(lNormalizedEvaluatedProperty);
        lValidationVisitor.Result.AddEvaluatedProperty(lNormalizedEvaluatedProperty);

        // Em modo cross-draft, reconstrói cobertura local para unevaluated* do visitor pai.
        if ((lScope.InstancePath = '#') and lNormalizedEvaluatedProperty.StartsWith('/')) or
           ((lScope.InstancePath <> '#') and lNormalizedEvaluatedProperty.StartsWith(lScope.InstancePath + '/')) then
        begin
          if lScope.InstancePath = '#' then
            lRelativePath := lNormalizedEvaluatedProperty.Substring(1)
          else
            lRelativePath := lNormalizedEvaluatedProperty.Substring((lScope.InstancePath + '/').Length);
          lSegmentSeparator := Pos('/', lRelativePath);
          if lSegmentSeparator > 0 then
            lFirstSegment := Copy(lRelativePath, 1, lSegmentSeparator - 1)
          else
            lFirstSegment := lRelativePath;

          if TryStrToInt(lFirstSegment, lItemIndex) then
          begin
            TUtils.AddArray<Integer>(lScope.CoveredItems, lItemIndex);
          end
          else if lFirstSegment <> '' then
          begin
            TUtils.AddArray<string>(lScope.CoveredProperties, lFirstSegment);
          end;
        end;
      end;
      Visitor.UpdateScope(lScope);

      if not lCrossDraftResult.IsValid then
        for lCrossDraftError in lCrossDraftResult.Errors do
          lValidationVisitor.Result.AddError(lCrossDraftError);

      // Fallback minimo: dependentRequired em refs cross-draft para drafts que
      // suportam explicitamente o keyword.
      if lCrossDraftResult.IsValid and (lTargetDraftVersion in [TDraftVersion.dvDraft2019_09, TDraftVersion.dvDraft2020_12]) and
        (lTargetSchema is TJSONObject) and
         TJSONObject(lTargetSchema).TryGetValue('dependentRequired', lDependentRequired) and
         (lDependentRequired is TJSONObject) and (lScope.InstanceNode is TJSONObject) then
      begin
        lInstanceObject := TJSONObject(lScope.InstanceNode);
        for lDependencyPair in TJSONObject(lDependentRequired) do
        begin
          if lInstanceObject.FindValue(lDependencyPair.JsonString.Value) = nil then
            Continue;

          if not (lDependencyPair.JsonValue is TJSONArray) then
            Continue;

          lRequiredArray := TJSONArray(lDependencyPair.JsonValue);
          for lRequiredValue in lRequiredArray do
          begin
            if not (lRequiredValue is TJSONString) then
              Continue;

            if lInstanceObject.FindValue(TJSONString(lRequiredValue).Value) = nil then
              lValidationVisitor.AddError(TErrorType.vetDependentRequired,
                [lDependencyPair.JsonString.Value, TJSONString(lRequiredValue).Value]);
          end;
        end;
      end;

      Exit;
    end;

    // Prepara e executa a validação recursiva no mesmo draft
    lNewScope := lScope;
    lNewScope.BaseURI      := lResolvedBaseURI;
    lNewScope.SchemaNode   := lTargetSchema;
    lNewScope.SchemaPath   := lFinalURI.Unsplit;
    lNewScope.CoveredItems      := [];
    lNewScope.ContainsCount     := 0;
    lNewScope.VisitedKeywords   := [];
    lNewScope.CoveredProperties := [];
    lNewScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
    if Assigned(lScope.EvaluatedPropertiesInScope) then
      for lEvaluatedProperty in lScope.EvaluatedPropertiesInScope do
        lNewScope.EvaluatedPropertiesInScope.Add(lEvaluatedProperty);

    lResultEvaluatedBefore := THashSet<string>.Create;
    try
      for lEvaluatedProperty in lValidationVisitor.Result.EvaluatedProperties do
        lResultEvaluatedBefore.Add(lEvaluatedProperty);

      Visitor.PushScope(lNewScope);
      try
        lWalker := TWalker<T>.Create(lTargetSchema, Visitor);
        lWalker.Walk;

        // Sincroniza imediatamente as anotações novas no escopo local do $ref
        // antes do pop, para manter coerência intra-subvalidação.
        lNewScope := Visitor.CurrentScope;
        if not Assigned(lNewScope.EvaluatedPropertiesInScope) then
          lNewScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

        for lEvaluatedProperty in lValidationVisitor.Result.EvaluatedProperties do
        begin
          if lResultEvaluatedBefore.Contains(lEvaluatedProperty) then
            Continue;

          lNormalizedEvaluatedProperty := NormalizeEvaluatedPropertyPath(lEvaluatedProperty, lScope.InstancePath);

          lNewScope.EvaluatedPropertiesInScope.Add(lNormalizedEvaluatedProperty);
        end;
        Visitor.UpdateScope(lNewScope);
      finally
        lNewScope := Visitor.PopScope;
      end;

      MergeRefEvaluatedProperties(lNewScope, lScope, lValidationVisitor);
      Visitor.UpdateScope(lScope);
    finally
      lResultEvaluatedBefore.Free;
    end;
  finally
    if lGuardEntered then
      lRefGuard.LeaveRefResolution(lGuardKey);
  end;
end;

procedure TBaseCoreVisitor<T>.VisitSchema(const pValue: TJSONString);
begin

end;

end.
