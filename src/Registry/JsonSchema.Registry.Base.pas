unit JsonSchema.Registry.Base;

interface

uses
  System.JSON,
  System.Generics.Collections,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Types,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Registry.Resource,
  JsonSchema.Registry.Uri,
  JsonSchema.Registry.Loader,
  JsonSchema.Walker,
  JsonSchema.Common.Utils;

type
  /// <summary>
  ///   Visitor that traverses a JSON Schema graph to discover and register
  ///   all sub-schema resources, anchors, and remote references.
  ///   Uses dependency injection for resource loading.
  /// </summary>
  TRegistryVisitor = class(TBaseVisitor<TRegistryVisitor>, IVisitor<TRegistryVisitor>)
  private
    FResources: TObjectDictionary<string, TResource>;
    FInflightResources: TDictionary<string, Byte>;
    FLoader: IResourceLoader;
    FBaseURI: string;
  public
    /// <param name="pLoader">Resource loader (injected). If nil, creates default TResourceLoader.</param>
    constructor Create(const pSchema, pData: TJSONValue; const pBaseURI: string;
      const pLoader: IResourceLoader = nil);
    destructor Destroy; override;

    function New(const pSchema, pData: TJSONValue; const pBaseURI: string): TRegistryVisitor; override;
    function KeywordPrecedence: TArray<string>; override;

    procedure DiscoverInObjectOfSchemas(pJsonObject: TJSONObject);
    procedure DiscoverInArrayOfSchemas(pJsonArray: TJSONArray);
    procedure DiscoverInSingleSchema(pJsonValue: TJSONValue);
    procedure TryLoadRemoteResource(const pTargetURI: TURIReference);
    procedure WalkSchemaRoot(const pSchemaRoot: TJSONValue; const pResourceKeyURI: string);
    function TryFindResource(const pBaseURI: string; out pResource: TResource): Boolean;

    property Resources: TObjectDictionary<string, TResource> read FResources;
  end;

  /// <summary>Registry phase handler for core keywords ($schema, $id, $ref, $anchor, $dynamicAnchor, $defs).</summary>
  TBaseRegistryCoreVisitor = class(TBase<TRegistryVisitor>, IBaseCoreVisitor<TRegistryVisitor>)
    [VisitorKeyword('$schema')]
    procedure VisitSchema(const pValue: TJSONString);
    [VisitorKeyword('id')]
    [VisitorKeyword('$id')]
    procedure VisitId(const pValue: TJSONString);
    [VisitorKeyword('$ref')]
    procedure VisitRef(const pValue: TJSONString);
    [VisitorKeyword('$anchor')]
    procedure VisitAnchor(const pValue: TJSONString);
    [VisitorKeyword('$dynamicAnchor')]
    procedure VisitDynamicAnchor(const pValue: TJSONString);
    [VisitorKeyword('definitions')]
    [VisitorKeyword('$defs')]
    procedure VisitDefinitions(const pValue: TJSONObject);
    procedure VisitBooleanSchema(const pValue: TJSONBool);
  end;

  /// <summary>Registry phase handler for applicator keywords.</summary>
  TBaseRegistryApplicatorVisitor = class(TBase<TRegistryVisitor>, IBaseApplicatorVisitor<TRegistryVisitor>)
    [VisitorKeyword('properties')]
    procedure VisitProperties(const pValue: TJSONObject);
    [VisitorKeyword('items')]
    procedure VisitItems(const pValue: TJSONValue);
    [VisitorKeyword('allOf')]
    procedure VisitAllOf(const pValue: TJSONArray);
    [VisitorKeyword('anyOf')]
    procedure VisitAnyOf(const pValue: TJSONArray);
    [VisitorKeyword('oneOf')]
    procedure VisitOneOf(const pValue: TJSONArray);
    [VisitorKeyword('not')]
    procedure VisitNot(const pValue: TJSONValue);
    [VisitorKeyword('if')]
    procedure VisitIf(const pValue: TJSONValue);
    [VisitorKeyword('then')]
    procedure VisitThen(const pValue: TJSONValue);
    [VisitorKeyword('else')]
    procedure VisitElse(const pValue: TJSONValue);
    [VisitorKeyword('patternProperties')]
    procedure VisitPatternProperties(const pValue: TJSONObject);
    [VisitorKeyword('additionalProperties')]
    procedure VisitAdditionalProperties(const pValue: TJSONValue);
    [VisitorKeyword('additionalItems')]
    procedure VisitAdditionalItems(const pValue: TJSONValue);
    [VisitorKeyword('prefixItems')]
    procedure VisitPrefixItems(const pValue: TJSONArray);
  end;

  /// <summary>Registry phase stub for validation keywords (no‑op).</summary>
  TBaseRegistryValidationVisitor = class(TBase<TRegistryVisitor>, IBaseValidationVisitor<TRegistryVisitor>)
    procedure VisitType(const pValue: TJSONValue);
    procedure VisitEnum(const pValue: TJSONArray);
    procedure VisitConst(const pValue: TJSONValue);
    procedure VisitMultipleOf(const pValue: TJSONNumber);
    procedure VisitMaximum(const pValue: TJSONNumber);
    procedure VisitExclusiveMaximum(const pValue: TJSONValue);
    procedure VisitMinimum(const pValue: TJSONNumber);
    procedure VisitExclusiveMinimum(const pValue: TJSONValue);
    procedure VisitMaxLength(const pValue: TJSONNumber);
    procedure VisitMinLength(const pValue: TJSONNumber);
    procedure VisitPattern(const pValue: TJSONString);
    procedure VisitFormat(const pValue: TJSONString);
    procedure VisitMaxItems(const pValue: TJSONNumber);
    procedure VisitMinItems(const pValue: TJSONNumber);
    procedure VisitUniqueItems(const pValue: TJSONBool);
    procedure VisitMaxProperties(const pValue: TJSONNumber);
    procedure VisitMinProperties(const pValue: TJSONNumber);
    procedure VisitRequired(const pValue: TJSONArray);
  end;

  /// <summary>Registry phase stub for hyper-schema (no‑op).</summary>
  TBaseRegistryHyperSchemaVisitor = class(TBase<TRegistryVisitor>, IBaseHyperSchemaVisitor<TRegistryVisitor>)
    procedure VisitBase(const pValue: TJSONString);
    procedure VisitLinks(const pValue: TJSONArray);
    procedure VisitHref(const pValue: TJSONString);
    procedure VisitTargetSchema(const pValue: TJSONValue);
    procedure VisitSubmissionSchema(const pValue: TJSONValue);
    procedure VisitHrefSchema(const pValue: TJSONValue);
  end;

  /// <summary>Registry phase stub for relative JSON pointer (no‑op).</summary>
  TBaseRegistryRelativeJsonPointer = class(TBase<TRegistryVisitor>, IBaseRelativeJsonPointer<TRegistryVisitor>)
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  JsonSchema.Registry.Utils;

