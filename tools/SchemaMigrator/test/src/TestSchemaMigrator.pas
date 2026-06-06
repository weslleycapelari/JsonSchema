unit TestSchemaMigrator;

(*
--------------------------------------------------------------------------------
Unit and integration tests for the SchemaMigrator engine and CLI utility.
--------------------------------------------------------------------------------
*)

interface

uses
  TestFramework,
  System.Classes,
  System.JSON,
  System.SysUtils,
  Winapi.Windows;

type
  /// <summary>Unit and integration tests checking SchemaMigrator dialet upgrades.</summary>
  TTestSchemaMigrator = class(TTestCase)
  strict private
    function RunCLI(const pArgs: string; out pStdout, pStderr: string): Integer;
    procedure CreateTempFile(const pContent: string; out pPath: string);
    procedure DeleteTempFile(const pPath: string);
  published
    /// <summary>Tests upgrading the draft version dialect and ID keyword.</summary>
    procedure TestDialectAndIdUpgrade;

    /// <summary>Tests renaming definitions to $defs and updating referencing pointers.</summary>
    procedure TestDefinitionsAndRefUpgrade;

    /// <summary>Tests splitting dependencies into dependentRequired and dependentSchemas.</summary>
    procedure TestDependenciesUpgrade;

    /// <summary>Tests translating array items to prefixItems and additionalItems to items.</summary>
    procedure TestItemsUpgrade;

    /// <summary>Tests CLI execution of the migrator utility.</summary>
    procedure TestCLIExecution;
  end;

implementation

uses
  System.IOUtils,
  SchemaMigrator.Engine,
  SchemaMigrator.Config;

{ TTestSchemaMigrator }

function TTestSchemaMigrator.RunCLI(const pArgs: string; out pStdout, pStderr: string): Integer;
var
  lSecAttributes: TSecurityAttributes;
  lReadPipe, lWritePipe: THandle;
  lReadPipeErr, lWritePipeErr: THandle;
  lStartInfo: TStartUpInfo;
  lProcInfo: TProcessInformation;
  lBuffer: array[0..4095] of AnsiChar;
  lBytesRead: DWORD;
  lExitCode: DWORD;
  lCmdLine: string;
  lExePath: string;
  lStdoutBuilder: TStringBuilder;
  lStderrBuilder: TStringBuilder;
  lHasReadStdout, lHasReadStderr: Boolean;
begin
  Result := -1;
  pStdout := '';
  pStderr := '';

  lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\.bin\SchemaMigratorCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\SchemaMigratorCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\SchemaMigratorCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + 'SchemaMigratorCLI.exe');

  if not FileExists(lExePath) then
    raise Exception.CreateFmt('SchemaMigratorCLI executable not found at: %s', [lExePath]);

  lSecAttributes.nLength := SizeOf(TSecurityAttributes);
  lSecAttributes.bInheritHandle := True;
  lSecAttributes.lpSecurityDescriptor := nil;

  if not CreatePipe(lReadPipe, lWritePipe, @lSecAttributes, 0) then
    Exit;

  if not CreatePipe(lReadPipeErr, lWritePipeErr, @lSecAttributes, 0) then
  begin
    CloseHandle(lReadPipe);
    CloseHandle(lWritePipe);
    Exit;
  end;

  try
    SetHandleInformation(lReadPipe, HANDLE_FLAG_INHERIT, 0);
    SetHandleInformation(lReadPipeErr, HANDLE_FLAG_INHERIT, 0);

    FillChar(lStartInfo, SizeOf(TStartUpInfo), 0);
    lStartInfo.cb := SizeOf(TStartUpInfo);
    lStartInfo.hStdOutput := lWritePipe;
    lStartInfo.hStdError := lWritePipeErr;
    lStartInfo.dwFlags := STARTF_USESTDHANDLES;

    lCmdLine := Format('"%s" %s', [lExePath, pArgs]);
    UniqueString(lCmdLine);

    if Winapi.Windows.CreateProcess(nil, PChar(lCmdLine), nil, nil, True, CREATE_NO_WINDOW, nil, nil, lStartInfo, lProcInfo) then
    begin
      CloseHandle(lWritePipe);
      lWritePipe := 0;
      CloseHandle(lWritePipeErr);
      lWritePipeErr := 0;

      lStdoutBuilder := TStringBuilder.Create;
      lStderrBuilder := TStringBuilder.Create;
      try
        repeat
          lHasReadStdout := ReadFile(lReadPipe, lBuffer, SizeOf(lBuffer) - 1, lBytesRead, nil) and (lBytesRead > 0);
          if lHasReadStdout then
          begin
            lBuffer[lBytesRead] := #0;
            lStdoutBuilder.Append(string(PAnsiChar(@lBuffer)));
          end;
        until not lHasReadStdout;

        repeat
          lHasReadStderr := ReadFile(lReadPipeErr, lBuffer, SizeOf(lBuffer) - 1, lBytesRead, nil) and (lBytesRead > 0);
          if lHasReadStderr then
          begin
            lBuffer[lBytesRead] := #0;
            lStderrBuilder.Append(string(PAnsiChar(@lBuffer)));
          end;
        until not lHasReadStderr;

        pStdout := lStdoutBuilder.ToString;
        pStderr := lStderrBuilder.ToString;
      finally
        lStdoutBuilder.Free;
        lStderrBuilder.Free;
      end;

      WaitForSingleObject(lProcInfo.hProcess, INFINITE);
      if GetExitCodeProcess(lProcInfo.hProcess, lExitCode) then
        Result := lExitCode;

      CloseHandle(lProcInfo.hProcess);
      CloseHandle(lProcInfo.hThread);
    end;
  finally
    if lReadPipe <> 0 then CloseHandle(lReadPipe);
    if lWritePipe <> 0 then CloseHandle(lWritePipe);
    if lReadPipeErr <> 0 then CloseHandle(lReadPipeErr);
    if lWritePipeErr <> 0 then CloseHandle(lWritePipeErr);
  end;
