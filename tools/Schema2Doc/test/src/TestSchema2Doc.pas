unit TestSchema2Doc;

(*
--------------------------------------------------------------------------------
Unit and integration tests for the Schema2Doc engine and CLI utility.
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
  /// <summary>Unit and integration tests checking Schema2Doc documentation rendering.</summary>
  TTestSchema2Doc = class(TTestCase)
  strict private
    function RunCLI(const pArgs: string; out pStdout, pStderr: string): Integer;
    procedure CreateTempFile(const pContent: string; out pPath: string);
    procedure DeleteTempFile(const pPath: string);
  published
    /// <summary>Tests schema rendering to Markdown format tables.</summary>
    procedure TestMarkdownRendering;

    /// <summary>Tests schema rendering to HTML pages with styling.</summary>
    procedure TestHTMLRendering;

    /// <summary>Tests CLI execution with schema input file.</summary>
    procedure TestCLIExecution;

    /// <summary>Tests parser command line configurations.</summary>
    procedure TestParseArguments;
  end;

implementation

uses
  System.IOUtils,
  Schema2Doc.Engine,
  Schema2Doc.Config;

{ TTestSchema2Doc }

function TTestSchema2Doc.RunCLI(const pArgs: string; out pStdout, pStderr: string): Integer;
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

  lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\.bin\Schema2DocCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\Schema2DocCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\Schema2DocCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + 'Schema2DocCLI.exe');

  if not FileExists(lExePath) then
    raise Exception.CreateFmt('Schema2DocCLI executable not found at: %s', [lExePath]);

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

procedure TTestSchema2Doc.CreateTempFile(const pContent: string; out pPath: string);
var
  lTempFolder: array[0..MAX_PATH] of Char;
  lTempFile: array[0..MAX_PATH] of Char;
begin
  GetTempPath(MAX_PATH, lTempFolder);
  GetTempFileName(lTempFolder, 'sch', 0, lTempFile);
  pPath := lTempFile;
  TFile.WriteAllText(pPath, pContent, TEncoding.UTF8);
end;

procedure TTestSchema2Doc.DeleteTempFile(const pPath: string);
begin
  if FileExists(pPath) then
    System.SysUtils.DeleteFile(pPath);
end;

procedure TTestSchema2Doc.TestMarkdownRendering;
var
  lGen: TSchema2DocGenerator;
  lSchema: TJSONObject;
  lDoc: string;
  lOptions: TSchema2DocOptions;
begin
  lSchema := TJSONObject.ParseJSONValue(
    '{"title": "User", "description": "System user accounts.", "type": "object", "properties": {' +
    '  "id": {"type": "integer", "description": "PK id"},' +
    '  "name": {"type": "string"}' +
    '}, "required": ["id"]}'
  ) as TJSONObject;

  lGen := TSchema2DocGenerator.Create;
  try
    lOptions.Format := dfMarkdown;
    lOptions.TitleOverride := '';
    lGen.Options := lOptions;
    lDoc := lGen.GenerateDoc(lSchema);

    CheckTrue(lDoc.Contains('# User'), 'Markdown should contain title header');
    CheckTrue(lDoc.Contains('System user accounts.'), 'Markdown should contain schema description');
    CheckTrue(lDoc.Contains('| Property | Type |'), 'Markdown should contain table headers');
    CheckTrue(lDoc.Contains('**id**'), 'Markdown should contain property names');
    CheckTrue(lDoc.Contains('`integer`'), 'Markdown should contain code type tags');
    CheckTrue(lDoc.Contains('Yes'), 'Markdown should show required yes status');
    CheckTrue(lDoc.Contains('No'), 'Markdown should show required no status');
  finally
    lGen.Free;
    lSchema.Free;
  end;
end;

procedure TTestSchema2Doc.TestHTMLRendering;
var
  lGen: TSchema2DocGenerator;
  lSchema: TJSONObject;
  lDoc: string;
  lOptions: TSchema2DocOptions;
begin
  lSchema := TJSONObject.ParseJSONValue(
    '{"title": "Order", "type": "object", "properties": {' +
    '  "total": {"type": "number", "default": 0.0}' +
    '}}'
  ) as TJSONObject;

  lGen := TSchema2DocGenerator.Create;
  try
    lOptions.Format := dfHTML;
    lOptions.TitleOverride := 'Sales Order Documentation';
    lGen.Options := lOptions;

    lDoc := lGen.GenerateDoc(lSchema);

    CheckTrue(lDoc.Contains('<!DOCTYPE html>'), 'HTML should contain doctype');
    CheckTrue(lDoc.Contains('<h1>Sales Order Documentation</h1>'), 'HTML should contain overridden title header');
    CheckTrue(lDoc.Contains('<span class="badge badge-number">number</span>'), 'HTML should render number type badge');
    CheckTrue(lDoc.Contains('<code>0.0</code>'), 'HTML should render default value code node');
  finally
    lGen.Free;
    lSchema.Free;
  end;
end;

procedure TTestSchema2Doc.TestCLIExecution;
var
  lExitCode: Integer;
  lStdout: string;
  lStderr: string;
  lTempFile: string;
begin
  CreateTempFile('{"title": "Customer", "type": "object", "properties": {"code": {"type": "integer"}}}', lTempFile);
  try
    lExitCode := RunCLI(Format('-s "%s" -f markdown -t "Client Documentation"', [lTempFile]), lStdout, lStderr);
    CheckEquals(0, lExitCode);
    CheckTrue(lStdout.Contains('# Client Documentation'), 'CLI stdout must contain overridden title');
    CheckTrue(lStdout.Contains('**code**'), 'CLI stdout must contain property descriptions');
  finally
    DeleteTempFile(lTempFile);
  end;
end;

procedure TTestSchema2Doc.TestParseArguments;
var
  lConfig: TSchema2DocConfig;
begin
  lConfig := ParseCommandLineEx([]);
  CheckEquals('', lConfig.SchemaPath);
  CheckEquals('', lConfig.OutputPath);
  CheckEquals('markdown', lConfig.Format);
  CheckEquals('', lConfig.TitleOverride);
  CheckFalse(lConfig.Quiet);
  CheckFalse(lConfig.ShowHelp);

  lConfig := ParseCommandLineEx(['-s', 'schema.json', '-o', 'out.md', '-f', 'html', '-t', 'Title', '--quiet']);
  CheckEquals('schema.json', lConfig.SchemaPath);
  CheckEquals('out.md', lConfig.OutputPath);
  CheckEquals('html', lConfig.Format);
  CheckEquals('Title', lConfig.TitleOverride);
  CheckTrue(lConfig.Quiet);

  // Synonyms
  lConfig := ParseCommandLineEx(['-i', 'schema.json', '--output', 'out.md', '--format', 'html', '--title', 'Title']);
  CheckEquals('schema.json', lConfig.SchemaPath);
  CheckEquals('out.md', lConfig.OutputPath);
  CheckEquals('html', lConfig.Format);
  CheckEquals('Title', lConfig.TitleOverride);

  // Fallback Positional Parameter
  lConfig := ParseCommandLineEx(['schema.json', '-o', 'out.md']);
  CheckEquals('schema.json', lConfig.SchemaPath);
  CheckEquals('out.md', lConfig.OutputPath);
end;

initialization
  RegisterTest(TTestSchema2Doc.Suite);

end.
