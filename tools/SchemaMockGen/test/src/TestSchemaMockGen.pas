unit TestSchemaMockGen;

(*
--------------------------------------------------------------------------------
Unit and integration tests for SchemaMockGen CLI and Generator.
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
  /// <summary>Test suite validating constraint mock generation and CLI runner behaviors.</summary>
  TTestSchemaMockGen = class(TTestCase)
  strict private
    function RunCLI(const pArgs: string; out pStdout, pStderr: string): Integer;
    procedure CreateTempFile(const pContent: string; out pPath: string);
    procedure DeleteTempFile(const pPath: string);
  published
    /// <summary>Verifies that TSeededRandom is deterministic and repeatable.</summary>
    procedure TestSeededRandom;

    /// <summary>Checks CLI argument parsing logic.</summary>
    procedure TestParseArguments;

    /// <summary>Generates mock JSON against schemas and validates using the core engine.</summary>
    procedure TestGeneratorConformity;

    /// <summary>Verifies CLI process execution exit codes and redirection behavior.</summary>
    procedure TestCLIExecution;
  end;

implementation

uses
  SchemaMockGen.Config,
  SchemaMockGen.Utils,
  SchemaMockGen.Generator,
  JsonSchema.Validator,
  JsonSchema.Core.Interfaces;

{ TTestSchemaMockGen }

function TTestSchemaMockGen.RunCLI(const pArgs: string; out pStdout, pStderr: string): Integer;
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

  lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\SchemaMockGen.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\SchemaMockGen.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + 'SchemaMockGen.exe');

  if not FileExists(lExePath) then
    raise Exception.CreateFmt('SchemaMockGen executable not found at: %s', [lExePath]);

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

procedure TTestSchemaMockGen.CreateTempFile(const pContent: string; out pPath: string);
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

procedure TTestSchemaMockGen.DeleteTempFile(const pPath: string);
begin
  if (pPath <> '') and FileExists(pPath) then
    System.SysUtils.DeleteFile(pPath);
end;

procedure TTestSchemaMockGen.TestSeededRandom;
var
  lRand1, lRand2, lRandDiff: TSeededRandom;
  lI: Integer;
begin
  lRand1 := TSeededRandom.Create(12345);
  lRand2 := TSeededRandom.Create(12345);
  lRandDiff := TSeededRandom.Create(54321);
  try
    for lI := 1 to 50 do
    begin
      CheckEquals(lRand1.NextInt(0, 1000), lRand2.NextInt(0, 1000), 'Identical seeds must yield identical results');
      Check(lRand1.NextBool = lRand2.NextBool);
      Check(lRand1.NextDouble = lRand2.NextDouble);
    end;

    // Verify that different seeds generate at least some different results
    CheckNotEquals(lRand1.NextInt(0, 1000), lRandDiff.NextInt(0, 1000));
  finally
    lRand1.Free;
    lRand2.Free;
    lRandDiff.Free;
  end;
end;

procedure TTestSchemaMockGen.TestParseArguments;
var
  lConfig: TConfig;
begin
  // Default values
  lConfig := ParseArgumentsEx([]);
  CheckEquals('', lConfig.SchemaPath);
  CheckEquals('', lConfig.OutputPath);
  CheckEquals(-1, lConfig.Seed);
  CheckEquals(1, lConfig.Count);
  CheckFalse(lConfig.ShowHelp);

  // Custom values
  lConfig := ParseArgumentsEx(['-s', 'schema.json', '-o', 'out.json', '-e', '9876', '-n', '5']);
  CheckEquals('schema.json', lConfig.SchemaPath);
  CheckEquals('out.json', lConfig.OutputPath);
  CheckEquals(9876, lConfig.Seed);
  CheckEquals(5, lConfig.Count);
end;

procedure TTestSchemaMockGen.TestGeneratorConformity;
var
  lSchemaJson: TJSONObject;
  lValidator: TJsonSchemaValidator;
  lGenerator: TSchemaMockGenerator;
  lMock: TJSONValue;
  lResult: IValidationResult;
  lSchemaStr: string;
begin
  lSchemaStr :=
    '{' +
    '  "type": "object",' +
    '  "properties": {' +
    '    "age": {"type": "integer", "minimum": 18, "maximum": 99},' +
    '    "name": {"type": "string", "minLength": 3, "maxLength": 10},' +
    '    "email": {"type": "string", "format": "email"},' +
    '    "active": {"type": "boolean"}' +
    '  },' +
    '  "required": ["age", "name", "email"]' +
    '}';

  lSchemaJson := TJSONObject.ParseJSONValue(lSchemaStr) as TJSONObject;
  lValidator := TJsonSchemaValidator.Create;
  lGenerator := TSchemaMockGenerator.Create(1337);
  try
    lMock := lGenerator.Generate(lSchemaJson);
    try
      // Check that required properties exist
      Check(TJSONObject(lMock).Values['age'] <> nil);
      Check(TJSONObject(lMock).Values['name'] <> nil);
      Check(TJSONObject(lMock).Values['email'] <> nil);

      // Validate the mock data using core validator library
      lResult := lValidator.Validate(lSchemaJson, lMock, TDraftVersion.dvDraft2020_12);
      Check(lResult.IsValid, 'Generated mock JSON must conform to the JSON Schema');
    finally
      lMock.Free;
    end;
  finally
    lSchemaJson.Free;
    lValidator.Free;
    lGenerator.Free;
  end;
end;

procedure TTestSchemaMockGen.TestCLIExecution;
var
  lSchemaPath, lOutputPath: string;
  lStdout, lStderr: string;
  lExitCode: Integer;
  lMockVal: TJSONValue;
  lValidator: TJsonSchemaValidator;
  lSchemaVal: TJSONValue;
  lResult: IValidationResult;
begin
  lValidator := TJsonSchemaValidator.Create;
  CreateTempFile('{"type": "object", "properties": {"id": {"type": "string", "format": "uuid"}}, "required": ["id"]}', lSchemaPath);
  CreateTempFile('', lOutputPath);
  try
    // Run CLI generating to file
    lExitCode := RunCLI(Format('-s "%s" -o "%s" -e 42', [lSchemaPath, lOutputPath]), lStdout, lStderr);
    CheckEquals(0, lExitCode, 'Exit code should be 0 on success');

    // Load and validate generated mock data
    lMockVal := TJSONObject.ParseJSONValue(ReadFileContent(lOutputPath));
    lSchemaVal := TJSONObject.ParseJSONValue(ReadFileContent(lSchemaPath));
    try
      lResult := lValidator.Validate(lSchemaVal, lMockVal, TDraftVersion.dvDraft2020_12);
      Check(lResult.IsValid, 'File-generated mock must conform to the schema');
    finally
      lMockVal.Free;
      lSchemaVal.Free;
    end;

    // Run CLI printing to stdout with count > 1
    lExitCode := RunCLI(Format('-s "%s" -e 42 -n 3', [lSchemaPath]), lStdout, lStderr);
    CheckEquals(0, lExitCode);
    Check(lStdout.StartsWith('['), 'Output must be a JSON array when count > 1');
  finally
    lValidator.Free;
    DeleteTempFile(lSchemaPath);
    DeleteTempFile(lOutputPath);
  end;
end;

initialization
  RegisterTest(TTestSchemaMockGen.Suite);

end.
