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
  JsonSchema.Registry.Resource;

type
  TRegistryVisitor = class(TBaseVisitor<TRegistryVisitor>, IVisitor<TRegistryVisitor>)
  private
    FResources: TDictionary<string, TResource>;

    procedure DiscoverInObjectOfSchemas(AJsonObject: TJSONObject);
    procedure DiscoverInArrayOfSchemas(AJsonArray: TJSONArray);
    procedure DiscoverInSingleSchema(AJsonValue: TJSONValue);
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

    procedure VisitAllOf(const AValue: TJSONArray);
    procedure VisitAnyOf(const AValue: TJSONArray);
    procedure VisitOneOf(const AValue: TJSONArray);
    procedure VisitNot(const AValue: TJSONValue);
    procedure VisitIf(const AValue: TJSONValue);
    procedure VisitThen(const AValue: TJSONValue);
    procedure VisitElse(const AValue: TJSONValue);
    procedure VisitPatternProperties(const AValue: TJSONObject);
    procedure VisitAdditionalProperties(const AValue: TJSONValue);
    procedure VisitAdditionalItems(const AValue: TJSONValue);
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
  JsonSchema.Walker,
  JsonSchema.Registry.Uri,
  JsonSchema.Registry.Utils;

{ TRegistryVisitor }

constructor TRegistryVisitor.Create(const ASchema, AData: TJSONValue; const ABaseURI: string);
begin
  inherited Create(ASchema, AData, ABaseURI);

  FResources := TDictionary<string, TResource>.Create;
  FResources.Add(ABaseURI, TResource.Create(TURIReference.New(ABaseURI), ASchema));

  FCore                := TBaseRegistryCoreVisitor.Create(Self);
  FApplicator          := TBaseRegistryApplicatorVisitor.Create(Self);
  FValidation          := TBaseRegistryValidationVisitor.Create(Self);
  FHyperSchema         := TBaseRegistryHyperSchemaVisitor.Create(Self);
  FRelativeJsonPointer := TBaseRegistryRelativeJsonPointer.Create(Self);
end;

destructor TRegistryVisitor.Destroy;
begin
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
  // Apenas objetos e booleanos são schemas válidos para percorrer.
    if Assigned(AJsonValue) and ((AJsonValue is TJSONObject) or (AJsonValue is TJSONBool)) then
      TWalker<TRegistryVisitor>.Create(AJsonValue, Self).Walk;
  finally
    PopScope;
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

end;

procedure TBaseRegistryApplicatorVisitor.VisitAdditionalProperties(const AValue: TJSONValue);
begin

end;

procedure TBaseRegistryApplicatorVisitor.VisitAllOf(const AValue: TJSONArray);
begin

end;

procedure TBaseRegistryApplicatorVisitor.VisitAnyOf(const AValue: TJSONArray);
begin

end;

procedure TBaseRegistryApplicatorVisitor.VisitElse(const AValue: TJSONValue);
begin

end;

procedure TBaseRegistryApplicatorVisitor.VisitIf(const AValue: TJSONValue);
begin

end;

procedure TBaseRegistryApplicatorVisitor.VisitItems(const AValue: TJSONValue);
begin
  // A lógica de `items` pode ter um schema (objeto) ou um array de schemas.
  if AValue is TJSONObject then
    Visitor.DiscoverInSingleSchema(AValue)
  else if AValue is TJSONArray then
    Visitor.DiscoverInArrayOfSchemas(AValue as TJSONArray);
end;

procedure TBaseRegistryApplicatorVisitor.VisitNot(const AValue: TJSONValue);
begin

end;

procedure TBaseRegistryApplicatorVisitor.VisitOneOf(const AValue: TJSONArray);
begin

end;

procedure TBaseRegistryApplicatorVisitor.VisitPatternProperties(const AValue: TJSONObject);
begin

end;

procedure TBaseRegistryApplicatorVisitor.VisitPrefixItems(const AValue: TJSONArray);
begin

end;

procedure TBaseRegistryApplicatorVisitor.VisitProperties(const AValue: TJSONObject);
begin
  // A lógica é idêntica a VisitDefinitions: percorrer os valores do objeto.
  Visitor.DiscoverInObjectOfSchemas(AValue);
end;

procedure TBaseRegistryApplicatorVisitor.VisitThen(const AValue: TJSONValue);
begin

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
begin
  LScope := Visitor.FScopeStack.Peek;

  // Resolve a nova URI contra a base atual.
  LNewBaseURI := TURIReference.From(AValue.Value).ResolveWith(TURIReference.From(LScope.BaseURI));
  LScope.BaseURI := LNewBaseURI.Unsplit;

  // Atualiza o escopo na pilha ANTES de continuar a recursão.
  Visitor.FScopeStack.List[Visitor.FScopeStack.Count - 1] := LScope;

  // Se o recurso já não existe, adiciona-o.
  if not Visitor.FResources.ContainsKey(LScope.BaseURI) then
    Visitor.FResources.Add(LScope.BaseURI, TResource.Create(LNewBaseURI, LScope.SchemaNode));

  // Marca a palavra-chave como visitada para que o Walker não a processe duas vezes
  // se a precedência for usada.
  Visitor.AddVisitedKeyword('$id');
end;

procedure TBaseRegistryCoreVisitor.VisitRef(const AValue: TJSONString);
var
  LScope: TScope;
  LTargetURI: TURIReference;
  LResourceURI: string;
begin
  LScope := Visitor.CurrentScope;
  LTargetURI := TURIReference.From(AValue.Value).ResolveWith(TURIReference.From(LScope.BaseURI));
  LResourceURI := TURIUtils.NormalizeURI(LTargetURI.Unsplit);

  // Se o recurso referenciado ainda não está no registro, e é "buscável" (ex: http),
  // o registro tentará carregá-lo.
  if not Visitor.FResources.ContainsKey(LResourceURI) then
  begin
    // A implementação de TryLoadResource dentro do Registry lidaria com o fetch HTTP
    // e chamaria RegisterRootSchema novamente, populando o registro de forma recursiva.
    //Visitor.TryLoadResource(LResourceURI);
  end;
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
