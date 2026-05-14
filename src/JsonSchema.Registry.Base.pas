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
    FResources: TDictionary<string, TResource>;
    FInflightResources: TDictionary<string, Byte>;

    procedure DiscoverInObjectOfSchemas(AJsonObject: TJSONObject);
    procedure DiscoverInArrayOfSchemas(AJsonArray: TJSONArray);
    procedure DiscoverInSingleSchema(AJsonValue: TJSONValue);
    class function TryResolveStaticMappedFile(const ARemoteURI: string; out AMappedFilePath: string): Boolean; static;
    class function IsLocalTestServerURI(const AURI: string): Boolean; static;
    procedure TryLoadRemoteResource(const ATargetURI: TURIReference);
  public
    constructor Create(const ASchema, AData: TJSONValue; const ABaseURI: string);
    destructor Destroy; override;
    function New(const ASchema, AData: TJSONValue; const ABaseURI: string): TRegistryVisitor; override;
    function KeywordPrecedence: TArray<string>; override;
    function TryFindResource(const ABaseURI: string; var AResource: TResource): Boolean;
  end;

  TBaseRegistryCoreVisitor = class(TBase<TRegistryVisitor>, IBaseCoreVisitor<TRegistryVisitor>)
    [VisitorKeyword('$schema')]
    procedure VisitSchema(const AValue: TJSONString);
    [VisitorKeyword('$id')]
    procedure VisitId(const AValue: TJSONString);
    [VisitorKeyword('$ref')]
    procedure VisitRef(const AValue: TJSONString);
    [VisitorKeyword('$anchor')]
    procedure VisitAnchor(const AValue: TJSONString);
    [VisitorKeyword('definitions')]
    [VisitorKeyword('$defs')]
    procedure VisitDefinitions(const AValue: TJSONObject);
    procedure VisitBooleanSchema(const AValue: TJSONBool);
  end;

  TBaseRegistryApplicatorVisitor = class(TBase<TRegistryVisitor>, IBaseApplicatorVisitor<TRegistryVisitor>)
    [VisitorKeyword('properties')]
    procedure VisitProperties(const AValue: TJSONObject);
    [VisitorKeyword('items')]
    procedure VisitItems(const AValue: TJSONValue);

    [VisitorKeyword('allOf')]
    procedure VisitAllOf(const AValue: TJSONArray);
    [VisitorKeyword('anyOf')]
    procedure VisitAnyOf(const AValue: TJSONArray);
    [VisitorKeyword('oneOf')]
    procedure VisitOneOf(const AValue: TJSONArray);
    [VisitorKeyword('not')]
    procedure VisitNot(const AValue: TJSONValue);
    [VisitorKeyword('if')]
    procedure VisitIf(const AValue: TJSONValue);
    [VisitorKeyword('then')]
    procedure VisitThen(const AValue: TJSONValue);
    [VisitorKeyword('else')]
    procedure VisitElse(const AValue: TJSONValue);
    [VisitorKeyword('patternProperties')]
    procedure VisitPatternProperties(const AValue: TJSONObject);
    [VisitorKeyword('additionalProperties')]
    procedure VisitAdditionalProperties(const AValue: TJSONValue);
    [VisitorKeyword('additionalItems')]
    procedure VisitAdditionalItems(const AValue: TJSONValue);
    [VisitorKeyword('prefixItems')]
    procedure VisitPrefixItems(const AValue: TJSONArray);
  end;

  TBaseRegistryHyperSchemaVisitor = class(TBase<TRegistryVisitor>, IBaseHyperSchemaVisitor<TRegistryVisitor>)
    procedure VisitBase(const AValue: TJSONString);
    procedure VisitLinks(const AValue: TJSONArray);
    procedure VisitHref(const AValue: TJSONString);
    procedure VisitTargetSchema(const AValue: TJSONValue);
    procedure VisitSubmissionSchema(const AValue: TJSONValue);
    procedure VisitHrefSchema(const AValue: TJSONValue);
  end;

  TBaseRegistryValidationVisitor = class(TBase<TRegistryVisitor>, IBaseValidationVisitor<TRegistryVisitor>)
    procedure VisitType(const AValue: TJSONValue);
    procedure VisitEnum(const AValue: TJSONArray);
    procedure VisitConst(const AValue: TJSONValue);
    procedure VisitMultipleOf(const AValue: TJSONNumber);
    procedure VisitMaximum(const AValue: TJSONNumber);
    procedure VisitExclusiveMaximum(const AValue: TJSONNumber);
    procedure VisitMinimum(const AValue: TJSONNumber);
    procedure VisitExclusiveMinimum(const AValue: TJSONNumber);
    procedure VisitMaxLength(const AValue: TJSONNumber);
    procedure VisitMinLength(const AValue: TJSONNumber);
    procedure VisitPattern(const AValue: TJSONString);
    procedure VisitFormat(const AValue: TJSONString);
    procedure VisitMaxItems(const AValue: TJSONNumber);
    procedure VisitMinItems(const AValue: TJSONNumber);
    procedure VisitUniqueItems(const AValue: TJSONBool);
    procedure VisitMaxProperties(const AValue: TJSONNumber);
    procedure VisitMinProperties(const AValue: TJSONNumber);
    procedure VisitRequired(const AValue: TJSONArray);
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

