unit JsonSchema.Registry.Base;

interface

uses
  System.JSON,
  System.Generics.Collections,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Types,
  JsonSchema.Common.Utils,
  JsonSchema.Registry.Resource,
  JsonSchema.Registry.Uri;

type
  /// <summary>Visitor that traverses a JSON Schema graph to discover and register all sub-schema resources, anchors, and remote references.</summary>
  TRegistryVisitor = class(TBaseVisitor<TRegistryVisitor>, IVisitor<TRegistryVisitor>)
  private
    FResources: TObjectDictionary<string, TResource>;
    FInflightResources: TDictionary<string, Byte>;

    procedure DiscoverInObjectOfSchemas(pJsonObject: TJSONObject);
    procedure DiscoverInArrayOfSchemas(pJsonArray: TJSONArray);
    procedure DiscoverInSingleSchema(pJsonValue: TJSONValue);
    class function TryResolveStaticMappedFile(const pRemoteURI: string; out pMappedFilePath: string): Boolean; static;
    class function IsLocalTestServerURI(const pURI: string): Boolean; static;
    procedure TryLoadRemoteResource(const pTargetURI: TURIReference);
  public
    /// <summary>Initializes the registry visitor, seeds the resource table with the root schema, and wires up all subordinate visitor handlers.</summary>
    /// <param name="pSchema">The root JSON Schema value to register.</param>
    /// <param name="pData">The JSON data instance being validated (may be nil).</param>
    /// <param name="pBaseURI">The absolute base URI that identifies the root schema resource.</param>
    constructor Create(const pSchema, pData: TJSONValue; const pBaseURI: string);
    destructor Destroy; override;
    /// <summary>Creates and returns a new TRegistryVisitor, satisfying the abstract factory contract of TBaseVisitor.</summary>
    /// <param name="pSchema">The root JSON Schema value for the new visitor.</param>
    /// <param name="pData">The JSON data instance for the new visitor.</param>
    /// <param name="pBaseURI">The base URI for the new visitor.</param>
    /// <returns>A newly constructed TRegistryVisitor.</returns>
    function New(const pSchema, pData: TJSONValue; const pBaseURI: string): TRegistryVisitor; override;
    /// <summary>Returns the ordered list of keywords that must be processed before all others during schema traversal.</summary>
    /// <returns>An array of keyword strings in priority order.</returns>
    function KeywordPrecedence: TArray<string>; override;
    /// <summary>Attempts to locate a registered TResource by its base URI, triggering a remote fetch if the resource has not yet been loaded.</summary>
    /// <param name="pBaseURI">The URI whose resource is being looked up.</param>
    /// <param name="pResource">Receives the found TResource when the function returns True.</param>
    /// <returns>True if the resource was found (locally or after a remote load); False otherwise.</returns>
    function TryFindResource(const pBaseURI: string; var pResource: TResource): Boolean;
  end;

  /// <summary>Registry phase handler for core JSON Schema keywords ($schema, $id, id, $ref, $anchor, $dynamicAnchor, $defs, definitions); populates the resource registry during schema traversal.</summary>
  TBaseRegistryCoreVisitor = class(TBase<TRegistryVisitor>, IBaseCoreVisitor<TRegistryVisitor>)
    [VisitorKeyword('$schema')]
    procedure VisitSchema(const pValue: TJSONString);
    /// <summary>Handles the id/$id keyword: resolves the new base URI, registers the schema node as a resource, and records fragment-based anchors for older draft compatibility.</summary>
    /// <param name="pValue">The JSON string value of the id or $id keyword.</param>
    [VisitorKeyword('id')]
    [VisitorKeyword('$id')]
    procedure VisitId(const pValue: TJSONString);
    /// <summary>Handles the $ref keyword: resolves the reference URI against the current base and triggers loading of any unregistered remote resource it targets.</summary>
    /// <param name="pValue">The JSON string value of the $ref keyword.</param>
    [VisitorKeyword('$ref')]
    procedure VisitRef(const pValue: TJSONString);
    /// <summary>Handles the $anchor keyword: registers the named anchor and its absolute URI form against the current base resource.</summary>
    /// <param name="pValue">The JSON string value of the $anchor keyword.</param>
    [VisitorKeyword('$anchor')]
    procedure VisitAnchor(const pValue: TJSONString);
    /// <summary>Handles the $dynamicAnchor keyword: registers the named dynamic anchor in the current base resource to support late-binding reference resolution.</summary>
    /// <param name="pValue">The JSON string value of the $dynamicAnchor keyword.</param>
    [VisitorKeyword('$dynamicAnchor')]
    procedure VisitDynamicAnchor(const pValue: TJSONString);
    /// <summary>Handles the definitions/$defs keyword: recurses into each sub-schema value to discover and register nested resources and anchors.</summary>
    /// <param name="pValue">The JSON object whose values are sub-schemas to traverse.</param>
    [VisitorKeyword('definitions')]
    [VisitorKeyword('$defs')]
    procedure VisitDefinitions(const pValue: TJSONObject);
    procedure VisitBooleanSchema(const pValue: TJSONBool);
  end;

  /// <summary>Registry phase handler for applicator keywords; recursively traverses sub-schemas referenced by combinators, conditionals, and structural keywords to register all reachable resources.</summary>
  TBaseRegistryApplicatorVisitor = class(TBase<TRegistryVisitor>, IBaseApplicatorVisitor<TRegistryVisitor>)
    /// <summary>Registers resources reachable through each property sub-schema.</summary>
    /// <param name="pValue">The JSON object whose values are property sub-schemas.</param>
    [VisitorKeyword('properties')]
    procedure VisitProperties(const pValue: TJSONObject);
    /// <summary>Registers resources reachable through the items keyword, dispatching on whether the value is a single schema object or an array of schemas.</summary>
    /// <param name="pValue">The JSON value representing either a single schema or an array of schemas.</param>
    [VisitorKeyword('items')]
    procedure VisitItems(const pValue: TJSONValue);

    /// <summary>Registers resources reachable through every sub-schema in the allOf array.</summary>
    /// <param name="pValue">The JSON array of sub-schemas that must all apply.</param>
    [VisitorKeyword('allOf')]
    procedure VisitAllOf(const pValue: TJSONArray);
    /// <summary>Registers resources reachable through every sub-schema in the anyOf array.</summary>
    /// <param name="pValue">The JSON array of sub-schemas of which at least one must apply.</param>
    [VisitorKeyword('anyOf')]
    procedure VisitAnyOf(const pValue: TJSONArray);
    /// <summary>Registers resources reachable through every sub-schema in the oneOf array.</summary>
    /// <param name="pValue">The JSON array of sub-schemas of which exactly one must apply.</param>
    [VisitorKeyword('oneOf')]
    procedure VisitOneOf(const pValue: TJSONArray);
    /// <summary>Registers resources reachable through the not sub-schema.</summary>
    /// <param name="pValue">The JSON value representing the negated sub-schema.</param>
    [VisitorKeyword('not')]
    procedure VisitNot(const pValue: TJSONValue);
    /// <summary>Registers resources reachable through the if sub-schema.</summary>
    /// <param name="pValue">The JSON value representing the condition sub-schema.</param>
    [VisitorKeyword('if')]
    procedure VisitIf(const pValue: TJSONValue);
    /// <summary>Registers resources reachable through the then sub-schema.</summary>
    /// <param name="pValue">The JSON value representing the sub-schema applied when the if condition succeeds.</param>
    [VisitorKeyword('then')]
    procedure VisitThen(const pValue: TJSONValue);
    /// <summary>Registers resources reachable through the else sub-schema.</summary>
    /// <param name="pValue">The JSON value representing the sub-schema applied when the if condition fails.</param>
    [VisitorKeyword('else')]
    procedure VisitElse(const pValue: TJSONValue);
    /// <summary>Registers resources reachable through each patternProperties sub-schema.</summary>
    /// <param name="pValue">The JSON object whose values are pattern-keyed sub-schemas.</param>
    [VisitorKeyword('patternProperties')]
    procedure VisitPatternProperties(const pValue: TJSONObject);
    /// <summary>Registers resources reachable through the additionalProperties sub-schema.</summary>
    /// <param name="pValue">The JSON value representing the sub-schema for additional properties.</param>
    [VisitorKeyword('additionalProperties')]
    procedure VisitAdditionalProperties(const pValue: TJSONValue);
    /// <summary>Registers resources reachable through the additionalItems sub-schema.</summary>
    /// <param name="pValue">The JSON value representing the sub-schema for additional items.</param>
    [VisitorKeyword('additionalItems')]
    procedure VisitAdditionalItems(const pValue: TJSONValue);
    /// <summary>Registers resources reachable through every sub-schema in the prefixItems array.</summary>
    /// <param name="pValue">The JSON array of positional item sub-schemas.</param>
    [VisitorKeyword('prefixItems')]
    procedure VisitPrefixItems(const pValue: TJSONArray);
  end;

  /// <summary>Registry phase stub handler for JSON Hyper-Schema keywords; all methods are no-ops during the resource-discovery phase.</summary>
  TBaseRegistryHyperSchemaVisitor = class(TBase<TRegistryVisitor>, IBaseHyperSchemaVisitor<TRegistryVisitor>)
    procedure VisitBase(const pValue: TJSONString);
    procedure VisitLinks(const pValue: TJSONArray);
    procedure VisitHref(const pValue: TJSONString);
    procedure VisitTargetSchema(const pValue: TJSONValue);
    procedure VisitSubmissionSchema(const pValue: TJSONValue);
    procedure VisitHrefSchema(const pValue: TJSONValue);
  end;

  /// <summary>Registry phase stub handler for validation keywords; all methods are no-ops during the resource-discovery phase.</summary>
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

  /// <summary>Registry phase stub handler for the relative JSON Pointer vocabulary; no-ops during the resource-discovery phase.</summary>
  TBaseRegistryRelativeJsonPointer = class(TBase<TRegistryVisitor>, IBaseRelativeJsonPointer<TRegistryVisitor>)
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Net.HttpClient,
  JsonSchema.Walker,
  JsonSchema.Registry.Utils;