{ TRegistryVisitor }

constructor TRegistryVisitor.Create(const pSchema, pData: TJSONValue; const pBaseURI: string;
  const pLoader: IResourceLoader);
begin
  inherited Create(pSchema, pData, pBaseURI);
  FBaseURI := pBaseURI;
  FResources := TObjectDictionary<string, TResource>.Create([doOwnsValues]);
  FInflightResources := TDictionary<string, Byte>.Create;

  if pLoader = nil then
    FLoader := TResourceLoader.Create
  else
    FLoader := pLoader;

  FResources.Add(TURIUtils.NormalizeURI(pBaseURI), TResource.Create(TURIReference.From(pBaseURI), pSchema));

  FCore := TBaseRegistryCoreVisitor.Create(Self);
  FApplicator := TBaseRegistryApplicatorVisitor.Create(Self);
  FHyperSchema := TBaseRegistryHyperSchemaVisitor.Create(Self);
  FRelativeJsonPointer := TBaseRegistryRelativeJsonPointer.Create(Self);
end;

destructor TRegistryVisitor.Destroy;
begin
  FInflightResources.Free;
  FResources.Free;
  inherited;
end;

function TRegistryVisitor.New(const pSchema, pData: TJSONValue; const pBaseURI: string): TRegistryVisitor;
begin
  Result := TRegistryVisitor.Create(pSchema, pData, pBaseURI, FLoader);
