unit TestSchemaBundler;

(*
--------------------------------------------------------------------------------
Unit and integration tests for the SchemaBundler engine and CLI utility.
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
  /// <summary>Unit and integration tests checking SchemaBundler consolidation.</summary>
  TTestSchemaBundler = class(TTestCase)
  strict private
    FTestDir: string;
    function RunCLI(const pArgs: string; out pStdout, pStderr: string): Integer;
    procedure CreateTestEnvironment;
    procedure CleanupTestEnvironment;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    /// <summary>Tests simple single-level bundling of one external schema.</summary>
    procedure TestSimpleBundle;

    /// <summary>Tests recursive nested multi-level bundling with path navigation.</summary>
    procedure TestNestedBundle;

    /// <summary>Tests rewriting of internal local references in bundled schemas.</summary>
    procedure TestLocalRefRewriting;

    /// <summary>Tests CLI packaging tool execution.</summary>
    procedure TestCLIExecution;

    /// <summary>Tests parser command line configurations.</summary>
    procedure TestParseArguments;
  end;

implementation

uses
  System.IOUtils,
  SchemaBundler.Engine,
  SchemaBundler.Config;

{ TTestSchemaBundler }

procedure TTestSchemaBundler.SetUp;
begin
  inherited SetUp;
  CreateTestEnvironment;
end;

procedure TTestSchemaBundler.TearDown;
begin
  CleanupTestEnvironment;
  inherited TearDown;
end;

function TTestSchemaBundler.RunCLI(const pArgs: string; out pStdout, pStderr: string): Integer;
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

  lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\.bin\SchemaBundlerCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\SchemaBundlerCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\SchemaBundlerCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + 'SchemaBundlerCLI.exe');

  if not FileExists(lExePath) then
    raise Exception.CreateFmt('SchemaBundlerCLI executable not found at: %s', [lExePath]);

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

procedure TTestSchemaBundler.CreateTestEnvironment;
begin
  FTestDir := TPath.Combine(TPath.GetTempPath, 'SchemaBundlerTests_' + GUIDToString(TGUID.NewGuid));
  ForceDirectories(FTestDir);
  ForceDirectories(TPath.Combine(FTestDir, 'shared'));

  // 1. Root Schema (main.json)
  TFile.WriteAllText(TPath.Combine(FTestDir, 'main.json'),
    '{' +
    '  "type": "object",' +
    '  "properties": {' +
    '    "user": {"$ref": "user.json"}' +
    '  }' +
    '}', TEncoding.UTF8);

  // 2. User Schema (user.json)
  TFile.WriteAllText(TPath.Combine(FTestDir, 'user.json'),
    '{' +
    '  "type": "object",' +
    '  "properties": {' +
    '    "name": {"$ref": "#/definitions/nameString"},' +
    '    "address": {"$ref": "shared/address.json"}' +
    '  },' +
    '  "definitions": {' +
    '    "nameString": {"type": "string"}' +
    '  }' +
    '}', TEncoding.UTF8);

  // 3. Address Schema (shared/address.json)
  TFile.WriteAllText(TPath.Combine(FTestDir, 'shared/address.json'),
    '{' +
    '  "type": "object",' +
    '  "properties": {' +
    '    "city": {"type": "string"},' +
    '    "postal": {"$ref": "#/definitions/postalCode"}' +
    '  },' +
    '  "definitions": {' +
    '    "postalCode": {"type": "string", "pattern": "^[0-9]{5}$"}' +
    '  }' +
    '}', TEncoding.UTF8);
end;

procedure TTestSchemaBundler.CleanupTestEnvironment;
begin
  if TDirectory.Exists(FTestDir) then
  begin
    try
      TDirectory.Delete(FTestDir, True);
    except
      // ignore locking issues in teardown
    end;
  end;
end;

procedure TTestSchemaBundler.TestSimpleBundle;
var
  lBundler: TSchemaBundler;
  lOutput: string;
  lJSON: TJSONObject;
  lDefs: TJSONObject;
  lUser: TJSONObject;
  lProps: TJSONObject;
  lUserVal: TJSONObject;
begin
  lBundler := TSchemaBundler.Create;
  try
    lOutput := lBundler.Bundle(TPath.Combine(FTestDir, 'main.json'));
    lJSON := TJSONObject.ParseJSONValue(lOutput) as TJSONObject;
    try
      // Verify main structure
      lProps := lJSON.Values['properties'] as TJSONObject;
      lUserVal := lProps.Values['user'] as TJSONObject;
      CheckEquals('#/$defs/user', lUserVal.Values['$ref'].Value);

      // Verify $defs contains "user"
      lDefs := lJSON.Values['$defs'] as TJSONObject;
      CheckNotNull(lDefs, '$defs block should be present');

      lUser := lDefs.Values['user'] as TJSONObject;
      CheckNotNull(lUser, '"user" should be present inside $defs');
      CheckEquals('object', lUser.Values['type'].Value);
    finally
      lJSON.Free;
    end;
  finally
    lBundler.Free;
  end;
end;