constructor TRegistryVisitor.Create(const ASchema, AData: TJSONValue; const ABaseURI: string);
begin
  inherited Create(ASchema, AData, ABaseURI);

  FResources := TDictionary<string, TResource>.Create;
  FInflightResources := TDictionary<string, Byte>.Create;
  FResources.Add(ABaseURI, TResource.Create(TURIReference.New(ABaseURI), ASchema));

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

procedure TRegistryVisitor.DiscoverInArrayOfSchemas(AJsonArray: TJSONArray);
var
  LItem: TJSONValue;
begin
  if not Assigned(AJsonArray) then
    Exit;

  for LItem in AJsonArray do
    DiscoverInSingleSchema(LItem);
end;

procedure TRegistryVisitor.DiscoverInObjectOfSchemas(AJsonObject: TJSONObject);
var
  LPair: TJSONPair;
begin
  if not Assigned(AJsonObject) then
    Exit;

  for LPair in AJsonObject do
    DiscoverInSingleSchema(LPair.JsonValue);
end;

procedure TRegistryVisitor.DiscoverInSingleSchema(AJsonValue: TJSONValue);
var
  LScope: TScope;
  LNewScope: TScope;
begin
  LScope := CurrentScope;

  LNewScope := LScope;
  with LNewScope do
  begin
    SchemaNode        := AJsonValue;
    CoveredItems      := [];
    ContainsCount     := 0;
    VisitedKeywords   := [];
    CoveredProperties := [];
  end;

  PushScope(LNewScope);
  try
  // Apenas objetos e booleanos s�o schemas v�lidos para percorrer.
    if Assigned(AJsonValue) and ((AJsonValue is TJSONObject) or (AJsonValue is TJSONBool)) then
      TWalker<TRegistryVisitor>.Create(AJsonValue, Self).Walk;
  finally
    PopScope;
  end;
end;

class function TRegistryVisitor.TryResolveStaticMappedFile(const ARemoteURI: string; out AMappedFilePath: string): Boolean;
var
  LCanonicalURI: string;
  LRepoRootPath: string;
  LCandidatePath: string;
begin
  AMappedFilePath := '';
  LCanonicalURI := LowerCase(ARemoteURI);

  if not ((LCanonicalURI = 'http://json-schema.org/draft-06/schema') or
          (LCanonicalURI = 'https://json-schema.org/draft-06/schema')) then
    Exit(False);

  LRepoRootPath := TPath.GetFullPath(
    TPath.Combine(
      TPath.Combine(
        TPath.Combine(ExtractFilePath(ParamStr(0)), '..'),
        '..'),
      '..'));
  LCandidatePath := TPath.Combine(LRepoRootPath, 'test\schemas\remotes\draft6\schema.json');
  if not FileExists(LCandidatePath) then
    Exit(False);

  AMappedFilePath := LCandidatePath;
  Result := True;
