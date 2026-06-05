unit TestSchemaValidatorCLI;

(*
--------------------------------------------------------------------------------
Integration and unit tests for SchemaValidatorCLI.
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
  /// <summary>Test suite containing unit and integration tests for SchemaValidatorCLI.</summary>
  TTestSchemaValidatorCLI = class(TTestCase)
  strict private
    /// <summary>Spawns the SchemaValidatorCLI process and captures its exit code and stdout/stderr.</summary>
    function RunCLI(const pArgs: string; out pStdout, pStderr: string): Integer;

    /// <summary>Creates a temporary UTF-8 JSON file containing pContent.</summary>
    procedure CreateTempFile(const pContent: string; out pPath: string);

    /// <summary>Deletes the temporary file if it exists.</summary>
    procedure DeleteTempFile(const pPath: string);
  published
    /// <summary>Tests the CLI argument parser with different command line options.</summary>
    procedure TestParseArguments;

    /// <summary>Tests auto-detection of draft versions from schema $schema strings.</summary>
    procedure TestAutoDetectDraft;

    /// <summary>Tests CLI execution with valid schema and instance (exit code 0).</summary>
    procedure TestCLIExecutionSuccess;

    /// <summary>Tests CLI execution with invalid instance (exit code 1).</summary>
    procedure TestCLIExecutionFailure;

    /// <summary>Tests CLI execution with malformed JSON input or missing files (exit code 2).</summary>
    procedure TestCLIExecutionRuntimeError;
  end;

implementation

uses
  SchemaValidatorCLI.Config,
  SchemaValidatorCLI.Utils,
  JsonSchema.Core.Interfaces,
  JsonSchema.Localization.Enums;

{ TTestSchemaValidatorCLI }

function TTestSchemaValidatorCLI.RunCLI(const pArgs: string; out pStdout, pStderr: string): Integer;
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
begin
  Result := -1;
  pStdout := '';
  pStderr := '';

  lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\SchemaValidatorCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\SchemaValidatorCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + 'SchemaValidatorCLI.exe');

  if not FileExists(lExePath) then
    raise Exception.CreateFmt('SchemaValidatorCLI executable not found at: %s', [lExePath]);

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
        while ReadFile(lReadPipe, lBuffer, SizeOf(lBuffer) - 1, lBytesRead, nil) and (lBytesRead > 0) do
        begin
          lBuffer[lBytesRead] := #0;
          lStdoutBuilder.Append(string(PAnsiChar(@lBuffer)));
        end;

        while ReadFile(lReadPipeErr, lBuffer, SizeOf(lBuffer) - 1, lBytesRead, nil) and (lBytesRead > 0) do
        begin
          lBuffer[lBytesRead] := #0;
          lStderrBuilder.Append(string(PAnsiChar(@lBuffer)));
        end;

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

procedure TTestSchemaValidatorCLI.CreateTempFile(const pContent: string; out pPath: string);
var
  lTempDir: array[0..MAX_PATH] of Char;
  lTempFile: array[0..MAX_PATH] of Char;
  lList: TStringList;
begin
  Winapi.Windows.GetTempPath(MAX_PATH, lTempDir);
  Winapi.Windows.GetTempFileName(lTempDir, PChar('js_'), 0, lTempFile);
  pPath := lTempFile;

  lList := TStringList.Create;
  try
    lList.Text := pContent;
    lList.SaveToFile(pPath, TEncoding.UTF8);
  finally
    lList.Free;
  end;
end;

procedure TTestSchemaValidatorCLI.DeleteTempFile(const pPath: string);
begin
  if (pPath <> '') and FileExists(pPath) then
    System.SysUtils.DeleteFile(pPath);
end;

procedure TTestSchemaValidatorCLI.TestParseArguments;
var
  lConfig: TConfig;
begin
  // Default values check
  lConfig := ParseArgumentsEx([]);
  CheckEquals('', lConfig.SchemaPath, 'Default schema path should be empty');
  CheckEquals('', lConfig.InstancePath, 'Default instance path should be empty');
  Check(lConfig.Locale = TLocale.EnUS, 'Default locale should be EnUS');
  Check(lConfig.OutputFormat = ofText, 'Default output format should be text');
  CheckFalse(lConfig.ForceDraft, 'ForceDraft should default to False');
  Check(lConfig.EnforceFormats, 'EnforceFormats should default to True');
  CheckFalse(lConfig.ShowHelp, 'ShowHelp should default to False');

  // Custom values check
  lConfig := ParseArgumentsEx(['-s', 'my_schema.json', '-i', 'my_instance.json', '-d', '7', '-l', 'pt', '-f', 'json', '--no-format']);
  CheckEquals('my_schema.json', lConfig.SchemaPath);
  CheckEquals('my_instance.json', lConfig.InstancePath);
  Check(lConfig.ForceDraft, 'Should force draft');
  Check(lConfig.DraftVersion = TDraftVersion.dvDraft7, 'Draft should be 7');
  Check(lConfig.Locale = TLocale.PtBR, 'Locale should be PtBR');
  Check(lConfig.OutputFormat = ofJson, 'Format should be JSON');
  CheckFalse(lConfig.EnforceFormats, 'EnforceFormats should be disabled');

  // Help flag check
  lConfig := ParseArgumentsEx(['--help']);
  Check(lConfig.ShowHelp, 'ShowHelp should be true');
