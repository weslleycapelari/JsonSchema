unit JsonSchema.Visitor.Core.Base;

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
  JsonSchema.Common.Utils,
  JsonSchema.Walker.Types;

type
  /// <summary>
  ///   Base visitor that handles the JSON Schema Core vocabulary keywords:
  ///   $schema, $id, id, $ref, definitions/$defs, and boolean schemas.
  ///   This class is meant to be inherited by draft‑specific core visitors.
  /// </summary>
  TBaseCoreVisitor<T: IVisitor<T>> = class(TBase<T>, IBaseCoreVisitor<T>)
  protected
    /// <summary>Resolves a $ref target and returns the schema node and base URI.</summary>
    function ResolveRefTarget(const pRefString, pBaseURI: string;
      out pFinalURI: TURIReference; out pResource: TResource;
      out pTargetSchema: TJSONValue; out pResolvedBaseURI: string): Boolean;

    /// <summary>Merges evaluated properties from a $ref sub‑validation into the current scope.</summary>
    procedure MergeRefEvaluatedProperties(const pNewScope: TScope; var pScope: TScope);

    /// <summary>Normalises an evaluated property path relative to the current instance path.</summary>
    function NormaliseEvaluatedPath(const pProp, pInstancePath: string): string;
  public
    [VisitorKeyword('$schema')]
    procedure VisitSchema(const pValue: TJSONString); virtual;

    [VisitorKeyword('id')]
    [VisitorKeyword('$id')]
    procedure VisitId(const pValue: TJSONString); virtual;

    [VisitorKeyword('$ref')]
    procedure VisitRef(const pValue: TJSONString); virtual;

    [VisitorKeyword('definitions')]
    [VisitorKeyword('$defs')]
    procedure VisitDefinitions(const pValue: TJSONObject); virtual;

    procedure VisitBooleanSchema(const pValue: TJSONBool); virtual;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  System.Generics.Collections,
  JsonSchema.Translate.Types,
  JsonSchema,
  JsonSchema.Walker;

{ TBaseCoreVisitor<T> }

function TBaseCoreVisitor<T>.NormaliseEvaluatedPath(const pProp, pInstancePath: string): string;
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
      Result := pInstancePath + '/' + StringReplace(Result.Substring(2), '.', '/', [rfReplaceAll])
    else if Result.StartsWith('/') then
      // Already absolute in the document – keep as is
    else if Result.StartsWith('.') then
      Result := pInstancePath + '/' + StringReplace(Result.Substring(1), '.', '/', [rfReplaceAll])
    else
      Result := pInstancePath + '/' + Result;
  end;
end;

function TBaseCoreVisitor<T>.ResolveRefTarget(const pRefString, pBaseURI: string;
  out pFinalURI: TURIReference; out pResource: TResource;
  out pTargetSchema: TJSONValue; out pResolvedBaseURI: string): Boolean;
var
  lValidationVisitor: IValidationVisitor<T>;
begin
  Result := False;
  pFinalURI := TURIReference.From(pRefString).ResolveWith(TURIReference.From(pBaseURI));

  if not Supports(Visitor, IValidationVisitor<T>, lValidationVisitor) then
    Exit;

  if not lValidationVisitor.Registry.TryFindResource(pFinalURI.Unsplit, pResource) then
  begin
    lValidationVisitor.AddError(TErrorType.vetUnresolvedReference, [pFinalURI.Unsplit]);
    Exit;
  end;

  pTargetSchema := pResource.ResolveFragment(pFinalURI.Fragment, pResolvedBaseURI);
  if not Assigned(pTargetSchema) then
  begin
    lValidationVisitor.AddError(TErrorType.vetUnresolvedReference, [pFinalURI.Unsplit]);
    Exit;
  end;

  Result := True;
end;

procedure TBaseCoreVisitor<T>.MergeRefEvaluatedProperties(const pNewScope: TScope; var pScope: TScope);
var
  lEvaluatedProperty: string;
  lNormalised: string;
  lRelativePath: string;
  lSegmentSeparator: Integer;
  lFirstSegment: string;
  lItemIndex: Integer;
  lValidationVisitor: IValidationVisitor<T>;
