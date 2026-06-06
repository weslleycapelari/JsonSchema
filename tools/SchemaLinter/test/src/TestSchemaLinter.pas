unit TestSchemaLinter;

(*
--------------------------------------------------------------------------------
Unit and integration tests for the SchemaLinter engine and CLI utility.
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
  /// <summary>Unit and integration tests checking SchemaLinter static analysis and CLI.</summary>
  TTestSchemaLinter = class(TTestCase)
  strict private
    function RunCLI(const pArgs: string; out pStdout, pStderr: string): Integer;
    procedure CreateTempFile(const pContent: string; out pPath: string);
    procedure DeleteTempFile(const pPath: string);
  published
    /// <summary>Tests detection of min/max conflicts and other limit anomalies.</summary>
    procedure TestLimitsConflict;

    /// <summary>Tests detection of required fields that are not defined in properties.</summary>
    procedure TestRequiredFieldsConflict;

    /// <summary>Tests detection of deprecated keywords like definitions and dependencies.</summary>
    procedure TestLegacyKeywords;

    /// <summary>Tests detection of missing documentation elements.</summary>
    procedure TestMissingDocumentation;

    /// <summary>Tests detection of potential ReDoS regex pattern vulnerabilities.</summary>
    procedure TestRegexReDoS;

    /// <summary>Tests CLI execution validation and exit codes.</summary>
    procedure TestCLIExecution;
  end;

implementation

uses
  System.IOUtils,
  SchemaLinter.Engine,
  SchemaLinter.Config;

{ TTestSchemaLinter }

function TTestSchemaLinter.RunCLI(const pArgs: string; out pStdout, pStderr: string): Integer;
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

  lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\.bin\SchemaLinterCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\SchemaLinterCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\SchemaLinterCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + 'SchemaLinterCLI.exe');

  if not FileExists(lExePath) then
    raise Exception.CreateFmt('SchemaLinterCLI executable not found at: %s', [lExePath]);

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

procedure TTestSchemaLinter.CreateTempFile(const pContent: string; out pPath: string);
var
  lTempFolder: array[0..MAX_PATH] of Char;
  lTempFile: array[0..MAX_PATH] of Char;
begin
  GetTempPath(MAX_PATH, lTempFolder);
  GetTempFileName(lTempFolder, 'lnt', 0, lTempFile);
  pPath := lTempFile;
  TFile.WriteAllText(pPath, pContent, TEncoding.UTF8);
end;

procedure TTestSchemaLinter.DeleteTempFile(const pPath: string);
begin
  if FileExists(pPath) then
    System.SysUtils.DeleteFile(pPath);
end;

procedure TTestSchemaLinter.TestLimitsConflict;
var
  lLinter: TSchemaLinter;
  lSchema: TJSONObject;
  lFindings: TArray<TLintFinding>;
  lHasMinMax, lHasLength, lHasItems, lHasProps: Boolean;
  lFinding: TLintFinding;
begin
  lSchema := TJSONObject.ParseJSONValue(
    '{' +
    '  "type": "object",' +
    '  "properties": {' +
    '    "age": {"type": "integer", "minimum": 100, "maximum": 50},' +
    '    "name": {"type": "string", "minLength": 10, "maxLength": 5},' +
    '    "tags": {"type": "array", "minItems": 8, "maxItems": 4},' +
    '    "meta": {"type": "object", "minProperties": 5, "maxProperties": 2}' +
    '  }' +
    '}'
  ) as TJSONObject;

  lLinter := TSchemaLinter.Create;
  try
    lLinter.MinSeverity := TSeverity.Info;
    lFindings := lLinter.Analyze(lSchema);

    lHasMinMax := False;
    lHasLength := False;
    lHasItems := False;
    lHasProps := False;

    for lFinding in lFindings do
    begin
      if lFinding.RuleId = 'LINT_MIN_MAX_CONFLICT' then
        lHasMinMax := True
      else if lFinding.RuleId = 'LINT_LENGTH_CONFLICT' then
        lHasLength := True
      else if lFinding.RuleId = 'LINT_ITEMS_CONFLICT' then
        lHasItems := True
      else if lFinding.RuleId = 'LINT_PROPS_CONFLICT' then
        lHasProps := True;
    end;

    CheckTrue(lHasMinMax, 'Should detect minimum > maximum conflict');
    CheckTrue(lHasLength, 'Should detect minLength > maxLength conflict');
    CheckTrue(lHasItems, 'Should detect minItems > maxItems conflict');
    CheckTrue(lHasProps, 'Should detect minProperties > maxProperties conflict');
  finally
    lLinter.Free;
    lSchema.Free;
  end;
end;

procedure TTestSchemaLinter.TestRequiredFieldsConflict;
var
  lLinter: TSchemaLinter;
  lSchema: TJSONObject;
  lFindings: TArray<TLintFinding>;
  lHasRequiredConflict: Boolean;
  lFinding: TLintFinding;
begin
  lSchema := TJSONObject.ParseJSONValue(
    '{' +
    '  "type": "object",' +
    '  "properties": {' +
    '    "id": {"type": "integer"}' +
    '  },' +
    '  "required": ["id", "username", "email"]' +
    '}'
  ) as TJSONObject;

  lLinter := TSchemaLinter.Create;
  try
    lFindings := lLinter.Analyze(lSchema);

    lHasRequiredConflict := False;
    for lFinding in lFindings do
    begin
      if (lFinding.RuleId = 'LINT_REQUIRED_MISSING') and (lFinding.Message.Contains('username') or lFinding.Message.Contains('email')) then
        lHasRequiredConflict := True;
    end;

    CheckTrue(lHasRequiredConflict, 'Should detect properties missing from "properties" but listed in "required"');
  finally
    lLinter.Free;
    lSchema.Free;
  end;
