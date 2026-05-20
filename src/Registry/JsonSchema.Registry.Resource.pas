unit JsonSchema.Registry.Resource;

interface

uses
  System.JSON,
  System.Generics.Collections,
  JsonSchema.Registry.Uri,
  JsonSchema.Registry.Utils;

type
  /// <summary>
  ///   Represents a single JSON Schema resource identified by a base URI.
  ///   Holds the root schema node and all anchors discovered during registry population.
  /// </summary>
  TResource = class
  private
    FBaseURI: TURIReference;
    FAnchors: TDictionary<string, TJSONValue>;
    FDynamicAnchors: TDictionary<string, TJSONValue>;
    FRootSchema: TJSONValue;
  public
    /// <summary>Initializes a new resource with the given base URI and root schema node.</summary>
    constructor Create(const pBaseURI: TURIReference; const pSchema: TJSONValue);
    destructor Destroy; override;

    /// <summary>Registers a named anchor pointing to a schema sub-node.</summary>
    procedure AddAnchor(const pAnchor: string; const pSchemaNode: TJSONValue);

    /// <summary>Registers a dynamic anchor pointing to a schema sub-node.</summary>
    procedure AddDynamicAnchor(const pAnchor: string; const pSchemaNode: TJSONValue);

    /// <summary>
    ///   Resolves a URI fragment to a schema node within this resource.
    ///   Supports empty (root), JSON Pointer (/...) and named anchor formats.
    /// </summary>
    function ResolveFragment(const pFragment: string): TJSONValue; overload;

    /// <summary>
    ///   Resolves a URI fragment to a schema node within this resource and
    ///   returns the effective base URI at the resolved node via pResolvedBaseURI.
    /// </summary>
    function ResolveFragment(const pFragment: string; out pResolvedBaseURI: string): TJSONValue; overload;

    property BaseURI: TURIReference read FBaseURI;
  end;

implementation

uses
  System.SysUtils,
  System.NetEncoding,
  JsonSchema.Common.Utils;

{ TResource }

constructor TResource.Create(const pBaseURI: TURIReference; const pSchema: TJSONValue);
begin
  inherited Create;
  FBaseURI := pBaseURI;
  FRootSchema := pSchema;
  FAnchors := TDictionary<string, TJSONValue>.Create;
  FDynamicAnchors := TDictionary<string, TJSONValue>.Create;
end;

destructor TResource.Destroy;
begin
  FAnchors.Free;
  FDynamicAnchors.Free;
  inherited;
end;

procedure TResource.AddAnchor(const pAnchor: string; const pSchemaNode: TJSONValue);
begin
  FAnchors.AddOrSetValue(pAnchor, pSchemaNode);
end;

procedure TResource.AddDynamicAnchor(const pAnchor: string; const pSchemaNode: TJSONValue);
begin
  FDynamicAnchors.AddOrSetValue(pAnchor, pSchemaNode);
end;

function TResource.ResolveFragment(const pFragment: string): TJSONValue;
var
  lResolvedBaseURI: string;
begin
  Result := ResolveFragment(pFragment, lResolvedBaseURI);
end;

function TResource.ResolveFragment(const pFragment: string; out pResolvedBaseURI: string): TJSONValue;
var
  lPointerPath: string;
  lSegments: TArray<string>;
  lSegment: string;
  lDecodedSegment: string;
  lCurrentNode: TJSONValue;
  lIndex: Integer;
  lDecodedId: string;
  lLegacyId: string;
begin
  pResolvedBaseURI := FBaseURI.Unsplit;

  // Case 1: empty fragment or root — return the entire resource schema
  if pFragment.IsEmpty then
    Exit(FRootSchema);

  lPointerPath := TNetEncoding.URL.Decode(pFragment);
  if lPointerPath.StartsWith('#') then
    lPointerPath := lPointerPath.Substring(1);

  // Case 2: JSON Pointer fragment (starts with '/')
  if lPointerPath.StartsWith('/') then
  begin
    lCurrentNode := FRootSchema;
    lSegments := lPointerPath.Substring(1).Split(['/']);

    for lSegment in lSegments do
    begin
      if not Assigned(lCurrentNode) then
        Exit(nil);

      // Update base URI if $id or id is present at this node
      if (lCurrentNode is TJSONObject) then
      begin
        if TJSONObject(lCurrentNode).TryGetValue<string>('$id', lDecodedId) and (lDecodedId <> '') then
          pResolvedBaseURI := TURIReference.From(lDecodedId).ResolveWith(TURIReference.From(pResolvedBaseURI)).Unsplit;

        if TJSONObject(lCurrentNode).TryGetValue<string>('id', lLegacyId) and (lLegacyId <> '') then
          pResolvedBaseURI := TURIReference.From(lLegacyId).ResolveWith(TURIReference.From(pResolvedBaseURI)).Unsplit;
      end;

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

  // Case 3: named anchor fragment
  if FAnchors.TryGetValue(lPointerPath, Result) then
    Exit;

  if FAnchors.TryGetValue(FBaseURI.Unsplit + '#' + lPointerPath, Result) then
    Exit;

  if FDynamicAnchors.TryGetValue(lPointerPath, Result) then
    Exit;

  Result := nil;
end;

end.
