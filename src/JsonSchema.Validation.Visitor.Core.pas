unit JsonSchema.Validation.Visitor.Core;

interface

uses
  System.JSON,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Types,
  JsonSchema.Validation.Interfaces,
  JsonSchema.Registry.Base;

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
  JsonSchema.Walker,
  JsonSchema.Walker.Types,
  JsonSchema.Registry.Uri,
  JsonSchema.Registry.Resource;

{ TBaseCoreVisitor<T> }

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

procedure TBaseCoreVisitor<T>.VisitRef(const pValue: TJSONString);
var
  lScope: TScope;
  lRefString: string;
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
  lTargetRootSchema: TJSONValue;
  lTargetDraftSchema: string;
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
  lPrecedenceKey: string;
  lCurrentHandlesNewDrafts: Boolean;
  lCurrentDraftVersion: TDraftVersion;
  lResultEvaluatedBefore: THashSet<string>;
begin
  if not Supports(Visitor, IValidationVisitor<T>, lValidationVisitor) then
    Exit; // Sanity check

  lScope := Visitor.CurrentScope;
  lRefString := pValue.Value;

  // 1. Resolve a URI da referência
  lFinalURI := TURIReference.From(lRefString).ResolveWith(TURIReference.From(lScope.BaseURI));
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
    // 2. Busca o recurso de schema no Registry
    if not lValidationVisitor.Registry.TryFindResource(lFinalURI.Unsplit, lTargetResource) then
    begin
      Visitor.AddError(TErrorType.vetUnresolvedReference, [lFinalURI.Unsplit]);
      Exit;
    end;

    // 3. Resolve o fragmento (#/... ou #anchor) dentro do recurso
    lTargetSchema := lTargetResource.ResolveFragment(lFinalURI.Fragment, lResolvedBaseURI);

    if not Assigned(lTargetSchema) then
    begin
      Visitor.AddError(TErrorType.vetUnresolvedReference, [lFinalURI.Unsplit]);
      Exit;
    end;

    // 3.1 Se o recurso apontar para outro draft, valida com o visitor correto.
    lTargetDraftVersion := TDraftVersion.dvUnknown;
    lTargetRootSchema := lTargetResource.ResolveFragment('');

    if (lTargetRootSchema is TJSONObject) and TJSONObject(lTargetRootSchema).TryGetValue<string>('$schema', lTargetDraftSchema) then
      lTargetDraftVersion := TDraftVersion.FromSchema(lTargetDraftSchema);

    if (lTargetDraftVersion = TDraftVersion.dvUnknown) then
    begin
      if ContainsText(lFinalURI.Unsplit, '/draft2019-09/') then
        lTargetDraftVersion := TDraftVersion.dvDraft2019_09
      else if ContainsText(lFinalURI.Unsplit, '/draft2020-12/') then
        lTargetDraftVersion := TDraftVersion.dvDraft2020_12;
    end;

    // Verifica se o visitor atual já suporta nativamente os drafts 2019-09/2020-12.
    // Se sim, não usar o caminho cross-draft para refs do mesmo draft (preserva o dynamic scope chain).
    lCurrentHandlesNewDrafts := False;
    lCurrentDraftVersion := TDraftVersion.dvUnknown;
    for lPrecedenceKey in Visitor.KeywordPrecedence do
      if lPrecedenceKey = '$dynamicRef' then
      begin
        lCurrentHandlesNewDrafts := True;
        lCurrentDraftVersion := TDraftVersion.dvDraft2020_12;
        Break;
      end
      else if lPrecedenceKey = '$recursiveRef' then
      begin
        lCurrentHandlesNewDrafts := True;
        lCurrentDraftVersion := TDraftVersion.dvDraft2019_09;
        Break;
      end;

    if ((lTargetDraftVersion = TDraftVersion.dvDraft7) and lCurrentHandlesNewDrafts) or
       ((lTargetDraftVersion in [TDraftVersion.dvDraft2019_09, TDraftVersion.dvDraft2020_12]) and
        ((not lCurrentHandlesNewDrafts) or (lCurrentDraftVersion <> lTargetDraftVersion))) then
    begin
      lCrossDraftResult := TJsonSchema.Validate(lTargetSchema, lScope.InstanceNode, lTargetDraftVersion);

      if not Assigned(lScope.EvaluatedPropertiesInScope) then
        lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
      for lEvaluatedProperty in lCrossDraftResult.EvaluatedProperties do
      begin
        lNormalizedEvaluatedProperty := lEvaluatedProperty;
        if not lNormalizedEvaluatedProperty.IsEmpty then
        begin
          if (lScope.InstancePath <> '#') and not lNormalizedEvaluatedProperty.StartsWith(lScope.InstancePath + '/') then
          begin
            if lNormalizedEvaluatedProperty = '#' then
              lNormalizedEvaluatedProperty := lScope.InstancePath
            else if lNormalizedEvaluatedProperty.StartsWith('#/') then
              lNormalizedEvaluatedProperty := lNormalizedEvaluatedProperty.Substring(1)
            else if lNormalizedEvaluatedProperty.StartsWith('#.') then
              lNormalizedEvaluatedProperty := lScope.InstancePath + '/' +
                StringReplace(lNormalizedEvaluatedProperty.Substring(2), '.', '/', [rfReplaceAll])
            else if lNormalizedEvaluatedProperty.StartsWith('/') then
            begin
              // Caminhos iniciados por '/' já são absolutos no documento.
            end
            else if lNormalizedEvaluatedProperty.StartsWith('.') then
              lNormalizedEvaluatedProperty := lScope.InstancePath + '/' +
                StringReplace(lNormalizedEvaluatedProperty.Substring(1), '.', '/', [rfReplaceAll])
            else
              lNormalizedEvaluatedProperty := lScope.InstancePath + '/' + lNormalizedEvaluatedProperty;
          end;
        end;

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

    // 4. Prepara e executa a validação recursiva
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

          lNormalizedEvaluatedProperty := lEvaluatedProperty;
          if not lNormalizedEvaluatedProperty.IsEmpty then
          begin
            if (lScope.InstancePath <> '#') and not lNormalizedEvaluatedProperty.StartsWith(lScope.InstancePath + '/') then
            begin
              if lNormalizedEvaluatedProperty = '#' then
                lNormalizedEvaluatedProperty := lScope.InstancePath
              else if lNormalizedEvaluatedProperty.StartsWith('#/') then
                lNormalizedEvaluatedProperty := lNormalizedEvaluatedProperty.Substring(1)
              else if lNormalizedEvaluatedProperty.StartsWith('#.') then
                lNormalizedEvaluatedProperty := lScope.InstancePath + '/' +
                  StringReplace(lNormalizedEvaluatedProperty.Substring(2), '.', '/', [rfReplaceAll])
              else if lNormalizedEvaluatedProperty.StartsWith('/') then
              begin
                // Caminhos iniciados por '/' já são absolutos no documento.
              end
              else if lNormalizedEvaluatedProperty.StartsWith('.') then
                lNormalizedEvaluatedProperty := lScope.InstancePath + '/' +
                  StringReplace(lNormalizedEvaluatedProperty.Substring(1), '.', '/', [rfReplaceAll])
              else
                lNormalizedEvaluatedProperty := lScope.InstancePath + '/' + lNormalizedEvaluatedProperty;
            end;
          end;

          lNewScope.EvaluatedPropertiesInScope.Add(lNormalizedEvaluatedProperty);
        end;
        Visitor.UpdateScope(lNewScope);
      finally
        lNewScope := Visitor.PopScope;
      end;

      lScope.CoveredItems      := TUtils.MergeArray<Integer>([lScope.CoveredItems, lNewScope.CoveredItems]);
      lScope.CoveredProperties := TUtils.MergeArray<string>([lScope.CoveredProperties, lNewScope.CoveredProperties]);
      if Assigned(lNewScope.EvaluatedPropertiesInScope) then
      begin
        if not Assigned(lScope.EvaluatedPropertiesInScope) then
          lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

        for lEvaluatedProperty in lNewScope.EvaluatedPropertiesInScope do
        begin
          lNormalizedEvaluatedProperty := lEvaluatedProperty;
          if not lNormalizedEvaluatedProperty.IsEmpty then
          begin
            if (lScope.InstancePath <> '#') and not lNormalizedEvaluatedProperty.StartsWith(lScope.InstancePath + '/') then
            begin
              if lNormalizedEvaluatedProperty = '#' then
                lNormalizedEvaluatedProperty := lScope.InstancePath
              else if lNormalizedEvaluatedProperty.StartsWith('#/') then
                lNormalizedEvaluatedProperty := lNormalizedEvaluatedProperty.Substring(1)
              else if lNormalizedEvaluatedProperty.StartsWith('#.') then
                lNormalizedEvaluatedProperty := lScope.InstancePath + '/' +
                  StringReplace(lNormalizedEvaluatedProperty.Substring(2), '.', '/', [rfReplaceAll])
              else if lNormalizedEvaluatedProperty.StartsWith('/') then
              begin
                // Caminhos iniciados por '/' já são absolutos no documento.
              end
              else if lNormalizedEvaluatedProperty.StartsWith('.') then
                lNormalizedEvaluatedProperty := lScope.InstancePath + '/' +
                  StringReplace(lNormalizedEvaluatedProperty.Substring(1), '.', '/', [rfReplaceAll])
              else
                lNormalizedEvaluatedProperty := lScope.InstancePath + '/' + lNormalizedEvaluatedProperty;
            end;
          end;

          lScope.EvaluatedPropertiesInScope.Add(lNormalizedEvaluatedProperty);
          lValidationVisitor.Result.AddEvaluatedProperty(lNormalizedEvaluatedProperty);

          // Em refs no mesmo draft, reconstrói cobertura local para unevaluated* no escopo pai.
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
              TUtils.AddArray<Integer>(lScope.CoveredItems, lItemIndex)
            else if lFirstSegment <> '' then
              TUtils.AddArray<string>(lScope.CoveredProperties, lFirstSegment);
          end;
        end;
      end;

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