end;

function TRegistryVisitor.KeywordPrecedence: TArray<string>;
begin
  Result := ['$schema', '$id', 'id', '$ref', 'properties', 'items'];
end;

procedure TRegistryVisitor.DiscoverInObjectOfSchemas(pJsonObject: TJSONObject);
var
  lPair: TJSONPair;
begin
  if not Assigned(pJsonObject) then
    Exit;
  for lPair in pJsonObject do
    DiscoverInSingleSchema(lPair.JsonValue);
end;

procedure TRegistryVisitor.DiscoverInArrayOfSchemas(pJsonArray: TJSONArray);
var
  lItem: TJSONValue;
begin
  if not Assigned(pJsonArray) then
    Exit;
  for lItem in pJsonArray do
    DiscoverInSingleSchema(lItem);
end;

procedure TRegistryVisitor.DiscoverInSingleSchema(pJsonValue: TJSONValue);
begin
  // In registry discovery, only object schemas may contain nested keywords/resources.
  // Boolean schemas do not need recursive discovery.
  if not (pJsonValue is TJSONObject) then
    Exit;

  TWalker<TRegistryVisitor>.Create(pJsonValue, Self).Walk;
end;

procedure TRegistryVisitor.WalkSchemaRoot(const pSchemaRoot: TJSONValue; const pResourceKeyURI: string);
var
  lScope: TScope;
  lNewScope: TScope;
begin
  lScope := CurrentScope;
  lNewScope := lScope;
  lNewScope.BaseURI := pResourceKeyURI;
  lNewScope.SchemaNode := pSchemaRoot;
  lNewScope.SchemaPath := '#';
  lNewScope.CoveredItems := [];
  lNewScope.ContainsCount := 0;
  lNewScope.VisitedKeywords := [];
  lNewScope.CoveredProperties := [];

  PushScope(lNewScope);
  try
    TWalker<TRegistryVisitor>.Create(pSchemaRoot, Self).Walk;
  finally
    PopScope;
  end;
end;

procedure TRegistryVisitor.TryLoadRemoteResource(const pTargetURI: TURIReference);
var
  lFetchURI: TURIReference;
  lRemoteURI: string;
  lResourceKeyURI: string;
  lSchemaRoot: TJSONValue;
begin
  lFetchURI := pTargetURI;
  lFetchURI.Query := '';
  lFetchURI.Fragment := '';
  lRemoteURI := lFetchURI.Unsplit;
  lResourceKeyURI := TURIUtils.NormalizeURI(lRemoteURI);

  if FResources.ContainsKey(lResourceKeyURI) then
    Exit;
  if FInflightResources.ContainsKey(lResourceKeyURI) then
    Exit;

  FInflightResources.AddOrSetValue(lResourceKeyURI, 1);
  try
    if not FLoader.TryLoadResource(lRemoteURI, lSchemaRoot) then
      Exit;

    FResources.AddOrSetValue(lResourceKeyURI, TResource.Create(TURIReference.From(lResourceKeyURI), lSchemaRoot));
    WalkSchemaRoot(lSchemaRoot, lResourceKeyURI);
  finally
    FInflightResources.Remove(lResourceKeyURI);
  end;
end;

