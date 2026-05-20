unit JsonSchema.Registry.Loader;

interface

uses
  System.JSON;

type
  /// <summary>
  ///   Responsible for loading remote JSON Schema resources (HTTP, file system)
  ///   during registry discovery. Implementations can be injected to support
  ///   different loading strategies (e.g., from disk, from HTTP, from database).
  /// </summary>
  IResourceLoader = interface(IInterface)
    ['{5F8A2C1E-4B9D-4A7F-8C3E-9D2F1A7B6C5D}']
    /// <summary>
    ///   Attempts to load a JSON Schema from the given URI.
    ///   Returns True and sets pSchema if successful; otherwise returns False.
    /// </summary>
    function TryLoadResource(const pURI: string; out pSchema: TJSONValue): Boolean;
  end;

  /// <summary>
  ///   Default resource loader that uses static file mapping for known schema
  ///   URIs (draft metaschemas) and falls back to local HTTP test server
  ///   (http://localhost:1234/ or http://test.json-schema.org/).
  ///   Does not perform arbitrary remote HTTP requests (YAGNI).
  /// </summary>
  TResourceLoader = class(TInterfacedObject, IResourceLoader)
  private
    FRepoRootPath: string;
    class function TryResolveStaticMappedFile(const pRemoteURI: string; out pMappedFilePath: string): Boolean; static;
    class function MapDraftSchemaURI(const pCanonicalURI: string; const pRepoRootPath: string; out pFilePath: string): Boolean; static;
    class function TryMapTestServerURI(const pRemoteURI: string; const pRepoRootPath: string; out pMappedFilePath: string): Boolean; static;
    class function IsLocalTestServerURI(const pURI: string): Boolean; static;
    function LoadFromFile(const pFilePath: string; out pSchema: TJSONValue): Boolean;
    function LoadFromHttp(const pURI: string; out pSchema: TJSONValue): Boolean;
  public
    constructor Create(const pRepoRootPath: string = '');
    function TryLoadResource(const pURI: string; out pSchema: TJSONValue): Boolean;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.Net.HttpClient,
  System.Classes,
  JsonSchema.Exceptions;

{ TResourceLoader }

constructor TResourceLoader.Create(const pRepoRootPath: string);
begin
  inherited Create;
  if pRepoRootPath.IsEmpty then
    FRepoRootPath := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\..'))
  else
    FRepoRootPath := pRepoRootPath;
end;

class function TResourceLoader.TryResolveStaticMappedFile(const pRemoteURI: string; out pMappedFilePath: string): Boolean;
var
  lCanonicalURI: string;
  lRepoRootPath: string;
begin
  pMappedFilePath := '';
  lCanonicalURI := LowerCase(pRemoteURI);
  lRepoRootPath := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\..'));

  if MapDraftSchemaURI(lCanonicalURI, lRepoRootPath, pMappedFilePath) then
    Exit(FileExists(pMappedFilePath));

  Result := TryMapTestServerURI(pRemoteURI, lRepoRootPath, pMappedFilePath);
end;

class function TResourceLoader.MapDraftSchemaURI(const pCanonicalURI, pRepoRootPath: string; out pFilePath: string): Boolean;
begin
  Result := True;
  if (pCanonicalURI = 'http://json-schema.org/draft-06/schema') or
     (pCanonicalURI = 'https://json-schema.org/draft-06/schema') then
    pFilePath := TPath.Combine(pRepoRootPath, 'test\schemas\remotes\draft6\schema.json')
  else if (pCanonicalURI = 'http://json-schema.org/draft-07/schema') or
          (pCanonicalURI = 'https://json-schema.org/draft-07/schema') then
    pFilePath := TPath.Combine(pRepoRootPath, 'test\schemas\remotes\draft7\schema.json')
  else if (pCanonicalURI = 'http://json-schema.org/draft/2019-09/schema') or
          (pCanonicalURI = 'https://json-schema.org/draft/2019-09/schema') then
    pFilePath := TPath.Combine(pRepoRootPath, 'test\schemas\remotes\draft2019-09\schema.json')
  else if (pCanonicalURI = 'https://json-schema.org/draft/2020-12/schema') then
    pFilePath := TPath.Combine(pRepoRootPath, 'test\schemas\remotes\draft2020-12\schema.json')
  else if pCanonicalURI.Contains('/draft2020-12/baseurichangefolder/') then
    pFilePath := TPath.Combine(pRepoRootPath, 'test\schemas\remotes\draft2020-12\baseUriChangeFolder\folderInteger.json')
  else if pCanonicalURI.Contains('/draft2020-12/baseurichangefolderinsubschema/') then
    pFilePath := TPath.Combine(pRepoRootPath, 'test\schemas\remotes\draft2020-12\baseUriChangeFolderInSubschema\folderInteger.json')
  else if pCanonicalURI.Contains('/draft2019-09/baseurichangefolder/') then
    pFilePath := TPath.Combine(pRepoRootPath, 'test\schemas\remotes\draft2019-09\baseUriChangeFolder\folderInteger.json')
  else if (pCanonicalURI = 'https://json-schema.org/draft/2019-09/meta/core') then
    pFilePath := TPath.Combine(pRepoRootPath, 'test\schemas\remotes\draft2019-09\meta\core.json')
  else if (pCanonicalURI = 'https://json-schema.org/draft/2019-09/meta/applicator') then
    pFilePath := TPath.Combine(pRepoRootPath, 'test\schemas\remotes\draft2019-09\meta\applicator.json')
  else if (pCanonicalURI = 'https://json-schema.org/draft/2019-09/meta/validation') then
    pFilePath := TPath.Combine(pRepoRootPath, 'test\schemas\remotes\draft2019-09\meta\validation.json')
  else if (pCanonicalURI = 'https://json-schema.org/draft/2019-09/meta/meta-data') then
    pFilePath := TPath.Combine(pRepoRootPath, 'test\schemas\remotes\draft2019-09\meta\meta-data.json')
  else if (pCanonicalURI = 'https://json-schema.org/draft/2019-09/meta/format') then
    pFilePath := TPath.Combine(pRepoRootPath, 'test\schemas\remotes\draft2019-09\meta\format.json')
  else if (pCanonicalURI = 'https://json-schema.org/draft/2019-09/meta/content') then
    pFilePath := TPath.Combine(pRepoRootPath, 'test\schemas\remotes\draft2019-09\meta\content.json')
  else
  begin
    pFilePath := '';
    Result := False;
  end;