{ TRegistryVisitor }

constructor TRegistryVisitor.Create(const pSchema, pData: TJSONValue; const pBaseURI: string);
begin
  inherited Create(pSchema, pData, pBaseURI);

  FResources := TObjectDictionary<string, TResource>.Create([doOwnsValues]);
  FInflightResources := TDictionary<string, Byte>.Create;
  FResources.Add(TURIUtils.NormalizeURI(pBaseURI), TResource.Create(TURIReference.New(pBaseURI), pSchema));

  FCore                := TBaseRegistryCoreVisitor.Create(Self);
  FApplicator          := TBaseRegistryApplicatorVisitor.Create(Self);
  FValidation          := TBaseRegistryValidationVisitor.Create(Self);
  FHyperSchema         := TBaseRegistryHyperSchemaVisitor.Create(Self);
  FRelativeJsonPointer := TBaseRegistryRelativeJsonPointer.Create(Self);
end;

destructor TRegistryVisitor.Destroy;
begin
  FInflightResources.Free;
  FResources.Free;
  inherited;
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

procedure TRegistryVisitor.DiscoverInObjectOfSchemas(pJsonObject: TJSONObject);
var
  lPair: TJSONPair;
begin
  if not Assigned(pJsonObject) then
    Exit;

  for lPair in pJsonObject do
    DiscoverInSingleSchema(lPair.JsonValue);