function TRegistryVisitor.TryFindResource(const pBaseURI: string; out pResource: TResource): Boolean;
var
  lURI: TURIReference;
  lNormalizedURI: string;
begin
  lURI := TURIReference.From(pBaseURI);
  lURI.Query := '';
  lURI.Fragment := '';
  lNormalizedURI := TURIUtils.NormalizeURI(lURI.Unsplit);

  Result := FResources.TryGetValue(lNormalizedURI, pResource);
  if not Result then
    Result := FResources.TryGetValue(lURI.Unsplit, pResource);

  if not Result then
  begin
    TryLoadRemoteResource(lURI);
    Result := FResources.TryGetValue(lNormalizedURI, pResource);
    if not Result then
      Result := FResources.TryGetValue(lURI.Unsplit, pResource);
  end;
end;

{ TBaseRegistryCoreVisitor }

procedure TBaseRegistryCoreVisitor.VisitSchema(const pValue: TJSONString);
begin
  // No action needed
end;

procedure TBaseRegistryCoreVisitor.VisitId(const pValue: TJSONString);
var
  lScope: TScope;
  lNewBaseURI: TURIReference;
  lResourceURI: TURIReference;
  lResourceKeyURI: string;
  lResource: TResource;
begin
  lScope := Visitor.CurrentScope;
  lNewBaseURI := TURIReference.From(pValue.Value).ResolveWith(TURIReference.From(lScope.BaseURI));
  lScope.BaseURI := lNewBaseURI.Unsplit;
  Visitor.UpdateScope(lScope);

  lResourceURI := lNewBaseURI;
  lResourceURI.Query := '';
  lResourceURI.Fragment := '';
  lResourceKeyURI := TURIUtils.NormalizeURI(lResourceURI.Unsplit);

  if not Visitor.FResources.ContainsKey(lResourceKeyURI) then
    Visitor.FResources.Add(lResourceKeyURI, TResource.Create(lResourceURI, lScope.SchemaNode));

  if (lNewBaseURI.Fragment <> '') and Visitor.FResources.TryGetValue(lResourceKeyURI, lResource) then
    lResource.AddAnchor(lNewBaseURI.Fragment, lScope.SchemaNode);

  Visitor.AddVisitedKeyword('$id');
  Visitor.AddVisitedKeyword('id');
end;

procedure TBaseRegistryCoreVisitor.VisitRef(const pValue: TJSONString);
var
  lScope: TScope;
  lTargetURI: TURIReference;
  lDefs: TJSONValue;
  lSchemaId: TJSONValue;
begin
  lScope := Visitor.CurrentScope;

  // Process local $id/id before resolving
  if (lScope.SchemaNode is TJSONObject) then
  begin
    if TJSONObject(lScope.SchemaNode).TryGetValue('$id', lSchemaId) and (lSchemaId is TJSONString) then
      VisitId(TJSONString(lSchemaId))
    else if TJSONObject(lScope.SchemaNode).TryGetValue('id', lSchemaId) and (lSchemaId is TJSONString) then
      VisitId(TJSONString(lSchemaId));
    lScope := Visitor.CurrentScope;
  end;

  // Discover anchors inside $defs/definitions before resolving ref
  if (lScope.SchemaNode is TJSONObject) then
  begin
    if TJSONObject(lScope.SchemaNode).TryGetValue('$defs', lDefs) and (lDefs is TJSONObject) then
      Visitor.DiscoverInObjectOfSchemas(TJSONObject(lDefs));
    if TJSONObject(lScope.SchemaNode).TryGetValue('definitions', lDefs) and (lDefs is TJSONObject) then
      Visitor.DiscoverInObjectOfSchemas(TJSONObject(lDefs));
  end;

  lTargetURI := TURIReference.From(pValue.Value).ResolveWith(TURIReference.From(lScope.BaseURI));
  Visitor.TryLoadRemoteResource(lTargetURI);
end;

