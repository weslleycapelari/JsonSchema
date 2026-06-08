unit TestSchema2REST;

(*
--------------------------------------------------------------------------------
Unit and integration tests for the Schema2REST engine and CLI utility.
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
  /// <summary>Unit and integration tests checking Schema2REST code generation.</summary>
  TTestSchema2REST = class(TTestCase)
  strict private
    function RunCLI(const pArgs: string; out pStdout, pStderr: string): Integer;
    procedure CreateTempFile(const pContent: string; out pPath: string);
    procedure DeleteTempFile(const pPath: string);
  published
    /// <summary>Tests schema translating for Horse framework router code.</summary>
    procedure TestHorseRESTGeneration;

    /// <summary>Tests schema translating for DMVC framework controller code.</summary>
    procedure TestDMVCRESTGeneration;

    /// <summary>Tests CLI execution with schema file input.</summary>
    procedure TestCLIExecution;

    /// <summary>Tests parser command line configurations.</summary>
    procedure TestParseArguments;
  end;

implementation

uses
  System.IOUtils,
  Schema2REST.Engine,
  Schema2REST.Templates,
  Schema2REST.Config;

{ TTestSchema2REST }

function TTestSchema2REST.RunCLI(const pArgs: string; out pStdout, pStderr: string): Integer;
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

  lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\.bin\Schema2RESTCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\Schema2RESTCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\Schema2RESTCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + 'Schema2RESTCLI.exe');

  if not FileExists(lExePath) then
    raise Exception.CreateFmt('Schema2RESTCLI executable not found at: %s', [lExePath]);

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

procedure TTestSchema2REST.CreateTempFile(const pContent: string; out pPath: string);
var
  lTempFolder: array[0..MAX_PATH] of Char;
  lTempFile: array[0..MAX_PATH] of Char;
begin
  GetTempPath(MAX_PATH, lTempFolder);
  GetTempFileName(lTempFolder, 'sch', 0, lTempFile);
  pPath := lTempFile;
  TFile.WriteAllText(pPath, pContent, TEncoding.UTF8);
end;

procedure TTestSchema2REST.DeleteTempFile(const pPath: string);
begin
  if FileExists(pPath) then
    System.SysUtils.DeleteFile(pPath);
end;

procedure TTestSchema2REST.TestHorseRESTGeneration;
var
  lGen: TSchema2RESTGenerator;
  lSchema: TJSONObject;
  lPascal: string;
begin
  lSchema := TJSONObject.ParseJSONValue(
    '{"title": "User", "type": "object", "properties": {' +
    '  "id": {"type": "integer"},' +
    '  "name": {"type": "string"}' +
    '}, "required": ["id", "name"]}'
  ) as TJSONObject;

  lGen := TSchema2RESTGenerator.Create;
  try
    lGen.Framework := rfHorse;
    lPascal := lGen.GenerateRESTCode(lSchema, 'User');

    CheckTrue(lPascal.Contains('unit UserRouter;'), 'Should contain unit declaration');
    CheckTrue(lPascal.Contains('procedure RegistryUserRoutes;'), 'Should contain route registration interface');
    CheckTrue(lPascal.Contains('/user'), 'Should define route for /user');
    CheckTrue(lPascal.Contains('TJsonSchemaValidator.Create'), 'Should reference JSON Schema validator creation');
  finally
    lGen.Free;
    lSchema.Free;
  end;
end;

procedure TTestSchema2REST.TestDMVCRESTGeneration;
var
  lGen: TSchema2RESTGenerator;
  lSchema: TJSONObject;
  lPascal: string;
begin
  lSchema := TJSONObject.ParseJSONValue(
    '{"title": "Product", "type": "object", "properties": {' +
    '  "code": {"type": "integer"}' +
    '}, "required": ["code"]}'
  ) as TJSONObject;

  lGen := TSchema2RESTGenerator.Create;
  try
    lGen.Framework := rfDMVC;
    lPascal := lGen.GenerateRESTCode(lSchema, 'Product');

    CheckTrue(lPascal.Contains('unit ProductController;'), 'Should contain DMVC unit declaration');
    CheckTrue(lPascal.Contains('TProductController = class(TMVCController)'), 'Should inherit from TMVCController');
    CheckTrue(lPascal.Contains('[MVCPath(''/product'')]'), 'Should define MVCPath attribute');
    CheckTrue(lPascal.Contains('[MVCProduces(''application/json'')]'), 'Should specify application/json response');
    CheckTrue(lPascal.Contains('TJsonSchemaValidator.Create'), 'Should reference JSON Schema validator creation');
  finally
    lGen.Free;
    lSchema.Free;
  end;
end;

procedure TTestSchema2REST.TestCLIExecution;
var
  lExitCode: Integer;
  lStdout: string;
  lStderr: string;
  lTempFile: string;
begin
  CreateTempFile(
    '{"title": "customer", "type": "object", "properties": {"id": {"type": "integer"}}}',
    lTempFile
  );
  try
    lExitCode := RunCLI(Format('-s "%s" -f Horse -e Customer', [lTempFile]), lStdout, lStderr);
    CheckEquals(0, lExitCode);
    CheckTrue(lStdout.Contains('unit CustomerRouter;'), 'CLI output must contain router declaration');
    CheckTrue(lStdout.Contains('/customer'), 'CLI output must contain route for customer');
  finally
    DeleteTempFile(lTempFile);
  end;
end;

procedure TTestSchema2REST.TestParseArguments;
var
  lConfig: TSchema2RESTConfig;
begin
  lConfig := ParseCommandLineEx([]);
  CheckEquals('', lConfig.SchemaPath);
  CheckEquals('Horse', lConfig.Framework);
  CheckEquals('', lConfig.OutputPath);
  CheckEquals('', lConfig.EntityName);
  CheckFalse(lConfig.Quiet);
  CheckFalse(lConfig.ShowHelp);

  lConfig := ParseCommandLineEx(['-s', 'schema.json', '-f', 'DMVC', '-o', 'out.pas', '-e', 'Client', '--quiet']);
  CheckEquals('schema.json', lConfig.SchemaPath);
  CheckEquals('DMVC', lConfig.Framework);
  CheckEquals('out.pas', lConfig.OutputPath);
  CheckEquals('Client', lConfig.EntityName);
  CheckTrue(lConfig.Quiet);

  // Synonyms
  lConfig := ParseCommandLineEx(['-i', 'schema.json', '--framework', 'DMVC', '--output', 'out.pas', '--entity', 'Client']);
  CheckEquals('schema.json', lConfig.SchemaPath);
  CheckEquals('DMVC', lConfig.Framework);
  CheckEquals('out.pas', lConfig.OutputPath);
  CheckEquals('Client', lConfig.EntityName);

  // Fallback Positional Parameter
  lConfig := ParseCommandLineEx(['schema.json', '-o', 'out.pas']);
  CheckEquals('schema.json', lConfig.SchemaPath);
  CheckEquals('out.pas', lConfig.OutputPath);
end;

initialization
  RegisterTest(TTestSchema2REST.Suite);

end.
