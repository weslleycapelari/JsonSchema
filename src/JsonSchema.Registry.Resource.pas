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

    function ResolveFragment(const AFragment: string): TJSONValue; overload;
    function ResolveFragment(const AFragment: string; out AResolvedBaseURI: string): TJSONValue; overload;

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
  LResolvedBaseURI: string;
begin
  Result := ResolveFragment(AFragment, LResolvedBaseURI);
end;

function TResource.ResolveFragment(const AFragment: string; out AResolvedBaseURI: string): TJSONValue;
var
  LSegments: TArray<string>;
  LSegment: string;
  LDecodedSegment: string;
  LCurrentNode: TJSONValue;
  LIndex: Integer;
  LDecodedId: string;
  LLegacyId: string;
  LCount: Integer;
  LPointerPath: string;
begin
  AResolvedBaseURI := FBaseURI.Unsplit;

  // Caso 1: Fragmento vazio ou raiz, retorna o schema inteiro do recurso.
  if AFragment.IsEmpty then
    Exit(FRootSchema);

  LPointerPath := AFragment;

  // Decodifica a string do fragmento antes de interpret�-la
  LPointerPath := TNetEncoding.URL.Decode(LPointerPath);

  if LPointerPath.StartsWith('#') then
    LPointerPath := LPointerPath.Substring(1);

  // Caso 2: Fragmento � um JSON Pointer.
  if LPointerPath.StartsWith('/') then
  begin
    LCurrentNode := FRootSchema;
    LSegments := LPointerPath.Substring(1).Split(['/']);

    for LSegment in LSegments do
    begin
      if not Assigned(LCurrentNode) then
        Exit(nil);

      if (LCurrentNode is TJSONObject) and
         TJSONObject(LCurrentNode).TryGetValue<string>('$id', LDecodedId) and
         (LDecodedId <> '') then
      begin
        AResolvedBaseURI := TURIReference.From(LDecodedId).ResolveWith(TURIReference.From(AResolvedBaseURI)).Unsplit;
      end;

      if (LCurrentNode is TJSONObject) and
         TJSONObject(LCurrentNode).TryGetValue<string>('id', LLegacyId) and
         (LLegacyId <> '') then
      begin
        AResolvedBaseURI := TURIReference.From(LLegacyId).ResolveWith(TURIReference.From(AResolvedBaseURI)).Unsplit;
      end;

      LDecodedSegment := '';
      LCount := 1;
      while LCount <= Length(LSegment) do
      begin
        if LSegment[LCount] = '~' then
        begin
          if LCount = Length(LSegment) then
            Exit(nil);

          case LSegment[LCount + 1] of
            '0': LDecodedSegment := LDecodedSegment + '~';
            '1': LDecodedSegment := LDecodedSegment + '/';
          else
            Exit(nil);
          end;
          Inc(LCount, 2);
        end
        else
        begin
          LDecodedSegment := LDecodedSegment + LSegment[LCount];
          Inc(LCount);
        end;
      end;

      if LCurrentNode is TJSONObject then
        LCurrentNode := TJSONObject(LCurrentNode).GetValue(LDecodedSegment)
      else if LCurrentNode is TJSONArray then
      begin
        if TryStrToInt(LDecodedSegment, LIndex) and
           (LIndex >= 0) and
           (LIndex < TJSONArray(LCurrentNode).Count) then
          LCurrentNode := TJSONArray(LCurrentNode).Items[LIndex]
        else
          Exit(nil);
      end
      else
        Exit(nil);
    end;

    Result := LCurrentNode;
    Exit;
  end
  // Caso 3: Fragmento � uma �ncora de nome simples.
  else
  begin
    FAnchors.TryGetValue(LPointerPath, Result);
    if not Assigned(Result) then
      FAnchors.TryGetValue(FBaseURI.Unsplit + '#' + LPointerPath, Result);
    // Se n�o encontrou em �ncoras normais, tente as din�micas (para o caso de $ref as usar)
    if not Assigned(Result) then
      FDynamicAnchors.TryGetValue(LPointerPath, Result);
    Exit;
  end;

  // Se o fragmento n�o come�ar com '#', � inv�lido neste contexto.
  Result := nil;
end;

end.