procedure TBaseRegistryCoreVisitor.VisitAnchor(const pValue: TJSONString);
var
  lScope: TScope;
  lResource: TResource;
  lAnchorName: string;
begin
  lScope := Visitor.CurrentScope;
  lAnchorName := pValue.Value;
  if lAnchorName.StartsWith('#') then
    lAnchorName := lAnchorName.Substring(1);

  if Visitor.TryFindResource(lScope.BaseURI, lResource) then
    lResource.AddAnchor(lAnchorName, lScope.SchemaNode);
end;

procedure TBaseRegistryCoreVisitor.VisitDynamicAnchor(const pValue: TJSONString);
var
  lScope: TScope;
  lResource: TResource;
  lAnchorName: string;
begin
  lScope := Visitor.CurrentScope;
  lAnchorName := pValue.Value;
  if lAnchorName.StartsWith('#') then
    lAnchorName := lAnchorName.Substring(1);

  if Visitor.TryFindResource(lScope.BaseURI, lResource) then
    lResource.AddDynamicAnchor(lAnchorName, lScope.SchemaNode);
end;

procedure TBaseRegistryCoreVisitor.VisitDefinitions(const pValue: TJSONObject);
var
  lPair: TJSONPair;
begin
  for lPair in pValue do
    Visitor.DiscoverInSingleSchema(lPair.JsonValue);
end;

procedure TBaseRegistryCoreVisitor.VisitBooleanSchema(const pValue: TJSONBool);
begin
  // No registration needed
end;

{ TBaseRegistryApplicatorVisitor }