end;

procedure TTestSchemaLinter.TestLegacyKeywords;
var
  lLinter: TSchemaLinter;
  lSchema: TJSONObject;
  lFindings: TArray<TLintFinding>;
  lHasDefs, lHasDeps: Boolean;
  lFinding: TLintFinding;
begin
  lSchema := TJSONObject.ParseJSONValue(
    '{' +
    '  "definitions": {' +
    '    "Address": {"type": "object"}' +
    '  },' +
    '  "dependencies": {' +
    '    "credit_card": ["billing_address"]' +
    '  }' +
    '}'
  ) as TJSONObject;

  lLinter := TSchemaLinter.Create;
  try
    lLinter.MinSeverity := TSeverity.Info;
    lFindings := lLinter.Analyze(lSchema);

    lHasDefs := False;
    lHasDeps := False;

    for lFinding in lFindings do
    begin
      if (lFinding.RuleId = 'LINT_DEPRECATED_KEYWORD') and (lFinding.Message.Contains('definitions')) then
        lHasDefs := True;
      if (lFinding.RuleId = 'LINT_DEPRECATED_KEYWORD') and (lFinding.Message.Contains('dependencies')) then
        lHasDeps := True;
    end;

    CheckTrue(lHasDefs, 'Should warn about "definitions" deprecation');
    CheckTrue(lHasDeps, 'Should warn about "dependencies" deprecation');
  finally
    lLinter.Free;
    lSchema.Free;
  end;
end;

procedure TTestSchemaLinter.TestMissingDocumentation;
var
  lLinter: TSchemaLinter;
  lSchema: TJSONObject;
  lFindings: TArray<TLintFinding>;
  lHasRootTitle, lHasPropDesc: Boolean;
  lFinding: TLintFinding;
begin
  // Root missing title, and prop "status" missing description
  lSchema := TJSONObject.ParseJSONValue(
    '{' +
    '  "type": "object",' +
    '  "properties": {' +
    '    "id": {"type": "integer", "description": "Identifier"},' +
    '    "status": {"type": "string"}' +
    '  }' +
    '}'
  ) as TJSONObject;

  lLinter := TSchemaLinter.Create;
  try
    lLinter.MinSeverity := TSeverity.Info;
    lFindings := lLinter.Analyze(lSchema);

    lHasRootTitle := False;
    lHasPropDesc := False;

    for lFinding in lFindings do
    begin
      if (lFinding.RuleId = 'LINT_MISSING_TITLE') and (lFinding.Path = '/') then
        lHasRootTitle := True;
      if (lFinding.RuleId = 'LINT_MISSING_DESC') and (lFinding.Path = '/properties/status') then
        lHasPropDesc := True;
    end;

    CheckTrue(lHasRootTitle, 'Should detect missing root title');
    CheckTrue(lHasPropDesc, 'Should detect missing property description');
  finally
    lLinter.Free;
    lSchema.Free;
  end;
end;

procedure TTestSchemaLinter.TestRegexReDoS;
var
  lLinter: TSchemaLinter;
  lSchema: TJSONObject;
  lFindings: TArray<TLintFinding>;
  lHasReDoS: Boolean;
  lFinding: TLintFinding;
begin
  lSchema := TJSONObject.ParseJSONValue(
    '{' +
    '  "type": "object",' +
    '  "properties": {' +
    '    "unsafe": {"type": "string", "pattern": "^(a+)+$"}' +
    '  }' +
    '}'
  ) as TJSONObject;

  lLinter := TSchemaLinter.Create;
  try
    lLinter.MinSeverity := TSeverity.Info;
    lFindings := lLinter.Analyze(lSchema);

    lHasReDoS := False;
    for lFinding in lFindings do
    begin
      if lFinding.RuleId = 'LINT_REGEX_REDOS' then
        lHasReDoS := True;
    end;

    CheckTrue(lHasReDoS, 'Should detect ReDoS pattern in regex pattern string');
  finally
    lLinter.Free;
    lSchema.Free;
  end;
end;

procedure TTestSchemaLinter.TestCLIExecution;
var
  lExitCode: Integer;
  lStdout: string;
  lStderr: string;
  lTempFile: string;
begin
  // Create a JSON schema that has a logical conflict (minimum > maximum), which should trigger exit code 1 due to Error
  CreateTempFile(
    '{' +
    '  "title": "InvalidSchema",' +
    '  "type": "object",' +
    '  "properties": {' +
    '    "age": {"type": "integer", "minimum": 100, "maximum": 50}' +
    '  }' +
    '}', lTempFile);
  try
    lExitCode := RunCLI(Format('-s "%s"', [lTempFile]), lStdout, lStderr);
    CheckEquals(1, lExitCode, 'Should return exit code 1 on logical error findings');
    CheckTrue(lStdout.Contains('LINT_MIN_MAX_CONFLICT'), 'CLI stdout should report the min/max conflict');
  finally
    DeleteTempFile(lTempFile);
  end;
end;

initialization
  RegisterTest(TTestSchemaLinter.Suite);

end.