end;

class function TRegistryVisitor.IsLocalTestServerURI(const AURI: string): Boolean;
var
  LLowerURI: string;
begin
  LLowerURI := LowerCase(AURI);
  Result := LLowerURI.StartsWith('http://localhost:1234/') or
            LLowerURI.StartsWith('http://127.0.0.1:1234/');
end;

procedure TRegistryVisitor.TryLoadRemoteResource(const ATargetURI: TURIReference);
var
  LFetchURI: TURIReference;
  LRemoteURI: string;
  LMappedFilePath: string;
  LResourceKeyURI: string;
  LHttpClient: THTTPClient;
  LResponse: IHTTPResponse;
  LResponseBody: string;
  LSchemaRoot: TJSONValue;
  LScope: TScope;
  LNewScope: TScope;
begin
  LFetchURI := ATargetURI;
  LFetchURI.Query := '';
  LFetchURI.Fragment := '';
  LRemoteURI := LFetchURI.Unsplit;
  LResourceKeyURI := TURIUtils.NormalizeURI(LRemoteURI);

  if FResources.ContainsKey(LResourceKeyURI) then
    Exit;

  if FInflightResources.ContainsKey(LResourceKeyURI) then
    Exit;

  FInflightResources.AddOrSetValue(LResourceKeyURI, 1);
  try

    if TryResolveStaticMappedFile(LRemoteURI, LMappedFilePath) then
    begin
      LResponseBody := TFile.ReadAllText(LMappedFilePath, TEncoding.UTF8);
      LSchemaRoot := TJSONObject.ParseJSONValue(LResponseBody);
      if not Assigned(LSchemaRoot) then
        Exit;

      FResources.AddOrSetValue(LResourceKeyURI, TResource.Create(TURIReference.From(LResourceKeyURI), LSchemaRoot));

      LScope := CurrentScope;
      LNewScope := LScope;
      with LNewScope do
      begin
        BaseURI           := LResourceKeyURI;
        SchemaNode        := LSchemaRoot;
        SchemaPath        := '#';
        CoveredItems      := [];
        ContainsCount     := 0;
        VisitedKeywords   := [];
        CoveredProperties := [];
      end;

      PushScope(LNewScope);
      try
        TWalker<TRegistryVisitor>.Create(LSchemaRoot, Self).Walk;
      finally
        PopScope;
      end;
      Exit;
    end;

    if not IsLocalTestServerURI(LRemoteURI) then
      Exit;

    LHttpClient := THTTPClient.Create;
    try
      LResponse := LHttpClient.Get(LRemoteURI);
      if not Assigned(LResponse) or (LResponse.StatusCode <> 200) then
        Exit;

      LResponseBody := LResponse.ContentAsString(TEncoding.UTF8);
      LSchemaRoot := TJSONObject.ParseJSONValue(LResponseBody);
      if not Assigned(LSchemaRoot) then
        Exit;

      FResources.AddOrSetValue(LResourceKeyURI, TResource.Create(TURIReference.From(LResourceKeyURI), LSchemaRoot));

      LScope := CurrentScope;
      LNewScope := LScope;
      with LNewScope do
      begin
        BaseURI           := LResourceKeyURI;
        SchemaNode        := LSchemaRoot;
        SchemaPath        := '#';
        CoveredItems      := [];
        ContainsCount     := 0;
        VisitedKeywords   := [];
        CoveredProperties := [];
      end;

      PushScope(LNewScope);
      try
        TWalker<TRegistryVisitor>.Create(LSchemaRoot, Self).Walk;
      finally
        PopScope;
      end;
    finally
      LHttpClient.Free;
    end;
  finally
    FInflightResources.Remove(LResourceKeyURI);
  end;
end;

function TRegistryVisitor.TryFindResource(const ABaseURI: string; var AResource: TResource): Boolean;
var
  LURI: TURIReference;
