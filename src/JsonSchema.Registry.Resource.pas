unit JsonSchema.Registry.Resource;

interface

uses
  System.JSON,
  System.Generics.Collections,
  JsonSchema.Registry.Uri;

type
  TResource = record
  private
    FBaseURI: TURIReference;
    FAnchors: TDictionary<string, TJSONValue>;
    FRootSchema: TJSONValue;
    FDynamicAnchors: TDictionary<string, TJSONValue>;
  public
    constructor Create(const ABaseURI: TURIReference; const ASchema: TJSONValue);

    procedure AddAnchor(const AAnchor: string; const ASchemaNode: TJSONValue);
    procedure AddDynamicAnchor(const AAnchor: string; const ASchemaNode: TJSONValue);

    function ResolveFragment(const AFragment: string): TJSONValue;

    property BaseURI: TURIReference read FBaseURI;
  end;

implementation

uses
  System.SysUtils,
  System.NetEncoding,
  JsonSchema.Registry.Utils;

{ TResource }

procedure TResource.AddAnchor(const AAnchor: string; const ASchemaNode: TJSONValue);
begin
  FAnchors.AddOrSetValue(AAnchor, ASchemaNode);
end;

procedure TResource.AddDynamicAnchor(const AAnchor: string; const ASchemaNode: TJSONValue);
begin
  FDynamicAnchors.AddOrSetValue(AAnchor, ASchemaNode);
end;

constructor TResource.Create(const ABaseURI: TURIReference; const ASchema: TJSONValue);
begin
  FBaseURI        := ABaseURI;
  FAnchors        := TDictionary<string, TJSONValue>.Create;
  FRootSchema     := ASchema;
  FDynamicAnchors := TDictionary<string, TJSONValue>.Create;
end;

function TResource.ResolveFragment(const AFragment: string): TJSONValue;
var
  LPointerPath: string;
begin
  // Caso 1: Fragmento vazio ou raiz, retorna o schema inteiro do recurso.
  if AFragment.IsEmpty then
    Exit(FRootSchema);

  LPointerPath := AFragment;

  // Decodifica a string do fragmento antes de interpretá-la
  LPointerPath := TNetEncoding.URL.Decode(LPointerPath);

  // Caso 2: Fragmento é um JSON Pointer.
  if AFragment.StartsWith('/') then
  begin
    // Delega a avaliação para a nossa função utilitária.
    Result := TURIUtils.EvaluateJsonPointer(FRootSchema, LPointerPath);
    Exit;
  end
  // Caso 3: Fragmento é uma âncora de nome simples.
  else
  begin
    // Remove o '#' inicial e busca no dicionário de âncoras.
    FAnchors.TryGetValue(LPointerPath, Result);
    // Se não encontrou em âncoras normais, tente as dinâmicas (para o caso de $ref as usar)
    if not Assigned(Result) then
      FDynamicAnchors.TryGetValue(LPointerPath, Result);
    Exit;
  end;

  // Se o fragmento não começar com '#', é inválido neste contexto.
  Result := nil;
end;

end.