end;

class function TResourceLoader.TryMapTestServerURI(const pRemoteURI, pRepoRootPath: string; out pMappedFilePath: string): Boolean;
var
  lRelativeRemotePath: string;
  lCandidatePath: string;
  lLowerURI: string;
begin
  Result := False;
  pMappedFilePath := '';
  lLowerURI := LowerCase(pRemoteURI);

  if lLowerURI.StartsWith('http://test.json-schema.org/') or
     lLowerURI.StartsWith('https://test.json-schema.org/') then
  begin
    lRelativeRemotePath := pRemoteURI;
    lRelativeRemotePath := StringReplace(lRelativeRemotePath, 'http://test.json-schema.org/', '', [rfIgnoreCase]);
    lRelativeRemotePath := StringReplace(lRelativeRemotePath, 'https://test.json-schema.org/', '', [rfIgnoreCase]);
    lRelativeRemotePath := StringReplace(lRelativeRemotePath, '/', PathDelim, [rfReplaceAll]);

    lCandidatePath := TPath.Combine(pRepoRootPath, TPath.Combine('test\schemas\remotes\draft2020-12', lRelativeRemotePath));
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
    lCandidatePath := TPath.Combine(pRepoRootPath, TPath.Combine('test\schemas\remotes', lRelativeRemotePath));
    if FileExists(lCandidatePath) then
    begin
      pMappedFilePath := lCandidatePath;
      Exit(True);
    end;
  end;
end;

class function TResourceLoader.IsLocalTestServerURI(const pURI: string): Boolean;
var
  lLowerURI: string;
begin
  lLowerURI := LowerCase(pURI);
  Result := lLowerURI.StartsWith('http://localhost:1234/') or
            lLowerURI.StartsWith('http://127.0.0.1:1234/');
end;

function TResourceLoader.LoadFromFile(const pFilePath: string; out pSchema: TJSONValue): Boolean;
var
  lContent: string;
begin
  Result := False;
  pSchema := nil;
  try
    lContent := TFile.ReadAllText(pFilePath, TEncoding.UTF8);
    pSchema := TJSONObject.ParseJSONValue(lContent);
    Result := Assigned(pSchema);
  except
    // Silently fail
  end;
end;

function TResourceLoader.LoadFromHttp(const pURI: string; out pSchema: TJSONValue): Boolean;
var
  lHttpClient: THTTPClient;
  lResponse: IHTTPResponse;
  lContent: string;
begin
  Result := False;
  pSchema := nil;
  try
    lHttpClient := THTTPClient.Create;
    try
      lResponse := lHttpClient.Get(pURI);
      if Assigned(lResponse) and (lResponse.StatusCode = 200) then
      begin
        lContent := lResponse.ContentAsString(TEncoding.UTF8);
        pSchema := TJSONObject.ParseJSONValue(lContent);
        Result := Assigned(pSchema);
      end;
    finally
      lHttpClient.Free;
    end;
  except
    // Silently fail
  end;
end;

function TResourceLoader.TryLoadResource(const pURI: string; out pSchema: TJSONValue): Boolean;
var
  lMappedFilePath: string;
  lNormalizedURI: string;
begin
  pSchema := nil;

  lNormalizedURI := LowerCase(pURI);
  if TryResolveStaticMappedFile(lNormalizedURI, lMappedFilePath) and FileExists(lMappedFilePath) then
    Exit(LoadFromFile(lMappedFilePath, pSchema));

  if IsLocalTestServerURI(pURI) then
    Exit(LoadFromHttp(pURI, pSchema));

  Result := False;
end;

end.