begin
  if not Supports(Visitor, IValidationVisitor<T>, lValidationVisitor) then
    Exit;

  pScope.CoveredItems := TUtils.MergeArray<Integer>([pScope.CoveredItems, pNewScope.CoveredItems]);
  pScope.CoveredProperties := TUtils.MergeArray<string>([pScope.CoveredProperties, pNewScope.CoveredProperties]);

  if not Assigned(pNewScope.EvaluatedPropertiesInScope) then
    Exit;

  if not Assigned(pScope.EvaluatedPropertiesInScope) then
    pScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

  for lEvaluatedProperty in pNewScope.EvaluatedPropertiesInScope do
  begin
    lNormalised := NormaliseEvaluatedPath(lEvaluatedProperty, pScope.InstancePath);
    pScope.EvaluatedPropertiesInScope.Add(lNormalised);
    lValidationVisitor.Result.AddEvaluatedProperty(lNormalised);

    // Derive covered items/properties from the evaluated path
    if ((pScope.InstancePath = '#') and lNormalised.StartsWith('/')) or
       ((pScope.InstancePath <> '#') and lNormalised.StartsWith(pScope.InstancePath + '/')) then
    begin
      if pScope.InstancePath = '#' then
        lRelativePath := lNormalised.Substring(1)
      else
        lRelativePath := lNormalised.Substring((pScope.InstancePath + '/').Length);

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

procedure TBaseCoreVisitor<T>.VisitSchema(const pValue: TJSONString);
begin
  // Default: no operation – draft‑specific visitors may override
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
  lFinalURI: TURIReference;
  lTargetResource: TResource;
  lTargetSchema: TJSONValue;
  lResolvedBaseURI: string;
  lNewScope: TScope;
  lValidationVisitor: IValidationVisitor<T>;
  lWalker: IWalker;
  lResultEvaluatedBefore: THashSet<string>;
  lEvaluatedProperty: string;
begin
  if not Supports(Visitor, IValidationVisitor<T>, lValidationVisitor) then
    Exit;

  lScope := Visitor.CurrentScope;

  if not ResolveRefTarget(pValue.Value, lScope.BaseURI, lFinalURI, lTargetResource, lTargetSchema, lResolvedBaseURI) then
    Exit;

  // Prepare new scope for the referenced schema
  lNewScope := lScope;
  lNewScope.BaseURI := lResolvedBaseURI;
  lNewScope.SchemaNode := lTargetSchema;
  lNewScope.SchemaPath := lFinalURI.Unsplit;
  lNewScope.CoveredItems := [];
  lNewScope.ContainsCount := 0;
  lNewScope.VisitedKeywords := [];
  lNewScope.CoveredProperties := [];
  lNewScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

  // Inherit parent evaluated properties
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
      lNewScope := Visitor.CurrentScope;
    finally
      lNewScope := Visitor.PopScope;
    end;

    // Merge newly evaluated properties back into parent scope
    if Assigned(lNewScope.EvaluatedPropertiesInScope) then
    begin
      if not Assigned(lScope.EvaluatedPropertiesInScope) then
        lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

      for lEvaluatedProperty in lNewScope.EvaluatedPropertiesInScope do
      begin
        if lResultEvaluatedBefore.Contains(lEvaluatedProperty) then
          Continue;
        lScope.EvaluatedPropertiesInScope.Add(lEvaluatedProperty);
        lValidationVisitor.Result.AddEvaluatedProperty(lEvaluatedProperty);
      end;
    end;

    lScope.CoveredItems := TUtils.MergeArray<Integer>([lScope.CoveredItems, lNewScope.CoveredItems]);
    lScope.CoveredProperties := TUtils.MergeArray<string>([lScope.CoveredProperties, lNewScope.CoveredProperties]);
    Visitor.UpdateScope(lScope);
  finally
    lResultEvaluatedBefore.Free;
  end;
end;

procedure TBaseCoreVisitor<T>.VisitDefinitions(const pValue: TJSONObject);
begin
  // Default: no operation – definitions are already traversed by the walker
  // (the walker will visit each value as a sub‑schema automatically).
  // This method exists only to satisfy the interface.
end;

procedure TBaseCoreVisitor<T>.VisitBooleanSchema(const pValue: TJSONBool);
var
  lValidationVisitor: IValidationVisitor<T>;
begin
  if not pValue.AsBoolean then
    if Supports(Visitor, IValidationVisitor<T>, lValidationVisitor) then
      lValidationVisitor.AddError(TErrorType.vetSchemaIsFalse);
end;

end.
