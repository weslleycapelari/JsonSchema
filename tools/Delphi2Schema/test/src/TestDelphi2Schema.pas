unit TestDelphi2Schema;

(*
--------------------------------------------------------------------------------
Unit and integration tests for the Delphi2Schema engine and CLI utility.
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
  /// <summary>Unit tests checking Delphi2Schema engine, mapping, and CLI execution.</summary>
  TTestDelphi2Schema = class(TTestCase)
  strict private
    /// <summary>Runs the CLI binary and captures exit code, stdout, and stderr.</summary>
    function RunCLI(const pArgs: string; out pStdout, pStderr: string): Integer;
  published
    /// <summary>Tests schema generation for basic types, nested classes, and arrays.</summary>
    procedure TestSchemaGeneration;

    /// <summary>Tests generation options like UseEnumNames and Field vs Property scanning.</summary>
    procedure TestGeneratorOptions;

    /// <summary>Tests CLI execution of Delphi2SchemaCLI.exe using built-in samples.</summary>
    procedure TestCLIExecution;
  end;

implementation

uses
  Delphi2Schema.Engine,
  Delphi2Schema.Samples,
  Delphi2Schema.Config;

{ TTestDelphi2Schema }

function TTestDelphi2Schema.RunCLI(const pArgs: string; out pStdout, pStderr: string): Integer;
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

  lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\.bin\Delphi2SchemaCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\Delphi2SchemaCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\Delphi2SchemaCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + 'Delphi2SchemaCLI.exe');

  if not FileExists(lExePath) then
    raise Exception.CreateFmt('Delphi2SchemaCLI executable not found at: %s', [lExePath]);

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

procedure TTestDelphi2Schema.TestSchemaGeneration;
var
  lGen: TDelphi2SchemaGenerator;
  lSchema: TJSONObject;
  lProps: TJSONObject;
  lPropId: TJSONObject;
  lPropName: TJSONObject;
  lPropEmail: TJSONObject;
  lPropAddress: TJSONObject;
  lPropTags: TJSONObject;
  lReqArray: TJSONArray;
  lIndex: Integer;
  lFound: Boolean;
begin
  lGen := TDelphi2SchemaGenerator.Create;
  try
    lSchema := lGen.GenerateSchema(TypeInfo(TSampleUser));
    try
      // Verify schema header and type
      CheckEquals('http://json-schema.org/draft-07/schema#', lSchema.GetValue('$schema').Value);
      CheckEquals('object', lSchema.GetValue('type').Value);
      CheckEquals('SampleUser', lSchema.GetValue('title').Value);

      // Verify properties existence
      lProps := lSchema.GetValue('properties') as TJSONObject;
      CheckNotNull(lProps, 'Properties object must exist');

      // ID property validation
      lPropId := lProps.GetValue('Id') as TJSONObject;
      CheckNotNull(lPropId, 'Id property must exist');
      CheckEquals('integer', lPropId.GetValue('type').Value);
      CheckEquals('1.0', lPropId.GetValue('minimum').Value);

      // Name property validation
      lPropName := lProps.GetValue('Name') as TJSONObject;
      CheckNotNull(lPropName, 'Name property must exist');
      CheckEquals('string', lPropName.GetValue('type').Value);
      CheckEquals('50', lPropName.GetValue('maxLength').Value);

      // Email property validation
      lPropEmail := lProps.GetValue('Email') as TJSONObject;
      CheckNotNull(lPropEmail, 'Email property must exist');
      CheckEquals('string', lPropEmail.GetValue('type').Value);
      CheckEquals('email', lPropEmail.GetValue('format').Value);

      // Required fields list validation
      lReqArray := lSchema.GetValue('required') as TJSONArray;
      CheckNotNull(lReqArray, 'Required list must exist');
      CheckEquals(3, lReqArray.Count);

      lFound := False;
      for lIndex := 0 to lReqArray.Count - 1 do
        if SameText(lReqArray.Items[lIndex].Value, 'Id') then
          lFound := True;
      CheckTrue(lFound, 'Id should be required');

      // Address nested class validation
      lPropAddress := lProps.GetValue('Address') as TJSONObject;
      CheckNotNull(lPropAddress, 'Address nested property must exist');
      CheckEquals('object', lPropAddress.GetValue('type').Value);

      // Tags array validation
      lPropTags := lProps.GetValue('Tags') as TJSONObject;
      CheckNotNull(lPropTags, 'Tags array property must exist');
      CheckEquals('array', lPropTags.GetValue('type').Value);
      CheckEquals('string', (lPropTags.GetValue('items') as TJSONObject).GetValue('type').Value);

    finally
      lSchema.Free;
    end;
  finally
    lGen.Free;
  end;
end;

procedure TTestDelphi2Schema.TestGeneratorOptions;
var
  lGen: TDelphi2SchemaGenerator;
  lSchema: TJSONObject;
  lProps: TJSONObject;
  lPropStatus: TJSONObject;
  lEnumVals: TJSONArray;
begin
  lGen := TDelphi2SchemaGenerator.Create;
  try
    // Test Option 1: Use enum names (Default)
    lGen.UseEnumNames := True;
    lSchema := lGen.GenerateSchema(TypeInfo(TSampleUser));
    try
      lProps := lSchema.GetValue('properties') as TJSONObject;
      lPropStatus := lProps.GetValue('Status') as TJSONObject;
      CheckEquals('string', lPropStatus.GetValue('type').Value);
      lEnumVals := lPropStatus.GetValue('enum') as TJSONArray;
      CheckNotNull(lEnumVals, 'enum array must exist when using names');
      CheckEquals(3, lEnumVals.Count);
      CheckEquals('Pendente', lEnumVals.Items[0].Value);
      CheckEquals('Aprovado', lEnumVals.Items[1].Value);
      CheckEquals('Rejeitado', lEnumVals.Items[2].Value);
    finally
      lSchema.Free;
    end;

    // Test Option 2: Use integer enum values
    lGen.UseEnumNames := False;
    lSchema := lGen.GenerateSchema(TypeInfo(TSampleUser));
    try
      lProps := lSchema.GetValue('properties') as TJSONObject;
      lPropStatus := lProps.GetValue('Status') as TJSONObject;
      CheckEquals('integer', lPropStatus.GetValue('type').Value);
      CheckEquals('0', lPropStatus.GetValue('minimum').Value);
      CheckEquals('2', lPropStatus.GetValue('maximum').Value);
    finally
      lSchema.Free;
    end;
  finally
    lGen.Free;
  end;
end;

procedure TTestDelphi2Schema.TestCLIExecution;
var
  lExitCode: Integer;
  lStdout: string;
  lStderr: string;
  lJSON: TJSONObject;
begin
  // Execute CLI to export TSampleUser
  lExitCode := RunCLI('-t TSampleUser', lStdout, lStderr);
  CheckEquals(0, lExitCode);
  CheckTrue(lStdout.Contains('"$schema"'), 'Stdout must contain schema header');
  CheckTrue(lStdout.Contains('"title": "SampleUser"'), 'Stdout must contain SampleUser title');

  // Parse stdout and verify it is a valid JSON
  try
    lJSON := TJSONObject.ParseJSONValue(lStdout) as TJSONObject;
    try
      CheckNotNull(lJSON, 'Generated output must be a valid JSON Object');
      CheckEquals('SampleUser', lJSON.GetValue('title').Value);
    finally
      lJSON.Free;
    end;
  except
    on E: Exception do
      Fail('Failed to parse generated CLI output JSON: ' + E.Message);
  end;
end;

initialization
  RegisterTest(TTestDelphi2Schema.Suite);

end.