procedure TBaseRegistryApplicatorVisitor.VisitProperties(const pValue: TJSONObject);
begin
  Visitor.DiscoverInObjectOfSchemas(pValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitItems(const pValue: TJSONValue);
begin
  if pValue is TJSONObject then
    Visitor.DiscoverInSingleSchema(pValue)
  else if pValue is TJSONArray then
    Visitor.DiscoverInArrayOfSchemas(TJSONArray(pValue));
end;

procedure TBaseRegistryApplicatorVisitor.VisitAllOf(const pValue: TJSONArray);
begin
  Visitor.DiscoverInArrayOfSchemas(pValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitAnyOf(const pValue: TJSONArray);
begin
  Visitor.DiscoverInArrayOfSchemas(pValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitOneOf(const pValue: TJSONArray);
begin
  Visitor.DiscoverInArrayOfSchemas(pValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitNot(const pValue: TJSONValue);
begin
  Visitor.DiscoverInSingleSchema(pValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitIf(const pValue: TJSONValue);
begin
  Visitor.DiscoverInSingleSchema(pValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitThen(const pValue: TJSONValue);
begin
  Visitor.DiscoverInSingleSchema(pValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitElse(const pValue: TJSONValue);
begin
  Visitor.DiscoverInSingleSchema(pValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitPatternProperties(const pValue: TJSONObject);
begin
  Visitor.DiscoverInObjectOfSchemas(pValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitAdditionalProperties(const pValue: TJSONValue);
begin
  Visitor.DiscoverInSingleSchema(pValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitAdditionalItems(const pValue: TJSONValue);
begin
  Visitor.DiscoverInSingleSchema(pValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitPrefixItems(const pValue: TJSONArray);
begin
  Visitor.DiscoverInArrayOfSchemas(pValue);
end;

{ TBaseRegistryValidationVisitor - all no‑op }

procedure TBaseRegistryValidationVisitor.VisitType(const pValue: TJSONValue);
begin
  // Empty - no registration needed for validation keywords in registry phase
end;

procedure TBaseRegistryValidationVisitor.VisitEnum(const pValue: TJSONArray);
begin
  // Empty - no registration needed for validation keywords in registry phase
end;

procedure TBaseRegistryValidationVisitor.VisitConst(const pValue: TJSONValue);
begin
  // Empty - no registration needed for validation keywords in registry phase
end;

procedure TBaseRegistryValidationVisitor.VisitMultipleOf(const pValue: TJSONNumber);
begin
  // Empty - no registration needed for validation keywords in registry phase
end;

procedure TBaseRegistryValidationVisitor.VisitMaximum(const pValue: TJSONNumber);
begin
  // Empty - no registration needed for validation keywords in registry phase
end;

procedure TBaseRegistryValidationVisitor.VisitExclusiveMaximum(const pValue: TJSONValue);
begin
  // Empty - no registration needed for validation keywords in registry phase
end;

procedure TBaseRegistryValidationVisitor.VisitMinimum(const pValue: TJSONNumber);
begin
  // Empty - no registration needed for validation keywords in registry phase
end;

procedure TBaseRegistryValidationVisitor.VisitExclusiveMinimum(const pValue: TJSONValue);
begin
  // Empty - no registration needed for validation keywords in registry phase
end;

procedure TBaseRegistryValidationVisitor.VisitMaxLength(const pValue: TJSONNumber);
begin
  // Empty - no registration needed for validation keywords in registry phase
end;

procedure TBaseRegistryValidationVisitor.VisitMinLength(const pValue: TJSONNumber);
begin
  // Empty - no registration needed for validation keywords in registry phase
end;

procedure TBaseRegistryValidationVisitor.VisitPattern(const pValue: TJSONString);
begin
  // Empty - no registration needed for validation keywords in registry phase
end;

procedure TBaseRegistryValidationVisitor.VisitFormat(const pValue: TJSONString);
begin
  // Empty - no registration needed for validation keywords in registry phase
end;

procedure TBaseRegistryValidationVisitor.VisitMaxItems(const pValue: TJSONNumber);
begin
  // Empty - no registration needed for validation keywords in registry phase
end;

procedure TBaseRegistryValidationVisitor.VisitMinItems(const pValue: TJSONNumber);
begin
  // Empty - no registration needed for validation keywords in registry phase
end;

procedure TBaseRegistryValidationVisitor.VisitUniqueItems(const pValue: TJSONBool);
begin
  // Empty - no registration needed for validation keywords in registry phase
end;

procedure TBaseRegistryValidationVisitor.VisitMaxProperties(const pValue: TJSONNumber);
begin
  // Empty - no registration needed for validation keywords in registry phase
end;

procedure TBaseRegistryValidationVisitor.VisitMinProperties(const pValue: TJSONNumber);
begin
  // Empty - no registration needed for validation keywords in registry phase
end;

procedure TBaseRegistryValidationVisitor.VisitRequired(const pValue: TJSONArray);
begin
  // Empty - no registration needed for validation keywords in registry phase
end;

{ TBaseRegistryHyperSchemaVisitor - all no‑op }

procedure TBaseRegistryHyperSchemaVisitor.VisitBase(const pValue: TJSONString);
begin
  // Empty - no registration needed for hyper schema keywords in registry phase
end;

procedure TBaseRegistryHyperSchemaVisitor.VisitLinks(const pValue: TJSONArray);
begin
  // Empty - no registration needed for hyper schema keywords in registry phase
end;

procedure TBaseRegistryHyperSchemaVisitor.VisitHref(const pValue: TJSONString);
begin
  // Empty - no registration needed for hyper schema keywords in registry phase
end;

procedure TBaseRegistryHyperSchemaVisitor.VisitTargetSchema(const pValue: TJSONValue);
begin
  // Empty - no registration needed for hyper schema keywords in registry phase
end;

procedure TBaseRegistryHyperSchemaVisitor.VisitSubmissionSchema(const pValue: TJSONValue);
begin
  // Empty - no registration needed for hyper schema keywords in registry phase
end;

procedure TBaseRegistryHyperSchemaVisitor.VisitHrefSchema(const pValue: TJSONValue);
begin
  // Empty - no registration needed for hyper schema keywords in registry phase
end;

end.
