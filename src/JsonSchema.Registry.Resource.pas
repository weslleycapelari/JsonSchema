unit JsonSchema.Registry.Resource;

interface

uses
  System.JSON,
  System.Generics.Collections,
  JsonSchema.Registry.Uri;

type
  TResource = class
  private
    FBaseURI: TURIReference;
    FAnchors: TDictionary<string, TJSONValue>;
    FRootSchema: TJSONValue;
    FDynamicAnchors: TDictionary<string, TJSONValue>;
  public
    constructor Create(const pBaseURI: TURIReference; const pSchema: TJSONValue);
    destructor Destroy; override;

    procedure AddAnchor(const pAnchor: string; const pSchemaNode: TJSONValue);
    procedure AddDynamicAnchor(const pAnchor: string; const pSchemaNode: TJSONValue);

    function ResolveFragment(const pFragment: string): TJSONValue; overload;
    function ResolveFragment(const pFragment: string; out pResolvedBaseURI: string): TJSONValue; overload;

    property BaseURI: TURIReference read FBaseURI;
  end;

implementation

uses
  System.SysUtils,
  System.NetEncoding,
  JsonSchema.Registry.Utils;

{ TResource }

procedure TResource.AddAnchor(const pAnchor: string; const pSchemaNode: TJSONValue);
begin
  FAnchors.AddOrSetValue(pAnchor, pSchemaNode);
end;

procedure TResource.AddDynamicAnchor(const pAnchor: string; const pSchemaNode: TJSONValue);
begin
  FDynamicAnchors.AddOrSetValue(pAnchor, pSchemaNode);
end;

constructor TResource.Create(const pBaseURI: TURIReference; const pSchema: TJSONValue);
begin
  FBaseURI        := pBaseURI;
  FAnchors        := TDictionary<string, TJSONValue>.Create;
  FRootSchema     := pSchema;
  FDynamicAnchors := TDictionary<string, TJSONValue>.Create;
end;

destructor TResource.Destroy;
begin
  FAnchors.Free;
  FDynamicAnchors.Free;
  inherited;
end;

function TResource.ResolveFragment(const pFragment: string): TJSONValue;
var
  lResolvedBaseURI: string;
begin
  Result := ResolveFragment(pFragment, lResolvedBaseURI);
end;

function TResource.ResolveFragment(const pFragment: string; out pResolvedBaseURI: string): TJSONValue;
var
  lSegments: TArray<string>;
  lSegment: string;
  lDecodedSegment: string;
  lCurrentNode: TJSONValue;
  lIndex: Integer;
  lDecodedId: string;
  lLegacyId: string;
  lCount: Integer;
  lPointerPath: string;
begin
  pResolvedBaseURI := FBaseURI.Unsplit;

  // Caso 1: Fragmento vazio ou raiz, retorna o schema inteiro do recurso.
  if pFragment.IsEmpty then
    Exit(FRootSchema);

  lPointerPath := pFragment;

  // Decodifica a string do fragmento antes de interpret�-la
  lPointerPath := TNetEncoding.URL.Decode(lPointerPath);

  if lPointerPath.StartsWith('#') then
    lPointerPath := lPointerPath.Substring(1);

  // Caso 2: Fragmento � um JSON Pointer.
  if lPointerPath.StartsWith('/') then
  begin
    lCurrentNode := FRootSchema;
    lSegments := lPointerPath.Substring(1).Split(['/']);

    for lSegment in lSegments do
    begin
      if not Assigned(lCurrentNode) then
        Exit(nil);

      if (lCurrentNode is TJSONObject) and
         TJSONObject(lCurrentNode).TryGetValue<string>('$id', lDecodedId) and
         (lDecodedId <> '') then
      begin
        pResolvedBaseURI := TURIReference.From(lDecodedId).ResolveWith(TURIReference.From(pResolvedBaseURI)).Unsplit;
      end;

      if (lCurrentNode is TJSONObject) and
         TJSONObject(lCurrentNode).TryGetValue<string>('id', lLegacyId) and
         (lLegacyId <> '') then
      begin
        pResolvedBaseURI := TURIReference.From(lLegacyId).ResolveWith(TURIReference.From(pResolvedBaseURI)).Unsplit;
      end;

      lDecodedSegment := '';
      lCount := 1;
      while lCount <= Length(lSegment) do
      begin
        if lSegment[lCount] = '~' then
        begin
          if lCount = Length(lSegment) then
            Exit(nil);

          case lSegment[lCount + 1] of
            '0': lDecodedSegment := lDecodedSegment + '~';
            '1': lDecodedSegment := lDecodedSegment + '/';
          else
            Exit(nil);
          end;
          Inc(lCount, 2);
        end
        else
        begin
          lDecodedSegment := lDecodedSegment + lSegment[lCount];
          Inc(lCount);
        end;
      end;

      if lCurrentNode is TJSONObject then
        lCurrentNode := TJSONObject(lCurrentNode).GetValue(lDecodedSegment)
      else if lCurrentNode is TJSONArray then
      begin
        if TryStrToInt(lDecodedSegment, lIndex) and
           (lIndex >= 0) and
           (lIndex < TJSONArray(lCurrentNode).Count) then
          lCurrentNode := TJSONArray(lCurrentNode).Items[lIndex]
        else
          Exit(nil);
      end
      else
        Exit(nil);
    end;

    Result := lCurrentNode;
    Exit;
  end
  // Caso 3: Fragmento � uma �ncora de nome simples.
  else
  begin
    FAnchors.TryGetValue(lPointerPath, Result);
    if not Assigned(Result) then
      FAnchors.TryGetValue(FBaseURI.Unsplit + '#' + lPointerPath, Result);
    // Se n�o encontrou em �ncoras normais, tente as din�micas (para o caso de $ref as usar)
    if not Assigned(Result) then
      FDynamicAnchors.TryGetValue(lPointerPath, Result);
    Exit;
  end;

  // Se o fragmento n�o come�ar com '#', � inv�lido neste contexto.
  Result := nil;
end;

end.
