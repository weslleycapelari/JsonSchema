unit TestVisualTestSuiteRunner;

(*
--------------------------------------------------------------------------------
Unit and integration tests for the VisualTestSuiteRunner engine and CLI utility.
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
  /// <summary>Unit and integration tests checking VisualTestSuiteRunner features.</summary>
  TTestVisualTestSuiteRunner = class(TTestCase)
  strict private
    function RunCLI(const pArgs: string; out pStdout, pStderr: string): Integer;
    procedure DeleteTempFile(const pPath: string);
  published
    /// <summary>Tests draft version normalization and mapping.</summary>
    procedure TestDraftVersionParsing;

    /// <summary>Tests reading and validating test cases from a test file.</summary>
    procedure TestRunTestFile;

    /// <summary>Tests CLI execution of the test suite runner utility.</summary>
    procedure TestCLIExecution;
  end;

implementation

uses
  System.IOUtils,
  VisualTestSuiteRunner.Engine,
  VisualTestSuiteRunner.Config,
  JsonSchema.Core.Interfaces;

{ TTestVisualTestSuiteRunner }

function TTestVisualTestSuiteRunner.RunCLI(const pArgs: string; out pStdout, pStderr: string): Integer;
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

  lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\.bin\VisualTestSuiteRunnerCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\VisualTestSuiteRunnerCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\VisualTestSuiteRunnerCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + 'VisualTestSuiteRunnerCLI.exe');

  if not FileExists(lExePath) then
    raise Exception.CreateFmt('VisualTestSuiteRunnerCLI executable not found at: %s', [lExePath]);

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


procedure TTestVisualTestSuiteRunner.DeleteTempFile(const pPath: string);
begin
  if FileExists(pPath) then
    System.SysUtils.DeleteFile(pPath);
end;

procedure TTestVisualTestSuiteRunner.TestDraftVersionParsing;
var
  lRunner: TTestSuiteRunner;
begin
  lRunner := TTestSuiteRunner.Create('2020-12');
  try
    Check(lRunner.Draft = TDraftVersion.dvDraft2020_12, 'draft 2020-12 mapping');
  finally
    lRunner.Free;
  end;

  lRunner := TTestSuiteRunner.Create('draft7');
  try
    Check(lRunner.Draft = TDraftVersion.dvDraft7, 'draft7 mapping');
  finally
    lRunner.Free;
  end;

  lRunner := TTestSuiteRunner.Create('draft6');
  try
    Check(lRunner.Draft = TDraftVersion.dvDraft6, 'draft6 mapping');
  finally
    lRunner.Free;
  end;
end;

procedure TTestVisualTestSuiteRunner.TestRunTestFile;
var
  lRunner: TTestSuiteRunner;
  lTempFile: string;
  lTestJSON: string;
  lFileRes: TTestFileResult;
  lGroup: TTestGroupResult;
  lCase: TTestCaseResult;
begin
  lTestJSON := '[' +
    '  {' +
    '    "description": "minLength validation",' +
    '    "schema": { "minLength": 3 },' +
    '    "tests": [' +
    '      {' +
    '        "description": "longer is valid",' +
    '        "data": "foo",' +
    '        "valid": true' +
    '      },' +
    '      {' +
    '        "description": "too short is invalid",' +
    '        "data": "ab",' +
    '        "valid": false' +
    '      }' +
    '    ]' +
    '  }' +
    ']';

  lTempFile := TPath.Combine(TPath.GetTempPath, 'test_run_file.json');
  TFile.WriteAllText(lTempFile, lTestJSON, TEncoding.UTF8);
  try
    lRunner := TTestSuiteRunner.Create('2020-12');
    try
      lRunner.RunTestSuite(ExtractFilePath(lTempFile));
      
      Check(lRunner.SuiteResults.Count > 0, 'Should load files');
      lFileRes := lRunner.SuiteResults[0];
      CheckEquals(2, lFileRes.TotalTests, 'Total tests run');
      CheckEquals(2, lFileRes.PassCount, 'Total passed (our validador supports minLength)');
      
      lGroup := lFileRes.Groups[0];
      CheckEquals('minLength validation', lGroup.Description);
      CheckEquals(2, lGroup.Cases.Count);
      
      lCase := lGroup.Cases[0];
      CheckEquals('longer is valid', lCase.Description);
      CheckTrue(lCase.Passed, 'Test case passed');
      CheckTrue(lCase.ExpectedValid, 'Expected valid');
      CheckTrue(lCase.ActualValid, 'Actual valid');
    finally
      lRunner.Free;
    end;
  finally
    DeleteTempFile(lTempFile);
  end;
end;

procedure TTestVisualTestSuiteRunner.TestCLIExecution;
var
  lExitCode: Integer;
  lStdout: string;
  lStderr: string;
  lTempDir: string;
  lTempFile: string;
  lOutFile: string;
begin
  lTempDir := IncludeTrailingPathDelimiter(TPath.GetTempPath) + 'jss_testsuite_run';
  TDirectory.CreateDirectory(lTempDir);
  
  lTempFile := TPath.Combine(lTempDir, 'mock_test.json');
  TFile.WriteAllText(lTempFile, '[' +
    '  {' +
    '    "description": "type validation",' +
    '    "schema": { "type": "string" },' +
    '    "tests": [' +
    '      {' +
    '        "description": "string is valid",' +
    '        "data": "hello",' +
    '        "valid": true' +
    '      }' +
    '    ]' +
    '  }' +
    ']', TEncoding.UTF8);
  
  lOutFile := TPath.Combine(lTempDir, 'compliance.json');
  try
    lExitCode := RunCLI(Format('-i "%s" -d "2020-12" -o "%s" --quiet', [lTempDir, lOutFile]), lStdout, lStderr);
    CheckEquals(0, lExitCode, 'CLI should exit with 0 since our engine validates type string successfully');
    CheckTrue(TFile.Exists(lOutFile), 'Output compliance report should be written');
  finally
    if TDirectory.Exists(lTempDir) then
      TDirectory.Delete(lTempDir, True);
  end;
end;

initialization
  RegisterTest(TTestVisualTestSuiteRunner.Suite);

end.
