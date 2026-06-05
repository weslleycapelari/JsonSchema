unit TestSchema2DDL;

(*
--------------------------------------------------------------------------------
Unit and integration tests for the Schema2DDL engine and CLI utility.
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
  /// <summary>Unit and integration tests checking Schema2DDL mapping and dialets.</summary>
  TTestSchema2DDL = class(TTestCase)
  strict private
    function RunCLI(const pArgs: string; out pStdout, pStderr: string): Integer;
    procedure CreateTempFile(const pContent: string; out pPath: string);
    procedure DeleteTempFile(const pPath: string);
  published
    /// <summary>Tests schema translating for PostgreSQL dialect.</summary>
    procedure TestPostgreSQLMapping;

    /// <summary>Tests schema translating for Firebird dialect.</summary>
    procedure TestFirebirdMapping;

    /// <summary>Tests nested objects and arrays relations (foreign key generation).</summary>
    procedure TestRelationalMappings;

    /// <summary>Tests CLI execution with schema file input.</summary>
    procedure TestCLIExecution;
  end;

implementation

uses
  System.IOUtils,
  Schema2DDL.Engine,
  Schema2DDL.Dialects,
  Schema2DDL.Config;

{ TTestSchema2DDL }

function TTestSchema2DDL.RunCLI(const pArgs: string; out pStdout, pStderr: string): Integer;
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

  lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\.bin\Schema2DDLCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\Schema2DDLCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\Schema2DDLCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + 'Schema2DDLCLI.exe');

  if not FileExists(lExePath) then
    raise Exception.CreateFmt('Schema2DDLCLI executable not found at: %s', [lExePath]);

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

procedure TTestSchema2DDL.CreateTempFile(const pContent: string; out pPath: string);
var
  lTempFolder: array[0..MAX_PATH] of Char;
  lTempFile: array[0..MAX_PATH] of Char;
begin
  GetTempPath(MAX_PATH, lTempFolder);
  GetTempFileName(lTempFolder, 'sch', 0, lTempFile);
  pPath := lTempFile;
  TFile.WriteAllText(pPath, pContent, TEncoding.UTF8);
end;

procedure TTestSchema2DDL.DeleteTempFile(const pPath: string);
begin
  if FileExists(pPath) then
    System.SysUtils.DeleteFile(pPath);
end;

procedure TTestSchema2DDL.TestPostgreSQLMapping;
var
  lGen: TSchema2DDLGenerator;
  lSchema: TJSONObject;
  lDdl: string;
begin
  lSchema := TJSONObject.ParseJSONValue(
    '{"title": "users", "type": "object", "properties": {' +
    '  "id": {"type": "integer"},' +
    '  "name": {"type": "string", "maxLength": 80},' +
    '  "email": {"type": "string", "format": "email"},' +
    '  "verified": {"type": "boolean", "default": false}' +
    '}, "required": ["id", "name"]}'
  ) as TJSONObject;

  lGen := TSchema2DDLGenerator.Create;
  try
    lGen.Dialect := TDialectFactory.CreateDialect('PostgreSQL');
    lGen.GenerateDropTable := True;
    lGen.AutoIncPk := True;

    lDdl := lGen.GenerateDDL(lSchema, '');
    
    CheckTrue(lDdl.Contains('DROP TABLE IF EXISTS users;'), 'Should contain drop table');
    CheckTrue(lDdl.Contains('CREATE TABLE users ('), 'Should contain create table users');
    CheckTrue(lDdl.Contains('id SERIAL PRIMARY KEY'), 'Should map integer PK auto-inc to SERIAL');
    CheckTrue(lDdl.Contains('name VARCHAR(80) NOT NULL'), 'Should map required string with length to VARCHAR NOT NULL');
    CheckTrue(lDdl.Contains('email TEXT'), 'Should map formatted string to default TEXT');
    CheckTrue(lDdl.Contains('verified BOOLEAN DEFAULT FALSE'), 'Should map boolean and default constraint');

  finally
    lGen.Free;
    lSchema.Free;
  end;
end;

procedure TTestSchema2DDL.TestFirebirdMapping;
var
  lGen: TSchema2DDLGenerator;
  lSchema: TJSONObject;
  lDdl: string;
begin
  lSchema := TJSONObject.ParseJSONValue(
    '{"title": "products", "type": "object", "properties": {' +
    '  "code": {"type": "integer", "x-pk": true},' +
    '  "description": {"type": "string"},' +
    '  "price": {"type": "number"}' +
    '}, "required": ["code"]}'
  ) as TJSONObject;

  lGen := TSchema2DDLGenerator.Create;
  try
    lGen.Dialect := TDialectFactory.CreateDialect('Firebird');
    lGen.AutoIncPk := True;

    lDdl := lGen.GenerateDDL(lSchema, '');

    CheckTrue(lDdl.Contains('CREATE TABLE products ('), 'Should contain create table products');
    CheckTrue(lDdl.Contains('code INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY'), 'Should map custom PK auto-inc in Firebird');
    CheckTrue(lDdl.Contains('description BLOB SUB_TYPE TEXT'), 'Should map long string to BLOB text in Firebird');
    CheckTrue(lDdl.Contains('price DOUBLE PRECISION'), 'Should map number to DOUBLE PRECISION in Firebird');

  finally
    lGen.Free;
    lSchema.Free;
  end;
end;

procedure TTestSchema2DDL.TestRelationalMappings;
var
  lGen: TSchema2DDLGenerator;
  lSchema: TJSONObject;
  lDdl: string;
begin
  lSchema := TJSONObject.ParseJSONValue(
    '{"title": "orders", "type": "object", "properties": {' +
    '  "id": {"type": "integer"},' +
    '  "customer": {' +
    '    "type": "object",' +
    '    "properties": {' +
    '      "name": {"type": "string"}' +
    '    }' +
    '  }' +
    '}}'
  ) as TJSONObject;

  lGen := TSchema2DDLGenerator.Create;
  try
    lGen.Dialect := TDialectFactory.CreateDialect('PostgreSQL');
    lGen.AutoIncPk := False;

    lDdl := lGen.GenerateDDL(lSchema, '');

    // Should generate child table orders_customer first, then parent table orders referencing it.
    CheckTrue(lDdl.Contains('CREATE TABLE orders_customer ('), 'Should generate nested child table');
    CheckTrue(lDdl.Contains('CREATE TABLE orders ('), 'Should generate parent table');
    CheckTrue(lDdl.Contains('customer_id INTEGER'), 'Should add child reference column');
    CheckTrue(lDdl.Contains('CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES orders_customer (id)'), 'Should link with foreign key constraint');

  finally
    lGen.Free;
    lSchema.Free;
  end;
end;

procedure TTestSchema2DDL.TestCLIExecution;
var
  lExitCode: Integer;
  lStdout: string;
  lStderr: string;
  lTempFile: string;
begin
  CreateTempFile(
    '{"title": "test", "type": "object", "properties": {"id": {"type": "integer"}}}',
    lTempFile
  );
  try
    lExitCode := RunCLI(Format('-s "%s" -d PostgreSQL --no-auto-inc', [lTempFile]), lStdout, lStderr);
    CheckEquals(0, lExitCode);
    CheckTrue(lStdout.Contains('CREATE TABLE test ('), 'CLI output must contain CREATE TABLE');
    CheckTrue(lStdout.Contains('id INTEGER PRIMARY KEY'), 'CLI output must contain PRIMARY KEY');
  finally
    DeleteTempFile(lTempFile);
  end;
end;

initialization
  RegisterTest(TTestSchema2DDL.Suite);

end.
