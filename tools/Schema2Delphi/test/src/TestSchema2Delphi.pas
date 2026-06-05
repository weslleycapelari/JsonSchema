unit TestSchema2Delphi;

(*
--------------------------------------------------------------------------------
DUnit unit test cases for Schema2Delphi code generator, asserting correct AST
traversal, output code generation, configuration parsing, and CLI process execution.
--------------------------------------------------------------------------------
*)

interface

uses
  TestFramework,
  System.JSON,
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  Schema2Delphi.Visitor,
  Schema2Delphi.Utils,
  Schema2Delphi.Common;

type
  TTestSchema2Delphi = class(TTestCase)
  strict private
    FSchema: TJSONObject;
    function RunCLI(const pArgs: string; out pStdout, pStderr: string): Integer;
    procedure CreateTempFile(const pContent: string; out pPath: string);
    procedure DeleteTempFile(const pPath: string);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestClassGenerationBasic;
    procedure TestClassGenerationNullableAndReserved;
    procedure TestRecordGenerationReverseOrder;
    procedure TestParseArguments;
    procedure TestCLIExecution;
  end;

implementation

uses
  System.StrUtils,
  Schema2Delphi.Config;

const
  TEST_SCHEMA =
    '{' +
    '  "$id": "https://example.com/test-schema.json",' +
    '  "type": "object",' +
    '  "properties": {' +
    '    "name": { "type": "string", "maxLength": 50, "description": "The person name" },' +
    '    "type": { "type": ["string", "null"] },' +
    '    "age": { "type": ["integer", "null"] },' +
    '    "isActive": { "type": ["boolean", "null"] },' +
    '    "friends": {' +
    '      "type": "array",' +
    '      "items": {' +
    '        "type": "object",' +
    '        "properties": {' +
    '          "name": { "type": "string" },' +
    '          "age": { "type": "integer" }' +
    '        }' +
    '      }' +
    '    },' +
    '    "status": {' +
    '      "enum": ["active", "inactive"]' +
    '    }' +
    '  },' +
    '  "required": ["name"]' +
    '}';

{ TTestSchema2Delphi }

procedure TTestSchema2Delphi.SetUp;
begin
  inherited;
  FSchema := TJSONObject.ParseJSONValue(TEST_SCHEMA) as TJSONObject;
end;

procedure TTestSchema2Delphi.TearDown;
begin
  FSchema.Free;
  inherited;
end;

function TTestSchema2Delphi.RunCLI(const pArgs: string; out pStdout, pStderr: string): Integer;
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

  lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\Schema2Delphi.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\Schema2Delphi.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + 'Schema2Delphi.exe');

  if not FileExists(lExePath) then
    raise Exception.CreateFmt('Schema2Delphi executable not found at: %s', [lExePath]);

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

procedure TTestSchema2Delphi.CreateTempFile(const pContent: string; out pPath: string);
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

procedure TTestSchema2Delphi.DeleteTempFile(const pPath: string);
begin
  if (pPath <> '') and FileExists(pPath) then
    System.SysUtils.DeleteFile(pPath);
end;

procedure TTestSchema2Delphi.TestClassGenerationBasic;
var
  lConfig: TCodeGeneratorConfig;
  lGeneratedPas: string;
begin
  lConfig := TCodeGeneratorConfig.DefaultConfig;
  lConfig.GenerationMode := gmClass;
  lConfig.UseNullableTypes := False;

  lGeneratedPas := GenerateClassFromSchema(FSchema, 'Person', 'GeneratedDTO', lConfig);

  CheckTrue(ContainsText(lGeneratedPas, 'unit GeneratedDTO;'), 'Should contain unit name');
  CheckTrue(ContainsText(lGeneratedPas, 'interface'), 'Should contain interface section');
  CheckTrue(ContainsText(lGeneratedPas, 'type'), 'Should contain type section');
  CheckTrue(ContainsText(lGeneratedPas, '  TPerson = class;'), 'Should contain forward declaration for TPerson');
  CheckTrue(ContainsText(lGeneratedPas, '  TFriends = class;'), 'Should contain forward declaration for TFriends');
  CheckTrue(ContainsText(lGeneratedPas, 'FName: string;'), 'Should contain FName field');
  CheckTrue(ContainsText(lGeneratedPas, 'property Name: string read FName write FName;'), 'Should contain Name property');
  CheckTrue(ContainsText(lGeneratedPas, 'FFriends: TArray<TFriends>;'), 'Should contain FFriends field');
  CheckTrue(ContainsText(lGeneratedPas, 'TStatus = ('), 'Should contain TStatus enum declaration');
  CheckTrue(ContainsText(lGeneratedPas, '    StatusActive,'), 'Should contain StatusActive enum value');
  CheckTrue(ContainsText(lGeneratedPas, '    StatusInactive'), 'Should contain StatusInactive enum value');
  CheckTrue(ContainsText(lGeneratedPas, 'destructor TPerson.Destroy;'), 'Should contain TPerson destructor implementation');
  CheckTrue(ContainsText(lGeneratedPas, 'for var lI := 0 to Length(FFriends) - 1 do'), 'Should contain loop to free array elements');
  CheckTrue(ContainsText(lGeneratedPas, 'FFriends[lI].Free;'), 'Should call Free on array elements');