begin
  LURI := TURIReference.From(ABaseURI);
  LURI.Query := '';
  LURI.Fragment := '';
  Result := FResources.TryGetValue(LURI.Unsplit, AResource);
end;

function TRegistryVisitor.KeywordPrecedence: TArray<string>;
begin
  Result := [
    '$schema',
    '$id',
    '$ref',
    'properties',
    'items'
  ];
end;

function TRegistryVisitor.New(const ASchema, AData: TJSONValue; const ABaseURI: string): TRegistryVisitor;
begin
  Result := TRegistryVisitor.Create(ASchema, AData, ABaseURI);
end;

{ TBaseRegistryApplicatorVisitor }

procedure TBaseRegistryApplicatorVisitor.VisitAdditionalItems(const AValue: TJSONValue);
begin
  Visitor.DiscoverInSingleSchema(AValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitAdditionalProperties(const AValue: TJSONValue);
begin
  Visitor.DiscoverInSingleSchema(AValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitAllOf(const AValue: TJSONArray);
begin
  Visitor.DiscoverInArrayOfSchemas(AValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitAnyOf(const AValue: TJSONArray);
begin
  Visitor.DiscoverInArrayOfSchemas(AValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitElse(const AValue: TJSONValue);
begin
  Visitor.DiscoverInSingleSchema(AValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitIf(const AValue: TJSONValue);
begin
  Visitor.DiscoverInSingleSchema(AValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitItems(const AValue: TJSONValue);
begin
  // A l�gica de `items` pode ter um schema (objeto) ou um array de schemas.
  if AValue is TJSONObject then
    Visitor.DiscoverInSingleSchema(AValue)
  else if AValue is TJSONArray then
    Visitor.DiscoverInArrayOfSchemas(AValue as TJSONArray);
end;

procedure TBaseRegistryApplicatorVisitor.VisitNot(const AValue: TJSONValue);
begin
  Visitor.DiscoverInSingleSchema(AValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitOneOf(const AValue: TJSONArray);
begin
  Visitor.DiscoverInArrayOfSchemas(AValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitPatternProperties(const AValue: TJSONObject);
begin
  Visitor.DiscoverInObjectOfSchemas(AValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitPrefixItems(const AValue: TJSONArray);
begin
  Visitor.DiscoverInArrayOfSchemas(AValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitProperties(const AValue: TJSONObject);
begin
  // A l�gica � id�ntica a VisitDefinitions: percorrer os valores do objeto.
  Visitor.DiscoverInObjectOfSchemas(AValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitThen(const AValue: TJSONValue);
begin
  Visitor.DiscoverInSingleSchema(AValue);
end;

procedure TBaseRegistryCoreVisitor.VisitAnchor(const AValue: TJSONString);
var
  LScope: TScope;
  LResource: TResource;
begin
  LScope := Visitor.CurrentScope;
  if Visitor.TryFindResource(LScope.BaseURI, LResource) then
    LResource.AddAnchor(AValue.Value, LScope.SchemaNode);
end;

procedure TBaseRegistryCoreVisitor.VisitBooleanSchema(const AValue: TJSONBool);
begin

end;

{ TBaseRegistryCoreVisitor<T> }

procedure TBaseRegistryCoreVisitor.VisitDefinitions(const AValue: TJSONObject);
var
  LPair: TJSONPair;
begin
  for LPair in AValue do
    Visitor.DiscoverInSingleSchema(LPair.JsonValue);
end;

procedure TBaseRegistryCoreVisitor.VisitId(const AValue: TJSONString);
var
  LScope: TScope;
  LNewBaseURI: TURIReference;
  LResourceURI: TURIReference;
  LResource: TResource;
begin
  LScope := Visitor.FScopeStack.Peek;

  // Resolve a nova URI contra a base atual.
  LNewBaseURI := TURIReference.From(AValue.Value).ResolveWith(TURIReference.From(LScope.BaseURI));
  LScope.BaseURI := LNewBaseURI.Unsplit;

  // Atualiza o escopo na pilha ANTES de continuar a recurs�o.
  Visitor.FScopeStack.List[Visitor.FScopeStack.Count - 1] := LScope;

  LResourceURI := LNewBaseURI;
  LResourceURI.Query := '';
  LResourceURI.Fragment := '';

  // Se o recurso base ainda nгo existe, adiciona-o.
  if not Visitor.FResources.ContainsKey(LResourceURI.Unsplit) then
    Visitor.FResources.Add(LResourceURI.Unsplit, TResource.Create(LResourceURI, LScope.SchemaNode));

  // Em drafts antigos, $id com fragmento atua como um identificador local semelhante a anchor.
  if (LNewBaseURI.Fragment <> '') and Visitor.FResources.TryGetValue(LResourceURI.Unsplit, LResource) then
    LResource.AddAnchor(LNewBaseURI.Fragment, LScope.SchemaNode);

  // Marca a palavra-chave como visitada para que o Walker n�o a processe duas vezes
  // se a preced�ncia for usada.
  Visitor.AddVisitedKeyword('$id');
end;

procedure TBaseRegistryCoreVisitor.VisitRef(const AValue: TJSONString);
var
  LScope: TScope;
  LTargetURI: TURIReference;
  LResourceRef: TURIReference;
  LResourceURI: string;
begin
  LScope := Visitor.CurrentScope;
  LTargetURI := TURIReference.From(AValue.Value).ResolveWith(TURIReference.From(LScope.BaseURI));
  LResourceRef := LTargetURI;
  LResourceRef.Query := '';
  LResourceRef.Fragment := '';
  LResourceURI := TURIUtils.NormalizeURI(LResourceRef.Unsplit);

  // Se o recurso referenciado ainda n�o est� no registro, e � "busc�vel" (ex: http),
  // o registro tentar� carreg�-lo.
  if not Visitor.FResources.ContainsKey(LResourceURI) then
    Visitor.TryLoadRemoteResource(LTargetURI);
end;

procedure TBaseRegistryCoreVisitor.VisitSchema(const AValue: TJSONString);
begin

end;

{ TBaseRegistryValidationVisitor }

procedure TBaseRegistryValidationVisitor.VisitConst(const AValue: TJSONValue);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitEnum(const AValue: TJSONArray);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitExclusiveMaximum(const AValue: TJSONNumber);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitExclusiveMinimum(const AValue: TJSONNumber);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitFormat(const AValue: TJSONString);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitMaximum(const AValue: TJSONNumber);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitMaxItems(const AValue: TJSONNumber);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitMaxLength(const AValue: TJSONNumber);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitMaxProperties(const AValue: TJSONNumber);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitMinimum(const AValue: TJSONNumber);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitMinItems(const AValue: TJSONNumber);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitMinLength(const AValue: TJSONNumber);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitMinProperties(const AValue: TJSONNumber);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitMultipleOf(const AValue: TJSONNumber);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitPattern(const AValue: TJSONString);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitRequired(const AValue: TJSONArray);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitType(const AValue: TJSONValue);
begin

end;

procedure TBaseRegistryValidationVisitor.VisitUniqueItems(const AValue: TJSONBool);
begin

end;

{ TBaseRegistryHyperSchemaVisitor }

procedure TBaseRegistryHyperSchemaVisitor.VisitBase(const AValue: TJSONString);
begin

end;

procedure TBaseRegistryHyperSchemaVisitor.VisitHref(const AValue: TJSONString);
begin

end;

procedure TBaseRegistryHyperSchemaVisitor.VisitHrefSchema(const AValue: TJSONValue);
begin

end;

procedure TBaseRegistryHyperSchemaVisitor.VisitLinks(const AValue: TJSONArray);
begin

end;

procedure TBaseRegistryHyperSchemaVisitor.VisitSubmissionSchema(const AValue: TJSONValue);
begin

end;

procedure TBaseRegistryHyperSchemaVisitor.VisitTargetSchema(const AValue: TJSONValue);
begin

end;

end.