end;

procedure TTestSchemaValidatorCLI.TestAutoDetectDraft;
var
  lJson: TJSONValue;
begin
  // Unknown/implicit should fallback to default (dvDraft2020_12)
  lJson := TJSONObject.ParseJSONValue('{"properties": {}}');
  try
    Check(AutoDetectDraft(lJson) = TDraftVersion.dvDraft2020_12);
  finally
    lJson.Free;
  end;

  // Draft 6
  lJson := TJSONObject.ParseJSONValue('{"$schema": "http://json-schema.org/draft-06/schema#"}');
  try
    Check(AutoDetectDraft(lJson) = TDraftVersion.dvDraft6);
  finally
    lJson.Free;
  end;

  // Draft 7
  lJson := TJSONObject.ParseJSONValue('{"$schema": "http://json-schema.org/draft-07/schema#"}');
  try
    Check(AutoDetectDraft(lJson) = TDraftVersion.dvDraft7);
  finally
    lJson.Free;
  end;

  // Draft 2019-09
  lJson := TJSONObject.ParseJSONValue('{"$schema": "http://json-schema.org/draft/2019-09/schema"}');
  try
    Check(AutoDetectDraft(lJson) = TDraftVersion.dvDraft2019_09);
  finally
    lJson.Free;
  end;

  // Draft 2020-12
  lJson := TJSONObject.ParseJSONValue('{"$schema": "http://json-schema.org/draft/2020-12/schema"}');
  try
    Check(AutoDetectDraft(lJson) = TDraftVersion.dvDraft2020_12);
  finally
    lJson.Free;
  end;
end;

procedure TTestSchemaValidatorCLI.TestCLIExecutionSuccess;
var
  lSchemaPath, lInstancePath: string;
  lStdout, lStderr: string;
  lExitCode: Integer;
begin
  CreateTempFile('{"type": "object", "properties": {"age": {"type": "integer"}}}', lSchemaPath);
  CreateTempFile('{"age": 30}', lInstancePath);
  try
    lExitCode := RunCLI(Format('-s "%s" -i "%s"', [lSchemaPath, lInstancePath]), lStdout, lStderr);
    CheckEquals(0, lExitCode, 'Exit code should be 0 on validation success');
    Check(lStdout.Contains('Validation succeeded'), 'Stdout should report success');
  finally
    DeleteTempFile(lSchemaPath);
    DeleteTempFile(lInstancePath);
  end;
end;

procedure TTestSchemaValidatorCLI.TestCLIExecutionFailure;
var
  lSchemaPath, lInstancePath: string;
  lStdout, lStderr: string;
  lExitCode: Integer;
begin
  CreateTempFile('{"type": "object", "properties": {"age": {"type": "integer"}}}', lSchemaPath);
  CreateTempFile('{"age": "thirty"}', lInstancePath);
  try
    // Text format test
    lExitCode := RunCLI(Format('-s "%s" -i "%s"', [lSchemaPath, lInstancePath]), lStdout, lStderr);
    CheckEquals(1, lExitCode, 'Exit code should be 1 on validation failure');
    Check(lStdout.Contains('Validation failed'), 'Stdout should report failure');

    // JSON format test
    lExitCode := RunCLI(Format('-s "%s" -i "%s" -f json', [lSchemaPath, lInstancePath]), lStdout, lStderr);
    CheckEquals(1, lExitCode);
    Check(lStdout.StartsWith('['), 'JSON output should be a JSON array');

    // JUnit format test
    lExitCode := RunCLI(Format('-s "%s" -i "%s" -f junit', [lSchemaPath, lInstancePath]), lStdout, lStderr);
    CheckEquals(1, lExitCode);
    Check(lStdout.Contains('<testsuite') and lStdout.Contains('<failure'), 'JUnit output should contain tags');
  finally
    DeleteTempFile(lSchemaPath);
    DeleteTempFile(lInstancePath);
  end;
end;

procedure TTestSchemaValidatorCLI.TestCLIExecutionRuntimeError;
var
  lStdout, lStderr: string;
  lExitCode: Integer;
  lSchemaPath: string;
begin
  // Missing parameter schema (exit code 2)
  lExitCode := RunCLI('', lStdout, lStderr);
  CheckEquals(2, lExitCode);
  Check(lStderr.Contains('Usage') or lStderr.Contains('Missing required option'), 'Usage error message on stderr');

  // Invalid JSON schema file
  CreateTempFile('{invalid_json}', lSchemaPath);
  try
    lExitCode := RunCLI(Format('-s "%s" -i "%s"', [lSchemaPath, lSchemaPath]), lStdout, lStderr);
    CheckEquals(2, lExitCode, 'Exit code should be 2 for invalid JSON structure');
    Check(lStderr.Contains('Error:'), 'Stderr should contain error message');
  finally
    DeleteTempFile(lSchemaPath);
  end;
end;

initialization
  RegisterTest(TTestSchemaValidatorCLI.Suite);

end.