end;

procedure TTestSchema2Delphi.TestClassGenerationNullableAndReserved;
var
  lConfig: TCodeGeneratorConfig;
  lGeneratedPas: string;
begin
  lConfig := TCodeGeneratorConfig.DefaultConfig;
  lConfig.GenerationMode := gmClass;
  lConfig.UseNullableTypes := True;
  lConfig.NullableTypeTemplate := 'TNullableValue<%s>';

  lGeneratedPas := GenerateClassFromSchema(FSchema, 'Person', 'GeneratedDTO', lConfig);

  CheckTrue(ContainsText(lGeneratedPas, 'FAge: TNullableValue<Integer>;'), 'Should wrap age in TNullableValue');
  CheckTrue(ContainsText(lGeneratedPas, 'FIsActive: TNullableValue<Boolean>;'), 'Should wrap isActive in TNullableValue');
  CheckTrue(ContainsText(lGeneratedPas, 'FAType: string;'), 'Should sanitize field name "type" to "FAType"');
  CheckTrue(ContainsText(lGeneratedPas, 'property AType: string read FAType write FAType;'), 'Should sanitize property name "type" to "AType"');
  CheckTrue(ContainsText(lGeneratedPas, '[JSONName(''type'')]'), 'Should add JSONName attribute for sanitized property');
  CheckTrue(ContainsText(lGeneratedPas, '[JsonSchema_Required]'), 'Should add JsonSchema_Required attribute');
  CheckTrue(ContainsText(lGeneratedPas, '[TJsonSchemaMaxLength(50)]'), 'Should add TJsonSchemaMaxLength attribute');
  CheckTrue(ContainsText(lGeneratedPas, '[TJsonSchemaDescription(''The person name'')]'), 'Should add TJsonSchemaDescription attribute');
end;

procedure TTestSchema2Delphi.TestRecordGenerationReverseOrder;
var
  lConfig: TCodeGeneratorConfig;
  lGeneratedPas: string;
  lFriendsIdx, lPersonIdx: Integer;
begin
  lConfig := TCodeGeneratorConfig.DefaultConfig;
  lConfig.GenerationMode := gmRecord;

  lGeneratedPas := GenerateClassFromSchema(FSchema, 'PersonRecord', 'GeneratedDTORecord', lConfig);

  CheckTrue(ContainsText(lGeneratedPas, 'TPersonRecord = record'), 'Should contain TPersonRecord record declaration');
  CheckTrue(ContainsText(lGeneratedPas, 'TFriends = record'), 'Should contain TFriends record declaration');

  lFriendsIdx := Pos('TFriends = record', lGeneratedPas);
  lPersonIdx := Pos('TPersonRecord = record', lGeneratedPas);

  CheckTrue(lFriendsIdx > 0, 'TFriends declaration not found');
  CheckTrue(lPersonIdx > 0, 'TPersonRecord declaration not found');
  CheckTrue(lFriendsIdx < lPersonIdx, 'TFriends must be declared before TPersonRecord to compile correctly');
end;

procedure TTestSchema2Delphi.TestParseArguments;
var
  lConfig: TConfig;
begin
  lConfig := ParseArgumentsEx([]);
  CheckEquals('', lConfig.SchemaPath);
  CheckEquals('', lConfig.OutputPath);
  CheckEquals('', lConfig.ClassName);
  CheckEquals('', lConfig.UnitName);
  CheckFalse(lConfig.ShowHelp);

  lConfig := ParseArgumentsEx(['-s', 'schema.json', '-o', 'out.pas', '-c', 'Customer', '-u', 'CustUnit']);
  CheckEquals('schema.json', lConfig.SchemaPath);
  CheckEquals('out.pas', lConfig.OutputPath);
  CheckEquals('Customer', lConfig.ClassName);
  CheckEquals('CustUnit', lConfig.UnitName);
end;

procedure TTestSchema2Delphi.TestCLIExecution;
var
  lSchemaPath, lOutputPath: string;
  lStdout, lStderr: string;
  lExitCode: Integer;
  lOutCode: string;
  lList: TStringList;
begin
  CreateTempFile(TEST_SCHEMA, lSchemaPath);
  lOutputPath := ExpandFileName(ExtractFilePath(lSchemaPath) + 'TestGenDTO.pas');
  try
    lExitCode := RunCLI(Format('-s "%s" -o "%s" -c Customer -u TestGenDTO', [lSchemaPath, lOutputPath]), lStdout, lStderr);
    CheckEquals(0, lExitCode, 'Exit code should be 0 on success');
    Check(FileExists(lOutputPath), 'Generated DTO unit should be created');

    lList := TStringList.Create;
    try
      lList.LoadFromFile(lOutputPath, TEncoding.UTF8);
      lOutCode := lList.Text;
    finally
      lList.Free;
    end;

    CheckTrue(ContainsText(lOutCode, 'unit TestGenDTO;'), 'Generated file should contain unit declaration');
    CheckTrue(ContainsText(lOutCode, 'TCustomer = class;'), 'Generated file should contain class TCustomer');
  finally
    DeleteTempFile(lSchemaPath);
    DeleteTempFile(lOutputPath);
  end;
end;

initialization
  RegisterTest(TTestSchema2Delphi.Suite);

end.
