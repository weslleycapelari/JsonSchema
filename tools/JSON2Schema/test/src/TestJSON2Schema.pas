unit TestJSON2Schema;

(*
--------------------------------------------------------------------------------
Unit and integration tests for the JSON2Schema engine and CLI utility.
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
  /// <summary>Unit and integration tests checking JSON2Schema inference logic.</summary>
  TTestJSON2Schema = class(TTestCase)
  strict private
    function RunCLI(const pArgs: string; out pStdout, pStderr: string): Integer;
    procedure CreateTempFile(const pContent: string; out pPath: string);
    procedure DeleteTempFile(const pPath: string);
  published
    /// <summary>Tests primitive type mapping (null, boolean, integers, floats, strings).</summary>
    procedure TestPrimitiveTypes;

    /// <summary>Tests format detection based on string patterns.</summary>
    procedure TestFormatDetection;

    /// <summary>Tests complex structure inference (objects, homogeneous and heterogeneous arrays).</summary>
    procedure TestComplexTypes;

    /// <summary>Tests CLI executable parsing and execution.</summary>
    procedure TestCLIExecution;
  end;

implementation

uses
  System.IOUtils,
  JSON2Schema.Engine,
  JSON2Schema.Config;

{ TTestJSON2Schema }

function TTestJSON2Schema.RunCLI(const pArgs: string; out pStdout, pStderr: string): Integer;
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

  lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\.bin\JSON2SchemaCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\JSON2SchemaCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\JSON2SchemaCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + 'JSON2SchemaCLI.exe');

  if not FileExists(lExePath) then
    raise Exception.CreateFmt('JSON2SchemaCLI executable not found at: %s', [lExePath]);

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

procedure TTestJSON2Schema.CreateTempFile(const pContent: string; out pPath: string);
var
  lTempFolder: array[0..MAX_PATH] of Char;
  lTempFile: array[0..MAX_PATH] of Char;
begin
  GetTempPath(MAX_PATH, lTempFolder);
  GetTempFileName(lTempFolder, 'sch', 0, lTempFile);
  pPath := lTempFile;
  TFile.WriteAllText(pPath, pContent, TEncoding.UTF8);
end;

procedure TTestJSON2Schema.DeleteTempFile(const pPath: string);
begin
  if FileExists(pPath) then
    System.SysUtils.DeleteFile(pPath);
end;

procedure TTestJSON2Schema.TestPrimitiveTypes;
var
  lGen: TJSON2SchemaGenerator;
  lVal: TJSONValue;
  lSchema: TJSONObject;
begin
  lGen := TJSON2SchemaGenerator.Create;
  try
    // Test Null
    lVal := TJSONNull.Create;
    try
      lSchema := lGen.GenerateSchema(lVal);
      try
        CheckEquals('null', lSchema.Values['type'].Value);
      finally
        lSchema.Free;
      end;
    finally
      lVal.Free;
    end;

    // Test Boolean
    lVal := TJSONTrue.Create;
    try
      lSchema := lGen.GenerateSchema(lVal);
      try
        CheckEquals('boolean', lSchema.Values['type'].Value);
      finally
        lSchema.Free;
      end;
    finally
      lVal.Free;
    end;

    // Test Integer
    lVal := TJSONNumber.Create(42);
    try
      lSchema := lGen.GenerateSchema(lVal);
      try
        CheckEquals('integer', lSchema.Values['type'].Value);
      finally
        lSchema.Free;
      end;
    finally
      lVal.Free;
    end;

    // Test Number
    lVal := TJSONNumber.Create(3.1415);
    try
      lSchema := lGen.GenerateSchema(lVal);
      try
        CheckEquals('number', lSchema.Values['type'].Value);
      finally
        lSchema.Free;
      end;
    finally
      lVal.Free;
    end;

    // Test String
    lVal := TJSONString.Create('hello');
    try
      lSchema := lGen.GenerateSchema(lVal);
      try
        CheckEquals('string', lSchema.Values['type'].Value);
        CheckNull(lSchema.Values['format'], 'No format should be detected for standard string');
      finally
        lSchema.Free;
      end;
    finally
      lVal.Free;
    end;

  finally
    lGen.Free;
  end;
end;

procedure TTestJSON2Schema.TestFormatDetection;
var
  lGen: TJSON2SchemaGenerator;
  lVal: TJSONValue;
  lSchema: TJSONObject;