procedure TTestSchemaBundler.TestNestedBundle;
var
  lBundler: TSchemaBundler;
  lOutput: string;
  lJSON: TJSONObject;
  lDefs: TJSONObject;
  lAddress: TJSONObject;
begin
  lBundler := TSchemaBundler.Create;
  try
    lOutput := lBundler.Bundle(TPath.Combine(FTestDir, 'main.json'));
    lJSON := TJSONObject.ParseJSONValue(lOutput) as TJSONObject;
    try
      lDefs := lJSON.Values['$defs'] as TJSONObject;
      CheckNotNull(lDefs, '$defs block should be present');

      // Verify "address" key exists in root defs
      lAddress := lDefs.Values['address'] as TJSONObject;
      CheckNotNull(lAddress, '"address" should be bundled at root $defs level');
      CheckEquals('object', lAddress.Values['type'].Value);
    finally
      lJSON.Free;
    end;
  finally
    lBundler.Free;
  end;
end;

procedure TTestSchemaBundler.TestLocalRefRewriting;
var
  lBundler: TSchemaBundler;
  lOutput: string;
  lJSON: TJSONObject;
  lDefs: TJSONObject;
  lUser: TJSONObject;
  lAddress: TJSONObject;
  lUserProps: TJSONObject;
  lUserName: TJSONObject;
  lAddrProps: TJSONObject;
  lAddrPostal: TJSONObject;
begin
  lBundler := TSchemaBundler.Create;
  try
    lOutput := lBundler.Bundle(TPath.Combine(FTestDir, 'main.json'));
    lJSON := TJSONObject.ParseJSONValue(lOutput) as TJSONObject;
    try
      lDefs := lJSON.Values['$defs'] as TJSONObject;

      lUser := lDefs.Values['user'] as TJSONObject;
      lUserProps := lUser.Values['properties'] as TJSONObject;
      lUserName := lUserProps.Values['name'] as TJSONObject;
      CheckEquals('#/$defs/user/definitions/nameString', lUserName.Values['$ref'].Value);

      lAddress := lDefs.Values['address'] as TJSONObject;
      lAddrProps := lAddress.Values['properties'] as TJSONObject;
      lAddrPostal := lAddrProps.Values['postal'] as TJSONObject;
      CheckEquals('#/$defs/address/definitions/postalCode', lAddrPostal.Values['$ref'].Value);
    finally
      lJSON.Free;
    end;
  finally
    lBundler.Free;
  end;
end;

procedure TTestSchemaBundler.TestCLIExecution;
var
  lExitCode: Integer;
  lStdout: string;
  lStderr: string;
  lOutFile: string;
  lJSON: TJSONObject;
  lProps: TJSONObject;
  lUserVal: TJSONObject;
begin
  lOutFile := TPath.Combine(FTestDir, 'bundled_output.json');
  lExitCode := RunCLI(Format('-i "%s" -o "%s"', [TPath.Combine(FTestDir, 'main.json'), lOutFile]), lStdout, lStderr);

  CheckEquals(0, lExitCode, 'CLI should complete with code 0');
  CheckTrue(TFile.Exists(lOutFile), 'Output file must be generated');

  lJSON := TJSONObject.ParseJSONValue(TFile.ReadAllText(lOutFile, TEncoding.UTF8)) as TJSONObject;
  try
    CheckNotNull(lJSON.Values['$defs'], '$defs block should exist in output');
    lProps := lJSON.Values['properties'] as TJSONObject;
    lUserVal := lProps.Values['user'] as TJSONObject;
    CheckEquals('#/$defs/user', lUserVal.Values['$ref'].Value);
  finally
    lJSON.Free;
  end;
end;

procedure TTestSchemaBundler.TestParseArguments;
var
  lConfig: TSchemaBundlerConfig;
begin
  lConfig := ParseCommandLineEx([]);
  CheckEquals('', lConfig.InputPath);
  CheckEquals('', lConfig.OutputPath);
  CheckFalse(lConfig.UseLegacy);
  CheckFalse(lConfig.Minify);
  CheckFalse(lConfig.Quiet);
  CheckFalse(lConfig.ShowHelp);

  lConfig := ParseCommandLineEx(['-i', 'schema.json', '-o', 'out.json', '--legacy', '--minify', '--quiet']);
  CheckEquals('schema.json', lConfig.InputPath);
  CheckEquals('out.json', lConfig.OutputPath);
  CheckTrue(lConfig.UseLegacy);
  CheckTrue(lConfig.Minify);
  CheckTrue(lConfig.Quiet);

  // Synonyms
  lConfig := ParseCommandLineEx(['-s', 'schema.json', '--output', 'out.json']);
  CheckEquals('schema.json', lConfig.InputPath);
  CheckEquals('out.json', lConfig.OutputPath);

  lConfig := ParseCommandLineEx(['--schema', 'schema.json']);
  CheckEquals('schema.json', lConfig.InputPath);

  // Fallback Positional Parameter
  lConfig := ParseCommandLineEx(['schema.json', '-o', 'out.json']);
  CheckEquals('schema.json', lConfig.InputPath);
  CheckEquals('out.json', lConfig.OutputPath);
end;

initialization
  RegisterTest(TTestSchemaBundler.Suite);

end.
