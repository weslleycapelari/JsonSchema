unit JsonSchema.Registry.Resource;

interface

uses
  System.JSON,
  System.Generics.Collections,
  JsonSchema.Registry.Uri;

type
  /// <summary>
  /// Represents a single JSON Schema resource identified by a base URI.
  /// Holds the root schema node and all anchors discovered during registry population.
  /// </summary>
  TResource = class
  private
    FBaseURI: TURIReference;
    FAnchors: TDictionary<string, TJSONValue>;
    FRootSchema: TJSONValue;
    FDynamicAnchors: TDictionary<string, TJSONValue>;
  public
    /// <summary>Initializes a new resource with the given base URI and root schema node.</summary>
    constructor Create(const pBaseURI: TURIReference; const pSchema: TJSONValue);
    destructor Destroy; override;

    /// <summary>Registers a named anchor pointing to a schema sub-node.</summary>
    procedure AddAnchor(const pAnchor: string; const pSchemaNode: TJSONValue);
    /// <summary>Registers a dynamic anchor pointing to a schema sub-node.</summary>
    procedure AddDynamicAnchor(const pAnchor: string; const pSchemaNode: TJSONValue);

    /// <summary>
    /// Resolves a URI fragment to a schema node within this resource.
    /// Supports empty (root), JSON Pointer (/...) and named anchor formats.
    /// </summary>
    function ResolveFragment(const pFragment: string): TJSONValue; overload;
    /// <summary>
    /// Resolves a URI fragment to a schema node within this resource and
    /// returns the effective base URI at the resolved node via pResolvedBaseURI.
    /// </summary>
    /// <param name="pFragment">The URI fragment to resolve.</param>
    /// <param name="pResolvedBaseURI">Receives the base URI of the resolved node.</param>
    /// <returns>The resolved JSON schema node, or nil if the fragment is not found.</returns>
    function ResolveFragment(const pFragment: string; out pResolvedBaseURI: string): TJSONValue; overload;

    property BaseURI: TURIReference read FBaseURI;
  end;

implementation

uses
  System.SysUtils,
  System.NetEncoding,
  JsonSchema.Common.Utils,
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
  lPointerPath: string;
begin
  pResolvedBaseURI := FBaseURI.Unsplit;

  // Case 1: empty fragment or root — return the entire resource schema.
  if pFragment.IsEmpty then
    Exit(FRootSchema);

  lPointerPath := TNetEncoding.URL.Decode(pFragment);

  if lPointerPath.StartsWith('#') then
    lPointerPath := lPointerPath.Substring(1);

  // Case 2: JSON Pointer fragment.
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
        pResolvedBaseURI := TURIReference.From(lDecodedId).ResolveWith(TURIReference.From(pResolvedBaseURI)).Unsplit;

      if (lCurrentNode is TJSONObject) and
         TJSONObject(lCurrentNode).TryGetValue<string>('id', lLegacyId) and
         (lLegacyId <> '') then
        pResolvedBaseURI := TURIReference.From(lLegacyId).ResolveWith(TURIReference.From(pResolvedBaseURI)).Unsplit;

      if not TUtils.DecodeJsonPointerSegment(lSegment, lDecodedSegment) then
        Exit(nil);

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
  end;

  // Case 3: named anchor fragment.
  FAnchors.TryGetValue(lPointerPath, Result);
  if not Assigned(Result) then
    FAnchors.TryGetValue(FBaseURI.Unsplit + '#' + lPointerPath, Result);
  if not Assigned(Result) then
    FDynamicAnchors.TryGetValue(lPointerPath, Result);
end;

end.