end;

procedure TRegistryVisitor.DiscoverInSingleSchema(pJsonValue: TJSONValue);
var
  lScope: TScope;
  lNewScope: TScope;
begin
  lScope := CurrentScope;

  lNewScope := lScope;
  lNewScope.SchemaNode        := pJsonValue;
  lNewScope.CoveredItems      := [];
  lNewScope.ContainsCount     := 0;
  lNewScope.VisitedKeywords   := [];
  lNewScope.CoveredProperties := [];

  PushScope(lNewScope);
  try
  if Assigned(pJsonValue) and ((pJsonValue is TJSONObject) or (pJsonValue is TJSONBool)) then
      TWalker<TRegistryVisitor>.Create(pJsonValue, Self).Walk;
  finally
    PopScope;
  end;
end;

class function TRegistryVisitor.TryResolveStaticMappedFile(const pRemoteURI: string; out pMappedFilePath: string): Boolean;
var
  lCanonicalURI: string;
  lRepoRootPath: string;
  lCandidatePath: string;
  lRelativeRemotePath: string;
begin
  pMappedFilePath := '';
  lCanonicalURI := LowerCase(pRemoteURI);

  lRepoRootPath := TPath.GetFullPath(
    TPath.Combine(
      TPath.Combine(
        TPath.Combine(ExtractFilePath(ParamStr(0)), '..'),
        '..'),
      '..'));

  if (lCanonicalURI = 'http://json-schema.org/draft-06/schema') or
     (lCanonicalURI = 'https://json-schema.org/draft-06/schema') then
    lCandidatePath := TPath.Combine(lRepoRootPath, 'test\schemas\remotes\draft6\schema.json')
  else if (lCanonicalURI = 'http://json-schema.org/draft-07/schema') or
          (lCanonicalURI = 'https://json-schema.org/draft-07/schema') then
    lCandidatePath := TPath.Combine(lRepoRootPath, 'test\schemas\remotes\draft7\schema.json')
  else if (lCanonicalURI = 'http://json-schema.org/draft/2019-09/schema') or
          (lCanonicalURI = 'https://json-schema.org/draft/2019-09/schema') then
    lCandidatePath := TPath.Combine(lRepoRootPath, 'test\schemas\remotes\draft2019-09\schema.json')
  else if (lCanonicalURI = 'https://json-schema.org/draft/2020-12/schema') then
    lCandidatePath := TPath.Combine(lRepoRootPath, 'test\schemas\remotes\draft2020-12\schema.json')
  else if lCanonicalURI.EndsWith('/draft2020-12/baseurichangefolder/baseurichangefolder/folderinteger.json') then
    lCandidatePath := TPath.Combine(lRepoRootPath, 'test\schemas\remotes\draft2020-12\baseUriChangeFolder\folderInteger.json')
  else if lCanonicalURI.EndsWith('/draft2020-12/baseurichangefolderinsubschema/baseurichangefolderinsubschema/folderinteger.json') then
    lCandidatePath := TPath.Combine(lRepoRootPath, 'test\schemas\remotes\draft2020-12\baseUriChangeFolderInSubschema\folderInteger.json')
  else if lCanonicalURI.EndsWith('/draft2019-09/baseurichangefolder/baseurichangefolder/folderinteger.json') then
      lCandidatePath := TPath.Combine(lRepoRootPath, 'test\schemas\remotes\draft2019-09\baseUriChangeFolder\folderInteger.json')
    else if (lCanonicalURI = 'https://json-schema.org/draft/2019-09/meta/core') then
      lCandidatePath := TPath.Combine(lRepoRootPath, 'test\schemas\remotes\draft2019-09\meta\core.json')
    else if (lCanonicalURI = 'https://json-schema.org/draft/2019-09/meta/applicator') then
      lCandidatePath := TPath.Combine(lRepoRootPath, 'test\schemas\remotes\draft2019-09\meta\applicator.json')
    else if (lCanonicalURI = 'https://json-schema.org/draft/2019-09/meta/validation') then
      lCandidatePath := TPath.Combine(lRepoRootPath, 'test\schemas\remotes\draft2019-09\meta\validation.json')
    else if (lCanonicalURI = 'https://json-schema.org/draft/2019-09/meta/meta-data') then
      lCandidatePath := TPath.Combine(lRepoRootPath, 'test\schemas\remotes\draft2019-09\meta\meta-data.json')
    else if (lCanonicalURI = 'https://json-schema.org/draft/2019-09/meta/format') then
      lCandidatePath := TPath.Combine(lRepoRootPath, 'test\schemas\remotes\draft2019-09\meta\format.json')
    else if (lCanonicalURI = 'https://json-schema.org/draft/2019-09/meta/content') then
      lCandidatePath := TPath.Combine(lRepoRootPath, 'test\schemas\remotes\draft2019-09\meta\content.json')
  else if lCanonicalURI.EndsWith('/draft2019-09/baseurichangefolderinsubschema/baseurichangefolderinsubschema/folderinteger.json') then
    lCandidatePath := TPath.Combine(lRepoRootPath, 'test\schemas\remotes\draft2019-09\baseUriChangeFolderInSubschema\folderInteger.json')
  else
  begin
    if lCanonicalURI.StartsWith('http://test.json-schema.org/') or
       lCanonicalURI.StartsWith('https://test.json-schema.org/') then
    begin
      lRelativeRemotePath := pRemoteURI;
      lRelativeRemotePath := StringReplace(lRelativeRemotePath, 'http://test.json-schema.org/', '', [rfIgnoreCase]);
      lRelativeRemotePath := StringReplace(lRelativeRemotePath, 'https://test.json-schema.org/', '', [rfIgnoreCase]);
      lRelativeRemotePath := StringReplace(lRelativeRemotePath, '/', PathDelim, [rfReplaceAll]);

      lCandidatePath := TPath.Combine(lRepoRootPath, TPath.Combine('test\schemas\remotes\draft2020-12', lRelativeRemotePath));
      if not FileExists(lCandidatePath) and not lCandidatePath.EndsWith('.json') then
        lCandidatePath := lCandidatePath + '.json';

      if FileExists(lCandidatePath) then
      begin
        pMappedFilePath := lCandidatePath;
        Exit(True);
      end;
    end;

    if IsLocalTestServerURI(pRemoteURI) then
    begin
      lRelativeRemotePath := StringReplace(pRemoteURI, 'http://localhost:1234/', '', [rfIgnoreCase]);
      lRelativeRemotePath := StringReplace(lRelativeRemotePath, 'http://127.0.0.1:1234/', '', [rfIgnoreCase]);
      lRelativeRemotePath := StringReplace(lRelativeRemotePath, '/', PathDelim, [rfReplaceAll]);
      lCandidatePath := TPath.Combine(lRepoRootPath, TPath.Combine('test\schemas\remotes', lRelativeRemotePath));
      if FileExists(lCandidatePath) then
      begin
        pMappedFilePath := lCandidatePath;
        Exit(True);
      end;
    end;

    Exit(False);
  end;

  if not FileExists(lCandidatePath) then
    Exit(False);

  pMappedFilePath := lCandidatePath;
  Result := True;
