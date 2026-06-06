unit TestSchemaOptimizer;

(*
--------------------------------------------------------------------------------
Unit and integration tests for the SchemaOptimizer engine and CLI utility.
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
  /// <summary>Unit and integration tests checking SchemaOptimizer features.</summary>
  TTestSchemaOptimizer = class(TTestCase)
  strict private
    function RunCLI(const pArgs: string; out pStdout, pStderr: string): Integer;
    procedure CreateTempFile(const pContent: string; out pPath: string);
    procedure DeleteTempFile(const pPath: string);
  published
    /// <summary>Tests removing unused local definitions.</summary>
    procedure TestPruneUnusedDefs;

    /// <summary>Tests flattening nested allOf arrays and merging non-conflicting properties.</summary>
    procedure TestFlattenAndMergeAllOf;

    /// <summary>Tests pruning empty object schemas and deduplicating array types.</summary>
    procedure TestPruneEmptyAndDeduplicate;

    /// <summary>Tests CLI execution of the optimizer utility.</summary>
    procedure TestCLIExecution;
  end;

implementation

uses
  System.IOUtils,
  SchemaOptimizer.Engine,
  SchemaOptimizer.Config;

{ TTestSchemaOptimizer }

function TTestSchemaOptimizer.RunCLI(const pArgs: string; out pStdout, pStderr: string): Integer;
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

  lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\.bin\SchemaOptimizerCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\SchemaOptimizerCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\SchemaOptimizerCLI.exe');
  if not FileExists(lExePath) then
    lExePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + 'SchemaOptimizerCLI.exe');

  if not FileExists(lExePath) then
    raise Exception.CreateFmt('SchemaOptimizerCLI executable not found at: %s', [lExePath]);

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

procedure TTestSchemaOptimizer.CreateTempFile(const pContent: string; out pPath: string);
var
  lTempFolder: array[0..MAX_PATH] of Char;
  lTempFile: array[0..MAX_PATH] of Char;
begin
  GetTempPath(MAX_PATH, lTempFolder);
  GetTempFileName(lTempFolder, 'opt', 0, lTempFile);
  pPath := lTempFile;
  TFile.WriteAllText(pPath, pContent, TEncoding.UTF8);
end;

procedure TTestSchemaOptimizer.DeleteTempFile(const pPath: string);
begin
  if FileExists(pPath) then
    System.SysUtils.DeleteFile(pPath);
end;

procedure TTestSchemaOptimizer.TestPruneUnusedDefs;
var
  lOptions: TOptimizerOptions;
  lOptimizer: TSchemaOptimizer;
  lSchema: TJSONObject;
  lOutput: string;
  lJSON: TJSONObject;
  lDefs: TJSONObject;
  lBytesSaved: Int64;
  lDefsRemoved: Integer;
begin
  lSchema := TJSONObject.ParseJSONValue(
    '{' +
    '  "$defs": {' +
    '    "Used": {"type": "string"},' +
    '    "Unused": {"type": "number"},' +
    '    "IndirectUnused": {"$ref": "#/$defs/Unused"}' +
    '  },' +
    '  "properties": {' +
    '    "name": {"$ref": "#/$defs/Used"}' +
    '  }' +
    '}'
  ) as TJSONObject;

  lOptions.RemoveUnused := True;
  lOptions.MergeAllOf := False;
  lOptions.PruneEmpty := False;
  lOptions.Minify := True;

  lOptimizer := TSchemaOptimizer.Create(lOptions);
  try
    lOutput := lOptimizer.Optimize(lSchema, lBytesSaved, lDefsRemoved);
    lJSON := TJSONObject.ParseJSONValue(lOutput) as TJSONObject;
    try
      CheckEquals(2, lDefsRemoved, 'Should remove "Unused" and "IndirectUnused"');
      lDefs := lJSON.Values['$defs'] as TJSONObject;
      CheckNotNull(lDefs, '$defs should still exist');
      CheckNotNull(lDefs.Values['Used'], '"Used" definition must be preserved');
      CheckNull(lDefs.Values['Unused'], '"Unused" definition must be removed');
      CheckNull(lDefs.Values['IndirectUnused'], '"IndirectUnused" definition must be removed');
    finally
      lJSON.Free;
    end;
  finally
    lOptimizer.Free;
    lSchema.Free;
  end;
end;

procedure TTestSchemaOptimizer.TestFlattenAndMergeAllOf;
var
  lOptions: TOptimizerOptions;
  lOptimizer: TSchemaOptimizer;
  lSchema: TJSONObject;
  lOutput: string;
  lJSON: TJSONObject;
  lProps: TJSONObject;
  lRequired: TJSONArray;
  lBytesSaved: Int64;
  lDefsRemoved: Integer;
