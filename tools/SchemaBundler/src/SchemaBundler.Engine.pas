unit SchemaBundler.Engine;

(*
--------------------------------------------------------------------------------
Bundling and Packaging engine for JSON Schemas. Resolves external references
and merges them into a single, self-contained schema file.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Generics.Collections;

type
  /// <summary>Options configuration for the SchemaBundler.</summary>
  TSchemaBundlerOptions = record
    UseLegacyDefinitions: Boolean; // If True, bundles into "definitions" instead of "$defs"
    IndentOutput: Boolean;         // If True, outputs formatted JSON
  end;

  /// <summary>Core bundler class that crawls JSON Schemas and inlines references.</summary>
  TSchemaBundler = class
  private
    FOptions: TSchemaBundlerOptions;
    FResolvedFiles: TDictionary<string, string>; // Maps absolute filepath to unique def key
    FDefinitions: TJSONObject;                    // Consolidated definitions block
    FRootDir: string;
    FDefsKeyword: string;

    function GenerateUniqueKey(const pFilePath: string): string;
    function ResolveFullPath(const pRef, pCurrentDir: string): string;
    procedure ProcessNode(pNode: TJSONValue; const pCurrentDir: string; const pFileKey: string);
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>Loads and bundles the schema located at pRootPath.</summary>
    /// <returns>The consolidated self-contained JSON schema content.</returns>
    function Bundle(const pRootPath: string): string;

    property Options: TSchemaBundlerOptions read FOptions write FOptions;
  end;

implementation

uses
  System.IOUtils;

{ TSchemaBundler }

constructor TSchemaBundler.Create;
begin
  inherited Create;
  FResolvedFiles := TDictionary<string, string>.Create;
  FOptions.UseLegacyDefinitions := False;
  FOptions.IndentOutput := True;
end;

destructor TSchemaBundler.Destroy;
begin
  FResolvedFiles.Free;
  inherited Destroy;
end;

function TSchemaBundler.GenerateUniqueKey(const pFilePath: string): string;
var
  lBaseName: string;
  lKey: string;
  lSuffix: Integer;
begin
  lBaseName := ChangeFileExt(ExtractFileName(pFilePath), '');
  // Clean special characters to ensure valid JSON pointer segment
  lBaseName := StringReplace(lBaseName, '.', '_', [rfReplaceAll]);
  lBaseName := StringReplace(lBaseName, '-', '_', [rfReplaceAll]);
  lBaseName := StringReplace(lBaseName, ' ', '_', [rfReplaceAll]);

  lKey := lBaseName;
  if lKey = '' then
    lKey := 'schema';

  lSuffix := 1;
  while FResolvedFiles.ContainsValue(lKey) do
  begin
    lKey := lBaseName + '_' + IntToStr(lSuffix);
    Inc(lSuffix);
  end;

  Result := lKey;
end;

function TSchemaBundler.ResolveFullPath(const pRef, pCurrentDir: string): string;
var
  lCleanRef: string;
begin
  lCleanRef := StringReplace(pRef, '/', '\', [rfReplaceAll]);
  Result := ExpandFileName(TPath.Combine(pCurrentDir, lCleanRef));
end;

procedure TSchemaBundler.ProcessNode(pNode: TJSONValue; const pCurrentDir: string; const pFileKey: string);
var
  lObj: TJSONObject;
  lPair: TJSONPair;
  lArr: TJSONArray;
  lI: Integer;
  lRefStr: string;
  lFullRefPath: string;
  lChildKey: string;
  lExternalSchemaText: string;
  lExternalJSON: TJSONValue;
  lExternalObj: TJSONObject;
  lExternalDir: string;
  lParts: TArray<string>;
  lFileRef: string;
  lSubRef: string;
begin
  if not Assigned(pNode) then
    Exit;

  if pNode is TJSONObject then
  begin
    lObj := TJSONObject(pNode);
    lPair := lObj.Get('$ref');

    if Assigned(lPair) and (lPair.JsonValue is TJSONString) then
    begin
      lRefStr := lPair.JsonValue.Value;
      if lRefStr <> '' then
      begin
        if lRefStr[1] = '#' then
        begin
          if pFileKey <> '' then
          begin
            lObj.RemovePair('$ref').Free;
            lObj.AddPair('$ref', '#/' + FDefsKeyword + '/' + pFileKey + Copy(lRefStr, 2, Length(lRefStr)));
          end;
        end else
        begin
          lParts := lRefStr.Split(['#']);
          lFileRef := lParts[0];
          lSubRef := '';
          if Length(lParts) > 1 then
            lSubRef := lParts[1];

          lFullRefPath := ResolveFullPath(lFileRef, pCurrentDir);

          if not FResolvedFiles.TryGetValue(lFullRefPath, lChildKey) then
          begin
            if not FileExists(lFullRefPath) then
              raise Exception.CreateFmt('Referenced schema file not found: %s', [lFullRefPath]);

            try
              lExternalSchemaText := TFile.ReadAllText(lFullRefPath, TEncoding.UTF8);
            except
              on E: Exception do
                raise Exception.CreateFmt('Error reading schema file %s: %s', [lFullRefPath, E.Message]);
            end;

            lExternalJSON := TJSONObject.ParseJSONValue(lExternalSchemaText);
            if not Assigned(lExternalJSON) or not (lExternalJSON is TJSONObject) then
            begin
              if Assigned(lExternalJSON) then
                lExternalJSON.Free;
              raise Exception.CreateFmt('Schema file is not a valid JSON object: %s', [lFullRefPath]);
            end;

            lExternalObj := TJSONObject(lExternalJSON);
            lChildKey := GenerateUniqueKey(lFullRefPath);
            FResolvedFiles.Add(lFullRefPath, lChildKey);

            lExternalDir := ExtractFilePath(lFullRefPath);
            ProcessNode(lExternalObj, lExternalDir, lChildKey);

            FDefinitions.AddPair(lChildKey, lExternalObj);
          end;

          lObj.RemovePair('$ref').Free;
          if lSubRef <> '' then
          begin
            if lSubRef[1] = '/' then
              lObj.AddPair('$ref', '#/' + FDefsKeyword + '/' + lChildKey + lSubRef)
            else
              lObj.AddPair('$ref', '#/' + FDefsKeyword + '/' + lChildKey + '/' + lSubRef);
          end else
          begin
            lObj.AddPair('$ref', '#/' + FDefsKeyword + '/' + lChildKey);
          end;
        end;
      end;
    end;

    for lPair in lObj do
    begin
      if lPair.JsonString.Value <> '$ref' then
      begin
        ProcessNode(lPair.JsonValue, pCurrentDir, pFileKey);
      end;
    end;
  end else if pNode is TJSONArray then
  begin
    lArr := TJSONArray(pNode);
    for lI := 0 to lArr.Count - 1 do
    begin
      ProcessNode(lArr.Items[lI], pCurrentDir, pFileKey);
    end;
  end;
end;

function TSchemaBundler.Bundle(const pRootPath: string): string;
var
  lRootText: string;
  lRootJSON: TJSONValue;
  lRootObj: TJSONObject;
  lExistingDefs: TJSONValue;
begin
  if FOptions.UseLegacyDefinitions then
    FDefsKeyword := 'definitions'
  else
    FDefsKeyword := '$defs';

  FRootDir := ExtractFilePath(pRootPath);

  if not FileExists(pRootPath) then
    raise Exception.Create('Root schema file not found at: ' + pRootPath);

  lRootText := TFile.ReadAllText(pRootPath, TEncoding.UTF8);
  lRootJSON := TJSONObject.ParseJSONValue(lRootText);
  if not Assigned(lRootJSON) or not (lRootJSON is TJSONObject) then
  begin
    if Assigned(lRootJSON) then
      lRootJSON.Free;
    raise Exception.Create('Root schema is not a valid JSON Object.');
  end;

  lRootObj := TJSONObject(lRootJSON);
  try
    FResolvedFiles.Clear;
    FResolvedFiles.Add(ExpandFileName(pRootPath), '');

    lExistingDefs := lRootObj.Values[FDefsKeyword];
    if Assigned(lExistingDefs) and (lExistingDefs is TJSONObject) then
    begin
      FDefinitions := TJSONObject(lExistingDefs);
    end else
    begin
      FDefinitions := TJSONObject.Create;
      lRootObj.AddPair(FDefsKeyword, FDefinitions);
    end;

    ProcessNode(lRootObj, FRootDir, '');

    if FOptions.IndentOutput then
      Result := lRootObj.Format(2)
    else
      Result := lRootObj.ToJSON;
  finally
    lRootObj.Free;
  end;
end;

end.