end;

class function TRegistryVisitor.IsLocalTestServerURI(const pURI: string): Boolean;
var
  lLowerURI: string;
begin
  lLowerURI := LowerCase(pURI);
  Result := lLowerURI.StartsWith('http://localhost:1234/') or
            lLowerURI.StartsWith('http://127.0.0.1:1234/');
end;

procedure TRegistryVisitor.TryLoadRemoteResource(const pTargetURI: TURIReference);
var
  lFetchURI: TURIReference;
  lRemoteURI: string;
  lMappedFilePath: string;
  lResourceKeyURI: string;
  lHttpClient: THTTPClient;
  lResponse: IHTTPResponse;
  lResponseBody: string;
  lSchemaRoot: TJSONValue;
  lScope: TScope;
  lNewScope: TScope;
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

    if TryResolveStaticMappedFile(lRemoteURI, lMappedFilePath) then
    begin
      lResponseBody := TFile.ReadAllText(lMappedFilePath, TEncoding.UTF8);
      lSchemaRoot := TJSONObject.ParseJSONValue(lResponseBody);
      if not Assigned(lSchemaRoot) then
        Exit;

      FResources.AddOrSetValue(lResourceKeyURI, TResource.Create(TURIReference.From(lResourceKeyURI), lSchemaRoot));

      lScope := CurrentScope;
      lNewScope := lScope;
      lNewScope.BaseURI           := lResourceKeyURI;
      lNewScope.SchemaNode        := lSchemaRoot;
      lNewScope.SchemaPath        := '#';
      lNewScope.CoveredItems      := [];
      lNewScope.ContainsCount     := 0;
      lNewScope.VisitedKeywords   := [];
      lNewScope.CoveredProperties := [];

      PushScope(lNewScope);
      try
        TWalker<TRegistryVisitor>.Create(lSchemaRoot, Self).Walk;
      finally
        PopScope;
      end;
      Exit;
    end;

    if not IsLocalTestServerURI(lRemoteURI) then
      Exit;

    lHttpClient := THTTPClient.Create;
    try
      lResponse := lHttpClient.Get(lRemoteURI);
      if not Assigned(lResponse) or (lResponse.StatusCode <> 200) then
        Exit;

      lResponseBody := lResponse.ContentAsString(TEncoding.UTF8);
      lSchemaRoot := TJSONObject.ParseJSONValue(lResponseBody);
      if not Assigned(lSchemaRoot) then
        Exit;

      FResources.AddOrSetValue(lResourceKeyURI, TResource.Create(TURIReference.From(lResourceKeyURI), lSchemaRoot));

      lScope := CurrentScope;
      lNewScope := lScope;
      lNewScope.BaseURI           := lResourceKeyURI;
      lNewScope.SchemaNode        := lSchemaRoot;
      lNewScope.SchemaPath        := '#';
      lNewScope.CoveredItems      := [];
      lNewScope.ContainsCount     := 0;
      lNewScope.VisitedKeywords   := [];
      lNewScope.CoveredProperties := [];

      PushScope(lNewScope);
      try
        TWalker<TRegistryVisitor>.Create(lSchemaRoot, Self).Walk;
      finally
        PopScope;
      end;
    finally
      lHttpClient.Free;
    end;
  finally
    FInflightResources.Remove(lResourceKeyURI);
  end;