begin
  lSchema := TJSONObject.ParseJSONValue(
    '{' +
    '  "type": "object",' +
    '  "properties": {' +
    '    "id": {"type": "integer"}' +
    '  },' +
    '  "required": ["id"],' +
    '  "allOf": [' +
    '    {' +
    '      "properties": {' +
    '        "name": {"type": "string"}' +
    '      },' +
    '      "required": ["name"]' +
    '    },' +
    '    {' +
    '      "allOf": [' +
    '        {' +
    '          "properties": {' +
    '            "email": {"type": "string"}' +
    '          }' +
    '        }' +
    '      ]' +
    '    }' +
    '  ]' +
    '}'
  ) as TJSONObject;

  lOptions.RemoveUnused := False;
  lOptions.MergeAllOf := True;
  lOptions.PruneEmpty := False;
  lOptions.Minify := True;

  lOptimizer := TSchemaOptimizer.Create(lOptions);
  try
    lOutput := lOptimizer.Optimize(lSchema, lBytesSaved, lDefsRemoved);
    lJSON := TJSONObject.ParseJSONValue(lOutput) as TJSONObject;
    try
      CheckNull(lJSON.Values['allOf'], 'allOf array should be fully merged and removed');
      
      lProps := lJSON.Values['properties'] as TJSONObject;
      CheckNotNull(lProps.Values['id'], 'id property must exist');
      CheckNotNull(lProps.Values['name'], 'name property must be merged');
      CheckNotNull(lProps.Values['email'], 'email property must be flattened and merged');
      
      lRequired := lJSON.Values['required'] as TJSONArray;
      CheckNotNull(lRequired, 'required array must exist');
      CheckEquals(2, lRequired.Count, 'required array must contain 2 elements');
    finally
      lJSON.Free;
    end;
  finally
    lOptimizer.Free;
    lSchema.Free;
  end;
end;

procedure TTestSchemaOptimizer.TestPruneEmptyAndDeduplicate;
var
  lOptions: TOptimizerOptions;
  lOptimizer: TSchemaOptimizer;
  lSchema: TJSONObject;
  lOutput: string;
  lJSON: TJSONObject;
  lBytesSaved: Int64;
  lDefsRemoved: Integer;
begin
  lSchema := TJSONObject.ParseJSONValue(
    '{' +
    '  "type": ["string", "string"],' +
    '  "allOf": [' +
    '    {},' +
    '    {"minLength": 5},' +
    '    {"minLength": 5}' +
    '  ]' +
    '}'
  ) as TJSONObject;

  lOptions.RemoveUnused := False;
  lOptions.MergeAllOf := False;
  lOptions.PruneEmpty := True;
  lOptions.Minify := True;

  lOptimizer := TSchemaOptimizer.Create(lOptions);
  try
    lOutput := lOptimizer.Optimize(lSchema, lBytesSaved, lDefsRemoved);
    lJSON := TJSONObject.ParseJSONValue(lOutput) as TJSONObject;
    try
      CheckEquals('string', lJSON.Values['type'].Value, 'Type array with duplicate should be simplified to single type value');
      
      var lAllOf := lJSON.Values['allOf'] as TJSONArray;
      CheckNotNull(lAllOf, 'allOf should exist');
      CheckEquals(1, lAllOf.Count, 'Should contain only one minLength item, pruning {} and duplicates');
    finally
      lJSON.Free;
    end;
  finally
    lOptimizer.Free;
    lSchema.Free;
  end;
end;

procedure TTestSchemaOptimizer.TestCLIExecution;
var
  lExitCode: Integer;
  lStdout: string;
  lStderr: string;
  lTempFile: string;
  lOutFile: string;
  lJSON: TJSONObject;
begin
  CreateTempFile(
    '{' +
    '  "$defs": {' +
    '    "test": {"type": "string"}' +
    '  }' +
    '}', lTempFile);
  lOutFile := lTempFile + '.optimized';
  try
    lExitCode := RunCLI(Format('-i "%s" -o "%s"', [lTempFile, lOutFile]), lStdout, lStderr);
    CheckEquals(0, lExitCode, 'CLI should complete with code 0');
    CheckTrue(TFile.Exists(lOutFile), 'Output file must be generated');

    lJSON := TJSONObject.ParseJSONValue(TFile.ReadAllText(lOutFile, TEncoding.UTF8)) as TJSONObject;
    try
      CheckNull(lJSON.Values['$defs'], 'Unused $defs should be removed in optimized output');
    finally
      lJSON.Free;
    end;
  finally
    DeleteTempFile(lTempFile);
    DeleteTempFile(lOutFile);
  end;
end;

initialization
  RegisterTest(TTestSchemaOptimizer.Suite);

end.