end;

procedure TTestSchemaMigrator.CreateTempFile(const pContent: string; out pPath: string);
var
  lTempFolder: array[0..MAX_PATH] of Char;
  lTempFile: array[0..MAX_PATH] of Char;
begin
  GetTempPath(MAX_PATH, lTempFolder);
  GetTempFileName(lTempFolder, 'mig', 0, lTempFile);
  pPath := lTempFile;
  TFile.WriteAllText(pPath, pContent, TEncoding.UTF8);
end;

procedure TTestSchemaMigrator.DeleteTempFile(const pPath: string);
begin
  if FileExists(pPath) then
    System.SysUtils.DeleteFile(pPath);
end;

procedure TTestSchemaMigrator.TestDialectAndIdUpgrade;
var
  lMigrator: TSchemaMigrator;
  lSchema: TJSONObject;
  lOutput: string;
  lJSON: TJSONObject;
begin
  lSchema := TJSONObject.ParseJSONValue(
    '{' +
    '  "$schema": "http://json-schema.org/draft-04/schema#",' +
    '  "id": "http://example.com/user.json",' +
    '  "type": "object"' +
    '}'
  ) as TJSONObject;

  lMigrator := TSchemaMigrator.Create;
  try
    lOutput := lMigrator.Migrate(lSchema);
    lJSON := TJSONObject.ParseJSONValue(lOutput) as TJSONObject;
    try
      CheckEquals('https://json-schema.org/draft/2020-12/schema', lJSON.Values['$schema'].Value);
      CheckEquals('http://example.com/user.json', lJSON.Values['$id'].Value);
      CheckNull(lJSON.Values['id'], 'Old id keyword must be removed');
    finally
      lJSON.Free;
    end;
  finally
    lMigrator.Free;
    lSchema.Free;
  end;
end;

procedure TTestSchemaMigrator.TestDefinitionsAndRefUpgrade;
var
  lMigrator: TSchemaMigrator;
  lSchema: TJSONObject;
  lOutput: string;
  lJSON: TJSONObject;
  lDefs: TJSONObject;
  lProps: TJSONObject;
  lName: TJSONObject;
begin
  lSchema := TJSONObject.ParseJSONValue(
    '{' +
    '  "definitions": {' +
    '    "nameString": {"type": "string"}' +
    '  },' +
    '  "properties": {' +
    '    "name": {"$ref": "#/definitions/nameString"}' +
    '  }' +
    '}'
  ) as TJSONObject;

  lMigrator := TSchemaMigrator.Create;
  try
    lOutput := lMigrator.Migrate(lSchema);
    lJSON := TJSONObject.ParseJSONValue(lOutput) as TJSONObject;
    try
      lDefs := lJSON.Values['$defs'] as TJSONObject;
      CheckNotNull(lDefs, 'definitions should be renamed to $defs');
      CheckNull(lJSON.Values['definitions'], 'Old definitions keyword must be removed');

      lProps := lJSON.Values['properties'] as TJSONObject;
      lName := lProps.Values['name'] as TJSONObject;
      CheckEquals('#/$defs/nameString', lName.Values['$ref'].Value);
    finally
      lJSON.Free;
    end;
  finally
    lMigrator.Free;
    lSchema.Free;
  end;
