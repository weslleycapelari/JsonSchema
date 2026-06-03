unit JsonSchema.Core.SchemaRegistry;

(*
--------------------------------------------------------------------------------
Provides a central schema registry to store, resolve, and load schema documents by URI.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  System.Generics.Collections,
  System.SysUtils,
  System.IOUtils;

type
  /// <summary>Registry class caching compiled and raw schemas by their absolute URIs.</summary>
  TSchemaRegistry = class
  strict private
    class var FRegistry: TDictionary<string, TJSONValue>;
    class var FRoots: TList<TJSONValue>;
    class var FCurrentBaseURI: string;
    class var FCurrentRootSchema: TJSONObject;
    class constructor Create;
    class destructor Destroy;
    class function FetchSchemaFromLocalOrHttp(const pURI: string): TJSONValue; static;
  public
    /// <summary>Registers a schema document under a specific URI.</summary>
    class procedure RegisterSchema(const pURI: string; const pSchema: TJSONValue); static;

    /// <summary>Attempts to find a registered schema by its URI. Fetches dynamically if needed.</summary>
    class function FindSchema(const pURI: string; out pSchema: TJSONValue): Boolean; static;

    /// <summary>Clears all cached schemas from the registry.</summary>
    class procedure Clear; static;

    /// <summary>Combines base and relative URIs following standard reference routing.</summary>
    class function CombineURI(const pBase, pRelative: string): string; static;

    /// <summary>Pre-scans a schema recursively to find all internal identifiers and anchors.</summary>
    class procedure PreScanSchema(const pURI: string; const pSchema: TJSONValue); static;

    /// <summary>Thread-local current base URI during schema compiling.</summary>
    class property CurrentBaseURI: string read FCurrentBaseURI write FCurrentBaseURI;

    /// <summary>Thread-local current root schema during schema compiling.</summary>
    class property CurrentRootSchema: TJSONObject read FCurrentRootSchema write FCurrentRootSchema;
  end;

implementation

uses
  System.Net.HttpClient;

{ TSchemaRegistry }

class constructor TSchemaRegistry.Create;
begin
  FRegistry := TDictionary<string, TJSONValue>.Create;
  FRoots := TList<TJSONValue>.Create;
end;

class destructor TSchemaRegistry.Destroy;
begin
  Clear;
  FRegistry.Free;
  FRoots.Free;
end;

class procedure TSchemaRegistry.Clear;
var
  lRoot: TJSONValue;
begin
  for lRoot in FRoots do
    lRoot.Free;

  FRoots.Clear;
  FRegistry.Clear;
end;

class function TSchemaRegistry.CombineURI(const pBase, pRelative: string): string;
var
  lLastSlash: Integer;
  lSlashIdx: Integer;
begin
  if pRelative.StartsWith('http://') or pRelative.StartsWith('https://') or pRelative.StartsWith('file://') then
  begin
    Result := pRelative;
  end else if pRelative.StartsWith('#') then
  begin
    lLastSlash := pBase.IndexOf('#');
    if lLastSlash >= 0 then
      Result := pBase.Substring(0, lLastSlash) + pRelative
    else
      Result := pBase + pRelative;
  end else if pRelative.StartsWith('/') and (not pRelative.StartsWith('//')) then
  begin
    // Absolute-path reference: resolves against the authority of pBase
    if pBase.StartsWith('http://') then
      lSlashIdx := pBase.IndexOf('/', Length('http://'))
    else if pBase.StartsWith('https://') then
      lSlashIdx := pBase.IndexOf('/', Length('https://'))
    else if pBase.StartsWith('file://') then
      lSlashIdx := pBase.IndexOf('/', Length('file://'))
    else
      lSlashIdx := -1;

    if lSlashIdx >= 0 then
      Result := pBase.Substring(0, lSlashIdx) + pRelative
    else
      Result := pBase + pRelative;
  end else
  begin
    lLastSlash := pBase.LastIndexOf('/');
    if lLastSlash >= 0 then
      Result := pBase.Substring(0, lLastSlash + 1) + pRelative
    else
      Result := pRelative;
  end;
end;

class procedure TSchemaRegistry.PreScanSchema(const pURI: string; const pSchema: TJSONValue);
  procedure RecurseSchema(const pSchemaVal: TJSONValue; const pCurrentBase: string);
  var
    lObj: TJSONObject;
    lNewBase: string;
    lIdStr: string;
    lAnchorStr: string;
    lPair: TJSONPair;
    lMapPair: TJSONPair;
    lSubVal: TJSONValue;
    lItem: TJSONValue;
  begin
    if not Assigned(pSchemaVal) then
      Exit;

    lNewBase := pCurrentBase;

    if pSchemaVal is TJSONBool then
      Exit;

    if pSchemaVal is TJSONObject then
    begin
      lObj := TJSONObject(pSchemaVal);

      // Check for '$id'
      lPair := lObj.Get('$id');
      if Assigned(lPair) and (lPair.JsonValue is TJSONString) then
      begin
        lIdStr := lPair.JsonValue.Value;
        lNewBase := CombineURI(pCurrentBase, lIdStr);

        if not FRegistry.ContainsKey(lNewBase) then
          FRegistry.Add(lNewBase, lObj);

        if lIdStr.StartsWith('#') then
          lNewBase := pCurrentBase;
      end else
      begin
        // Check for legacy 'id'
        lPair := lObj.Get('id');
        if Assigned(lPair) and (lPair.JsonValue is TJSONString) then
        begin
          lIdStr := lPair.JsonValue.Value;
          lNewBase := CombineURI(pCurrentBase, lIdStr);

          if not FRegistry.ContainsKey(lNewBase) then
            FRegistry.Add(lNewBase, lObj);

          if lIdStr.StartsWith('#') then
            lNewBase := pCurrentBase;
        end;
      end;

      // Check for '$anchor'
      lPair := lObj.Get('$anchor');
      if Assigned(lPair) and (lPair.JsonValue is TJSONString) then
      begin
        lAnchorStr := lPair.JsonValue.Value;
        if not lAnchorStr.StartsWith('#') then
          lAnchorStr := '#' + lAnchorStr;

        if not FRegistry.ContainsKey(CombineURI(lNewBase, lAnchorStr)) then
          FRegistry.Add(CombineURI(lNewBase, lAnchorStr), lObj);
      end;

      // Recurse into subschemas using specific keywords

      // 1. Single subschemas
      lPair := lObj.Get('additionalItems');
      if Assigned(lPair) then
        RecurseSchema(lPair.JsonValue, lNewBase);

      lPair := lObj.Get('items');
      if Assigned(lPair) then
      begin
        lSubVal := lPair.JsonValue;
        if lSubVal is TJSONArray then
        begin
          for lItem in TJSONArray(lSubVal) do
            RecurseSchema(lItem, lNewBase);
        end else
          RecurseSchema(lSubVal, lNewBase);
      end;

      lPair := lObj.Get('contains');
      if Assigned(lPair) then
        RecurseSchema(lPair.JsonValue, lNewBase);

      lPair := lObj.Get('additionalProperties');
      if Assigned(lPair) then
        RecurseSchema(lPair.JsonValue, lNewBase);

      lPair := lObj.Get('propertyNames');
      if Assigned(lPair) then
        RecurseSchema(lPair.JsonValue, lNewBase);

      lPair := lObj.Get('not');
      if Assigned(lPair) then
        RecurseSchema(lPair.JsonValue, lNewBase);

      lPair := lObj.Get('if');
      if Assigned(lPair) then
        RecurseSchema(lPair.JsonValue, lNewBase);

      lPair := lObj.Get('then');
      if Assigned(lPair) then
        RecurseSchema(lPair.JsonValue, lNewBase);

      lPair := lObj.Get('else');
      if Assigned(lPair) then
        RecurseSchema(lPair.JsonValue, lNewBase);

      // 2. Arrays of subschemas
      lPair := lObj.Get('allOf');
      if Assigned(lPair) and (lPair.JsonValue is TJSONArray) then
      begin
        for lItem in TJSONArray(lPair.JsonValue) do
          RecurseSchema(lItem, lNewBase);
      end;

      lPair := lObj.Get('anyOf');
      if Assigned(lPair) and (lPair.JsonValue is TJSONArray) then
      begin
        for lItem in TJSONArray(lPair.JsonValue) do
          RecurseSchema(lItem, lNewBase);
      end;

      lPair := lObj.Get('oneOf');
      if Assigned(lPair) and (lPair.JsonValue is TJSONArray) then
      begin
        for lItem in TJSONArray(lPair.JsonValue) do
          RecurseSchema(lItem, lNewBase);
      end;

      // 3. Maps of subschemas
      lPair := lObj.Get('properties');
      if Assigned(lPair) and (lPair.JsonValue is TJSONObject) then
      begin
        for lMapPair in TJSONObject(lPair.JsonValue) do
          RecurseSchema(lMapPair.JsonValue, lNewBase);
      end;

      lPair := lObj.Get('patternProperties');
      if Assigned(lPair) and (lPair.JsonValue is TJSONObject) then
      begin
        for lMapPair in TJSONObject(lPair.JsonValue) do
          RecurseSchema(lMapPair.JsonValue, lNewBase);
      end;

      lPair := lObj.Get('dependencies');
      if Assigned(lPair) and (lPair.JsonValue is TJSONObject) then
      begin
        for lMapPair in TJSONObject(lPair.JsonValue) do
        begin
          lSubVal := lMapPair.JsonValue;
          if (lSubVal is TJSONObject) or (lSubVal is TJSONBool) then
            RecurseSchema(lSubVal, lNewBase);
        end;
      end;

      lPair := lObj.Get('definitions');
      if Assigned(lPair) and (lPair.JsonValue is TJSONObject) then
      begin
        for lMapPair in TJSONObject(lPair.JsonValue) do
          RecurseSchema(lMapPair.JsonValue, lNewBase);
      end;
    end;
  end;

begin
  RecurseSchema(pSchema, pURI);
end;

class function TSchemaRegistry.FetchSchemaFromLocalOrHttp(const pURI: string): TJSONValue;
var
  lPath: string;
  lExePath: string;
  lDocPath: string;
  lClient: THTTPClient;
  lResponse: IHTTPResponse;
begin
  Result := nil;

  // Map json-schema.org meta-schemas locally to draft folders
  if pURI.StartsWith('http://json-schema.org/') or pURI.StartsWith('https://json-schema.org/') then
  begin
    lDocPath := '';
    if pURI.Contains('/draft-06/schema') then
      lDocPath := 'draft6/schema.json'
    else if pURI.Contains('/draft-07/schema') then
      lDocPath := 'draft7/schema.json'
    else if pURI.Contains('/draft/2019-09/schema') then
      lDocPath := 'draft2019-09/schema.json'
    else if pURI.Contains('/draft/2020-12/schema') then
      lDocPath := 'draft2020-12/schema.json';

    if lDocPath <> '' then
    begin
      lExePath := ExtractFilePath(ParamStr(0));
      lPath := TPath.Combine(lExePath, 'schemas/remotes/' + lDocPath);

      if not FileExists(lPath) then
        lPath := TPath.Combine(lExePath, '../schemas/remotes/' + lDocPath);

      if not FileExists(lPath) then
        lPath := TPath.Combine(lExePath, '../../schemas/remotes/' + lDocPath);

      if not FileExists(lPath) then
        lPath := TPath.Combine(lExePath, '../../../schemas/remotes/' + lDocPath);

      if FileExists(lPath) then
      begin
        try
          Result := TJSONObject.ParseJSONValue(TFile.ReadAllText(lPath));
        except
          // Fallback on parse failure
        end;
      end;
    end;
  end;

  // Optimize test executions by loading remotes locally from the project structure
  if (Result = nil) and (pURI.StartsWith('http://localhost:1234/') or pURI.StartsWith('https://localhost:1234/')) then
  begin
    if pURI.StartsWith('http://localhost:1234/') then
      lDocPath := pURI.Substring(Length('http://localhost:1234/'))
    else
      lDocPath := pURI.Substring(Length('https://localhost:1234/'));

    lExePath := ExtractFilePath(ParamStr(0));

    // Try finding the remotes folder in ancestor directories (typical test layout)
    lPath := TPath.Combine(lExePath, 'schemas/remotes/' + lDocPath);

    if not FileExists(lPath) then
      lPath := TPath.Combine(lExePath, '../schemas/remotes/' + lDocPath);

    if not FileExists(lPath) then
      lPath := TPath.Combine(lExePath, '../../schemas/remotes/' + lDocPath);

    if not FileExists(lPath) then
      lPath := TPath.Combine(lExePath, '../../../schemas/remotes/' + lDocPath);

    if FileExists(lPath) then
    begin
      try
        Result := TJSONObject.ParseJSONValue(TFile.ReadAllText(lPath));
      except
        // Fallback on parse failure
      end;
    end;
  end;

  // Standard HTTP/HTTPS remote resolution
  if (Result = nil) and (pURI.StartsWith('http://') or pURI.StartsWith('https://')) then
  begin
    lClient := THTTPClient.Create;
    try
      try
        lResponse := lClient.Get(pURI);
        if lResponse.StatusCode = 200 then
          Result := TJSONObject.ParseJSONValue(lResponse.ContentAsString);
      except
        // Network fail, returns nil
      end;
    finally
      lClient.Free;
    end;
  end;
end;

class procedure TSchemaRegistry.RegisterSchema(const pURI: string; const pSchema: TJSONValue);
var
  lCleanURI: string;
  lHashIdx: Integer;
  lFragment: string;
  lCloned: TJSONValue;
begin
  if not Assigned(pSchema) then
    Exit;

  lCleanURI := pURI;
  lHashIdx := lCleanURI.IndexOf('#');
  if lHashIdx >= 0 then
  begin
    lFragment := lCleanURI.Substring(lHashIdx);
    if (lFragment = '#') or (lFragment = '#/') or lFragment.StartsWith('#/') then
      lCleanURI := lCleanURI.Substring(0, lHashIdx);
  end;

  if not FRegistry.ContainsKey(lCleanURI) then
  begin
    lCloned := pSchema.Clone as TJSONValue;
    FRegistry.Add(lCleanURI, lCloned);
    FRoots.Add(lCloned);
    PreScanSchema(lCleanURI, lCloned);
  end;
end;

class function TSchemaRegistry.FindSchema(const pURI: string; out pSchema: TJSONValue): Boolean;
var
  lCleanURI: string;
  lHashIdx: Integer;
  lFragment: string;
  lFetched: TJSONValue;
begin
  lCleanURI := pURI;
  lHashIdx := lCleanURI.IndexOf('#');
  if lHashIdx >= 0 then
  begin
    lFragment := lCleanURI.Substring(lHashIdx);
    if (lFragment = '#') or (lFragment = '#/') or lFragment.StartsWith('#/') then
      lCleanURI := lCleanURI.Substring(0, lHashIdx);
  end;

  if FRegistry.TryGetValue(lCleanURI, pSchema) then
  begin
    Result := True;
  end else
  begin
    // Try to load dynamically
    lFetched := FetchSchemaFromLocalOrHttp(lCleanURI);
    if Assigned(lFetched) then
    begin
      FRegistry.Add(lCleanURI, lFetched);
      FRoots.Add(lFetched);
      PreScanSchema(lCleanURI, lFetched);
      pSchema := lFetched;
      Result := True;
    end else
    begin
      pSchema := nil;
      Result := False;
    end;
  end;
end;

end.