end;

function TRegistryVisitor.TryFindResource(const pBaseURI: string; var pResource: TResource): Boolean;
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

function TRegistryVisitor.KeywordPrecedence: TArray<string>;
begin
  Result := [
    '$schema',
    '$id',
    'id',
    '$ref',
    'properties',
    'items'
  ];
end;

function TRegistryVisitor.New(const pSchema, pData: TJSONValue; const pBaseURI: string): TRegistryVisitor;
begin
  Result := TRegistryVisitor.Create(pSchema, pData, pBaseURI);
end;

{ TBaseRegistryApplicatorVisitor }

procedure TBaseRegistryApplicatorVisitor.VisitAdditionalItems(const pValue: TJSONValue);
begin
  Visitor.DiscoverInSingleSchema(pValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitAdditionalProperties(const pValue: TJSONValue);
begin
  Visitor.DiscoverInSingleSchema(pValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitAllOf(const pValue: TJSONArray);
begin
  Visitor.DiscoverInArrayOfSchemas(pValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitAnyOf(const pValue: TJSONArray);
begin
  Visitor.DiscoverInArrayOfSchemas(pValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitElse(const pValue: TJSONValue);
begin
  Visitor.DiscoverInSingleSchema(pValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitIf(const pValue: TJSONValue);
begin
  Visitor.DiscoverInSingleSchema(pValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitItems(const pValue: TJSONValue);
begin
  if pValue is TJSONObject then
    Visitor.DiscoverInSingleSchema(pValue)
  else if pValue is TJSONArray then
    Visitor.DiscoverInArrayOfSchemas(pValue as TJSONArray);
end;

procedure TBaseRegistryApplicatorVisitor.VisitNot(const pValue: TJSONValue);
begin
  Visitor.DiscoverInSingleSchema(pValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitOneOf(const pValue: TJSONArray);
begin
  Visitor.DiscoverInArrayOfSchemas(pValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitPatternProperties(const pValue: TJSONObject);
begin
  Visitor.DiscoverInObjectOfSchemas(pValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitPrefixItems(const pValue: TJSONArray);
begin
  Visitor.DiscoverInArrayOfSchemas(pValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitProperties(const pValue: TJSONObject);
begin
  Visitor.DiscoverInObjectOfSchemas(pValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitThen(const pValue: TJSONValue);
begin
  Visitor.DiscoverInSingleSchema(pValue);
end;

procedure TBaseRegistryCoreVisitor.VisitAnchor(const pValue: TJSONString);
var
  lScope: TScope;
  lResource: TResource;
  lAnchorName: string;
  lAbsoluteAnchor: string;
begin
  lScope := Visitor.CurrentScope;
  lAnchorName := pValue.Value;
  if lAnchorName.StartsWith('#') then
    lAnchorName := lAnchorName.Substring(1);

  if Visitor.TryFindResource(lScope.BaseURI, lResource) then
  begin
    lResource.AddAnchor(lAnchorName, lScope.SchemaNode);
    if not lAnchorName.IsEmpty then
    begin
      lResource.AddAnchor('#' + lAnchorName, lScope.SchemaNode);

      lAbsoluteAnchor := lScope.BaseURI + '#' + lAnchorName;
      lResource.AddAnchor(lAbsoluteAnchor, lScope.SchemaNode);
    end;
  end;
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

  if Visitor.TryFindResource(lScope.BaseURI, lResource) and (not lAnchorName.IsEmpty) then
    lResource.AddDynamicAnchor(lAnchorName, lScope.SchemaNode);
end;

procedure TBaseRegistryCoreVisitor.VisitBooleanSchema(const pValue: TJSONBool);
begin

end;

{ TBaseRegistryCoreVisitor<T> }

procedure TBaseRegistryCoreVisitor.VisitDefinitions(const pValue: TJSONObject);
var
  lPair: TJSONPair;
begin
  for lPair in pValue do
    Visitor.DiscoverInSingleSchema(lPair.JsonValue);
end;

procedure TBaseRegistryCoreVisitor.VisitId(const pValue: TJSONString);
var
  lScope: TScope;
  lNewBaseURI: TURIReference;
  lResourceURI: TURIReference;
  lResourceKeyURI: string;
  lResource: TResource;
begin
  lScope := Visitor.FScopeStack.Peek;

  // Resolve a nova URI contra a base atual.
  lNewBaseURI := TURIReference.From(pValue.Value).ResolveWith(TURIReference.From(lScope.BaseURI));
  lScope.BaseURI := lNewBaseURI.Unsplit;

  // Update the scope in the stack BEFORE continuing the recursion.
  Visitor.FScopeStack.List[Visitor.FScopeStack.Count - 1] := lScope;

  lResourceURI := lNewBaseURI;
  lResourceURI.Query := '';
  lResourceURI.Fragment := '';
  lResourceKeyURI := TURIUtils.NormalizeURI(lResourceURI.Unsplit);

  if not Visitor.FResources.ContainsKey(lResourceKeyURI) then
    Visitor.FResources.Add(lResourceKeyURI, TResource.Create(lResourceURI, lScope.SchemaNode));

  // Em drafts antigos, $id com fragmento atua como um identificador local semelhante a anchor.
  if (lNewBaseURI.Fragment <> '') and Visitor.FResources.TryGetValue(lResourceKeyURI, lResource) then
    lResource.AddAnchor(lNewBaseURI.Fragment, lScope.SchemaNode);

  // Mark $id and id as visited so the Walker does not dispatch them again during precedence processing.
  Visitor.AddVisitedKeyword('$id');
  Visitor.AddVisitedKeyword('id');
end;

procedure TBaseRegistryCoreVisitor.VisitRef(const pValue: TJSONString);
var
  lScope: TScope;
  lTargetURI: TURIReference;
  lResourceRef: TURIReference;
  lResourceURI: string;
  lDefs: TJSONValue;
  lSchemaId: TJSONValue;
begin
  lScope := Visitor.CurrentScope;

  // Se o schema atual declara id/$id, atualiza a base antes de resolver $ref.
  if (lScope.SchemaNode is TJSONObject) then
  begin
    if TJSONObject(lScope.SchemaNode).TryGetValue('$id', lSchemaId) and (lSchemaId is TJSONString) then
      VisitId(TJSONString(lSchemaId))
    else if TJSONObject(lScope.SchemaNode).TryGetValue('id', lSchemaId) and (lSchemaId is TJSONString) then
      VisitId(TJSONString(lSchemaId));

    lScope := Visitor.CurrentScope;
  end;

  // Mesmo quando há $ref no schema atual, precisamos descobrir âncoras em $defs
  // para resolver referências locais e URNs definidos por $id.
  if (lScope.SchemaNode is TJSONObject) then
  begin
    if TJSONObject(lScope.SchemaNode).TryGetValue('$defs', lDefs) and (lDefs is TJSONObject) then
      Visitor.DiscoverInObjectOfSchemas(TJSONObject(lDefs));

    if TJSONObject(lScope.SchemaNode).TryGetValue('definitions', lDefs) and (lDefs is TJSONObject) then
      Visitor.DiscoverInObjectOfSchemas(TJSONObject(lDefs));
  end;

  lTargetURI := TURIReference.From(pValue.Value).ResolveWith(TURIReference.From(lScope.BaseURI));
  lResourceRef := lTargetURI;
  lResourceRef.Query := '';
  lResourceRef.Fragment := '';
  lResourceURI := TURIUtils.NormalizeURI(lResourceRef.Unsplit);

  // If the referenced resource is not yet in the registry and the URI is fetchable (e.g. http), attempt to load it.
  if not Visitor.FResources.ContainsKey(lResourceURI) then
    Visitor.TryLoadRemoteResource(lTargetURI);
end;

procedure TBaseRegistryCoreVisitor.VisitSchema(const pValue: TJSONString);
begin

end;

{ TBaseRegistryValidationVisitor }

procedure TBaseRegistryValidationVisitor.VisitConst(const pValue: TJSONValue);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitEnum(const pValue: TJSONArray);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitExclusiveMaximum(const pValue: TJSONValue);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitExclusiveMinimum(const pValue: TJSONValue);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitFormat(const pValue: TJSONString);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitMaximum(const pValue: TJSONNumber);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitMaxItems(const pValue: TJSONNumber);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitMaxLength(const pValue: TJSONNumber);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitMaxProperties(const pValue: TJSONNumber);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitMinimum(const pValue: TJSONNumber);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitMinItems(const pValue: TJSONNumber);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitMinLength(const pValue: TJSONNumber);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitMinProperties(const pValue: TJSONNumber);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitMultipleOf(const pValue: TJSONNumber);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitPattern(const pValue: TJSONString);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitRequired(const pValue: TJSONArray);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitType(const pValue: TJSONValue);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitUniqueItems(const pValue: TJSONBool);
begin

end;

{ TBaseRegistryHyperSchemaVisitor }

procedure TBaseRegistryHyperSchemaVisitor.VisitBase(const pValue: TJSONString);
begin

end;

procedure TBaseRegistryHyperSchemaVisitor.VisitHref(const pValue: TJSONString);
begin

end;

procedure TBaseRegistryHyperSchemaVisitor.VisitHrefSchema(const pValue: TJSONValue);
begin

end;

procedure TBaseRegistryHyperSchemaVisitor.VisitLinks(const pValue: TJSONArray);
begin

end;

procedure TBaseRegistryHyperSchemaVisitor.VisitSubmissionSchema(const pValue: TJSONValue);
begin

end;

procedure TBaseRegistryHyperSchemaVisitor.VisitTargetSchema(const pValue: TJSONValue);
begin

end;

end.