end;

procedure TTestSchemaMigrator.TestDependenciesUpgrade;
var
  lMigrator: TSchemaMigrator;
  lSchema: TJSONObject;
  lOutput: string;
  lJSON: TJSONObject;
  lDepReq: TJSONObject;
  lDepSch: TJSONObject;
begin
  lSchema := TJSONObject.ParseJSONValue(
    '{' +
    '  "dependencies": {' +
    '    "credit_card": ["billing_address"],' +
    '    "billing_address": {' +
    '      "properties": {' +
    '        "zip": {"type": "string"}' +
    '      }' +
    '    }' +
    '  }' +
    '}'
  ) as TJSONObject;

  lMigrator := TSchemaMigrator.Create;
  try
    lOutput := lMigrator.Migrate(lSchema);
    lJSON := TJSONObject.ParseJSONValue(lOutput) as TJSONObject;
    try
      CheckNull(lJSON.Values['dependencies'], 'Old dependencies keyword must be removed');

      lDepReq := lJSON.Values['dependentRequired'] as TJSONObject;
      CheckNotNull(lDepReq, 'dependentRequired should be created');
      CheckEquals('["billing_address"]', lDepReq.Values['credit_card'].ToJSON);

      lDepSch := lJSON.Values['dependentSchemas'] as TJSONObject;
      CheckNotNull(lDepSch, 'dependentSchemas should be created');
      CheckTrue(lDepSch.Values['billing_address'].ToJSON.Contains('zip'), 'Should contain billing_address schema');
    finally
      lJSON.Free;
    end;
  finally
    lMigrator.Free;
    lSchema.Free;
  end;
end;

procedure TTestSchemaMigrator.TestItemsUpgrade;
var
  lMigrator: TSchemaMigrator;
  lSchema: TJSONObject;
  lOutput: string;
  lJSON: TJSONObject;
begin
  lSchema := TJSONObject.ParseJSONValue(
    '{' +
    '  "items": [' +
    '    {"type": "string"},' +
    '    {"type": "number"}' +
    '  ],' +
    '  "additionalItems": {"type": "boolean"}' +
    '}'
  ) as TJSONObject;

  lMigrator := TSchemaMigrator.Create;
  try
    lOutput := lMigrator.Migrate(lSchema);
    lJSON := TJSONObject.ParseJSONValue(lOutput) as TJSONObject;
    try
      CheckNotNull(lJSON.Values['prefixItems'], 'Array items should be renamed to prefixItems');
      CheckNull(lJSON.Values['additionalItems'], 'additionalItems keyword must be removed');
      CheckEquals('{"type":"boolean"}', lJSON.Values['items'].ToJSON);
    finally
      lJSON.Free;
    end;
  finally
    lMigrator.Free;
    lSchema.Free;
  end;
end;

procedure TTestSchemaMigrator.TestCLIExecution;
var
  lExitCode: Integer;
  lStdout: string;
  lStderr: string;
  lTempFile: string;
  lOutFile: string;
  lJSON: TJSONObject;
begin
  CreateTempFile(
    '{' +
    '  "definitions": {' +
    '    "test": {"type": "string"}' +
    '  }' +
    '}', lTempFile);
  lOutFile := lTempFile + '.migrated';
  try
    lExitCode := RunCLI(Format('-i "%s" -o "%s"', [lTempFile, lOutFile]), lStdout, lStderr);
    CheckEquals(0, lExitCode, 'CLI should complete with code 0');
    CheckTrue(TFile.Exists(lOutFile), 'Output file must be generated');

    lJSON := TJSONObject.ParseJSONValue(TFile.ReadAllText(lOutFile, TEncoding.UTF8)) as TJSONObject;
    try
      CheckNotNull(lJSON.Values['$defs'], '$defs block should exist in output');
    finally
      lJSON.Free;
    end;
  finally
    DeleteTempFile(lTempFile);
    DeleteTempFile(lOutFile);
  end;
end;

initialization
  RegisterTest(TTestSchemaMigrator.Suite);

end.