begin
  lGen := TJSON2SchemaGenerator.Create;
  try
    // DateTime format check
    lVal := TJSONString.Create('2026-06-05T15:00:00Z');
    try
      lSchema := lGen.GenerateSchema(lVal);
      try
        CheckEquals('string', lSchema.Values['type'].Value);
        CheckEquals('date-time', lSchema.Values['format'].Value);
      finally
        lSchema.Free;
      end;
    finally
      lVal.Free;
    end;

    // Email format check
    lVal := TJSONString.Create('weslley@domain.com');
    try
      lSchema := lGen.GenerateSchema(lVal);
      try
        CheckEquals('string', lSchema.Values['type'].Value);
        CheckEquals('email', lSchema.Values['format'].Value);
      finally
        lSchema.Free;
      end;
    finally
      lVal.Free;
    end;

    // UUID format check
    lVal := TJSONString.Create('e9b56f5d-121f-433e-bdc7-e7a4a28df76b');
    try
      lSchema := lGen.GenerateSchema(lVal);
      try
        CheckEquals('string', lSchema.Values['type'].Value);
        CheckEquals('uuid', lSchema.Values['format'].Value);
      finally
        lSchema.Free;
      end;
    finally
      lVal.Free;
    end;

    // Test format detection disabled
    lVal := TJSONString.Create('weslley@domain.com');
    try
      lGen.Options := Default(TJSON2SchemaOptions); // InferFormats defaults to False if default record initialized
      lSchema := lGen.GenerateSchema(lVal);
      try
        CheckEquals('string', lSchema.Values['type'].Value);
        CheckNull(lSchema.Values['format'], 'Format detection should be disabled');
      finally
        lSchema.Free;
      end;
    finally
      lVal.Free;
    end;

  finally
    lGen.Free;
  end;
end;

procedure TTestJSON2Schema.TestComplexTypes;
var
  lGen: TJSON2SchemaGenerator;
  lVal: TJSONValue;
  lSchema: TJSONObject;
  lProps: TJSONObject;
  lOptions: TJSON2SchemaOptions;
begin
  lGen := TJSON2SchemaGenerator.Create;
  try
    // Test Object with properties
    lVal := TJSONObject.ParseJSONValue('{"id":1,"name":"Acme"}');
    try
      lSchema := lGen.GenerateSchema(lVal);
      try
        CheckEquals('object', lSchema.Values['type'].Value);
        lProps := lSchema.Values['properties'] as TJSONObject;
        CheckNotNull(lProps, 'Properties node should exist');
        CheckEquals('integer', TJSONObject(lProps.Values['id']).Values['type'].Value);
        CheckEquals('string', TJSONObject(lProps.Values['name']).Values['type'].Value);
        CheckNull(lSchema.Values['required'], 'Required property should be null by default');
      finally
        lSchema.Free;
      end;
    finally
      lVal.Free;
    end;

    // Test Object with required enabled
    lVal := TJSONObject.ParseJSONValue('{"id":1}');
    try
      lOptions.Draft := 'http://json-schema.org/draft-07/schema#';
      lOptions.InferFormats := True;
      lOptions.MakeRequired := True;
      lGen.Options := lOptions;

      lSchema := lGen.GenerateSchema(lVal);
      try
        CheckNotNull(lSchema.Values['required'], 'Required array should exist');
        CheckEquals('id', (lSchema.Values['required'] as TJSONArray).Items[0].Value);
      finally
        lSchema.Free;
      end;
    finally
      lVal.Free;
    end;

    // Test homogeneous Array
    lVal := TJSONObject.ParseJSONValue('[1, 2, 3]');
    try
      lSchema := lGen.GenerateSchema(lVal);
      try
        CheckEquals('array', lSchema.Values['type'].Value);
        CheckEquals('integer', TJSONObject(lSchema.Values['items']).Values['type'].Value);
      finally
        lSchema.Free;
      end;
    finally
      lVal.Free;
    end;

    // Test heterogeneous Array
    lVal := TJSONObject.ParseJSONValue('[1, "hello"]');
    try
      lSchema := lGen.GenerateSchema(lVal);
      try
        CheckEquals('array', lSchema.Values['type'].Value);
        CheckNotNull(TJSONObject(lSchema.Values['items']).Values['anyOf'], 'Items should contain anyOf array');
      finally
        lSchema.Free;
      end;
    finally
      lVal.Free;
    end;

  finally
    lGen.Free;
  end;
end;

procedure TTestJSON2Schema.TestCLIExecution;
var
  lExitCode: Integer;
  lStdout: string;
  lStderr: string;
  lTempFile: string;
begin
  CreateTempFile('{"id": 999, "email": "help@domain.org"}', lTempFile);
  try
    lExitCode := RunCLI(Format('-i "%s" --required', [lTempFile]), lStdout, lStderr);
    CheckEquals(0, lExitCode);
    CheckTrue(lStdout.Contains('"$schema"'), 'CLI output must contain schema declaration');
    CheckTrue(lStdout.Contains('"type": "object"'), 'CLI output must identify object type');
    CheckTrue(lStdout.Contains('"required"'), 'CLI output must contain required fields array');
  finally
    DeleteTempFile(lTempFile);
  end;
end;

initialization
  RegisterTest(TTestJSON2Schema.Suite);

end.
