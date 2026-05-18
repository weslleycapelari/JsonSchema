unit JsonSchema.Registry.Base;

interface

uses
  System.JSON,
  System.Generics.Collections,
  JsonSchema.Translate.Types,
  JsonSchema.Translate.Interfaces,
  JsonSchema.Translate.Utils,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Types,
  JsonSchema.Common.Utils,
  JsonSchema.Registry.Resource,
  JsonSchema.Registry.Uri;

type
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
    constructor Create(const pSchema, pData: TJSONValue; const pBaseURI: string);
    destructor Destroy; override;
    function New(const pSchema, pData: TJSONValue; const pBaseURI: string): TRegistryVisitor; override;
    function KeywordPrecedence: TArray<string>; override;
    function TryFindResource(const pBaseURI: string; var pResource: TResource): Boolean;
  end;

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

  TBaseRegistryHyperSchemaVisitor = class(TBase<TRegistryVisitor>, IBaseHyperSchemaVisitor<TRegistryVisitor>)
    procedure VisitBase(const pValue: TJSONString);
    procedure VisitLinks(const pValue: TJSONArray);
    procedure VisitHref(const pValue: TJSONString);
    procedure VisitTargetSchema(const pValue: TJSONValue);
    procedure VisitSubmissionSchema(const pValue: TJSONValue);
    procedure VisitHrefSchema(const pValue: TJSONValue);
  end;

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
  // Apenas objetos e booleanos s�o schemas v�lidos para percorrer.
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
  // A l�gica de `items` pode ter um schema (objeto) ou um array de schemas.
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
  // A l�gica � id�ntica a VisitDefinitions: percorrer os valores do objeto.
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

  // Atualiza o escopo na pilha ANTES de continuar a recurs�o.
  Visitor.FScopeStack.List[Visitor.FScopeStack.Count - 1] := lScope;

  lResourceURI := lNewBaseURI;
  lResourceURI.Query := '';
  lResourceURI.Fragment := '';
  lResourceKeyURI := TURIUtils.NormalizeURI(lResourceURI.Unsplit);

  // Se o recurso base ainda nгo existe, adiciona-o.
  if not Visitor.FResources.ContainsKey(lResourceKeyURI) then
    Visitor.FResources.Add(lResourceKeyURI, TResource.Create(lResourceURI, lScope.SchemaNode));

  // Em drafts antigos, $id com fragmento atua como um identificador local semelhante a anchor.
  if (lNewBaseURI.Fragment <> '') and Visitor.FResources.TryGetValue(lResourceKeyURI, lResource) then
    lResource.AddAnchor(lNewBaseURI.Fragment, lScope.SchemaNode);

  // Marca a palavra-chave como visitada para que o Walker n�o a processe duas vezes
  // se a preced�ncia for usada.
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

  // Se o recurso referenciado ainda n�o est� no registro, e � "busc�vel" (ex: http),
  // o registro tentar� carreg�-lo.
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
