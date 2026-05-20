unit JsonSchema.Visitor.Core.Registry;

interface

uses
  System.JSON,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Types,
  JsonSchema.Registry.Base,
  JsonSchema.Registry.Resource,
  JsonSchema.Registry.Uri,
  JsonSchema.Registry.Utils,
  JsonSchema.Walker,
  JsonSchema.Common.Utils;

type
  /// <summary>
  ///   Registry‑phase visitor for core JSON Schema keywords.
  ///   Handles $schema, $id/id, $ref, $anchor, $dynamicAnchor, definitions/$defs,
  ///   and boolean schemas. Registers resources, anchors, and triggers loading
  ///   of remote $ref targets.
  /// </summary>
  TRegistryCoreVisitor = class(TBase<TRegistryVisitor>, IBaseCoreVisitor<TRegistryVisitor>)
  public
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

implementation

uses
  System.SysUtils;

{ TRegistryCoreVisitor }

procedure TRegistryCoreVisitor.VisitSchema(const pValue: TJSONString);
begin
  // $schema is not used during registry phase; no action required
end;

procedure TRegistryCoreVisitor.VisitId(const pValue: TJSONString);
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

  if not Visitor.Resources.ContainsKey(lResourceKeyURI) then
    Visitor.Resources.Add(lResourceKeyURI, TResource.Create(lResourceURI, lScope.SchemaNode));

  // In older drafts, $id with a fragment acts as an anchor
  if (lNewBaseURI.Fragment <> '') and Visitor.Resources.TryGetValue(lResourceKeyURI, lResource) then
    lResource.AddAnchor(lNewBaseURI.Fragment, lScope.SchemaNode);

  // Mark as visited to avoid double processing
  Visitor.AddVisitedKeyword('$id');
  Visitor.AddVisitedKeyword('id');
end;

procedure TRegistryCoreVisitor.VisitRef(const pValue: TJSONString);
var
  lScope: TScope;
  lTargetURI: TURIReference;
  lDefs: TJSONValue;
  lSchemaId: TJSONValue;
begin
  lScope := Visitor.CurrentScope;

  // Process local $id/id before resolving the ref
  if lScope.SchemaNode is TJSONObject then
  begin
    if TJSONObject(lScope.SchemaNode).TryGetValue('$id', lSchemaId) and (lSchemaId is TJSONString) then
      VisitId(TJSONString(lSchemaId))
    else if TJSONObject(lScope.SchemaNode).TryGetValue('id', lSchemaId) and (lSchemaId is TJSONString) then
      VisitId(TJSONString(lSchemaId));
    lScope := Visitor.CurrentScope;
  end;

  // Discover anchors inside $defs/definitions before resolving the ref
  if lScope.SchemaNode is TJSONObject then
  begin
    if TJSONObject(lScope.SchemaNode).TryGetValue('$defs', lDefs) and (lDefs is TJSONObject) then
      Visitor.DiscoverInObjectOfSchemas(TJSONObject(lDefs));
    if TJSONObject(lScope.SchemaNode).TryGetValue('definitions', lDefs) and (lDefs is TJSONObject) then
      Visitor.DiscoverInObjectOfSchemas(TJSONObject(lDefs));
  end;

  lTargetURI := TURIReference.From(pValue.Value).ResolveWith(TURIReference.From(lScope.BaseURI));
  Visitor.TryLoadRemoteResource(lTargetURI);
end;

procedure TRegistryCoreVisitor.VisitAnchor(const pValue: TJSONString);
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

procedure TRegistryCoreVisitor.VisitDynamicAnchor(const pValue: TJSONString);
var
  lScope: TScope;
  lResource: TResource;
  lAnchorName: string;
begin
  lScope := Visitor.CurrentScope;
  lAnchorName := pValue.Value;
  if lAnchorName.StartsWith('#') then
    lAnchorName := lAnchorName.Substring(1);

  if Visitor.TryFindResource(lScope.BaseURI, lResource) and not lAnchorName.IsEmpty then
    lResource.AddDynamicAnchor(lAnchorName, lScope.SchemaNode);
end;

procedure TRegistryCoreVisitor.VisitDefinitions(const pValue: TJSONObject);
var
  lPair: TJSONPair;
begin
  for lPair in pValue do
    Visitor.DiscoverInSingleSchema(lPair.JsonValue);
end;

procedure TRegistryCoreVisitor.VisitBooleanSchema(const pValue: TJSONBool);
begin
  // Boolean schemas do not contribute to registry discovery; no action required
end;

end.
