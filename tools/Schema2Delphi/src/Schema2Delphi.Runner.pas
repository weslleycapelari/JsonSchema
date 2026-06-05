unit Schema2Delphi.Runner;

(*
--------------------------------------------------------------------------------
Orchestrates CLI execution for Schema2Delphi code generation.
--------------------------------------------------------------------------------
*)

interface

uses
  System.Classes,
  System.JSON,
  System.SysUtils,
  Schema2Delphi.Config,
  Schema2Delphi.Utils;

/// <summary>Displays the CLI usage manual on stderr.</summary>
procedure PrintUsage;

/// <summary>Runs the Schema2Delphi CLI generator workflow.</summary>
/// <returns>Exit code: 0 for success, 2 for errors.</returns>
function RunSchema2Delphi: Integer;

implementation

procedure PrintUsage;
begin
  Writeln(ErrOutput, 'Schema2Delphi - JSON Schema to Delphi DTO Code Generator');
  Writeln(ErrOutput);
  Writeln(ErrOutput, 'Usage:');
  Writeln(ErrOutput, '  Schema2Delphi -s <schema_path> -o <output_path> [options]');
  Writeln(ErrOutput);
  Writeln(ErrOutput, 'Options:');
  Writeln(ErrOutput, '  -s, --schema      Path to the JSON Schema file (Required).');
  Writeln(ErrOutput, '  -o, --output      Path to save the generated Delphi unit file (Required).');
  Writeln(ErrOutput, '  -c, --classname   Name of the generated root class (Optional. Default: inferred).');
  Writeln(ErrOutput, '  -u, --unitname    Name of the generated Delphi unit (Optional. Default: inferred).');
  Writeln(ErrOutput, '  -h, --help        Display this help manual.');
  Writeln(ErrOutput);
end;

function RunSchema2Delphi: Integer;
var
  lConfig: TConfig;
  lSchemaStr: string;
  lSchemaObj: TJSONValue;
  lClassName: string;
  lUnitName: string;
  lGeneratedCode: string;
  lOutFile: TStringList;
begin
  Result := 2; // Default to error
  lConfig := ParseArguments;

  if lConfig.ShowHelp or lConfig.SchemaPath.IsEmpty or lConfig.OutputPath.IsEmpty then
  begin
    PrintUsage;
    if not lConfig.ShowHelp then
    begin
      if lConfig.SchemaPath.IsEmpty then
        Writeln(ErrOutput, 'Error: Missing required option: -s/--schema');
      if lConfig.OutputPath.IsEmpty then
        Writeln(ErrOutput, 'Error: Missing required option: -o/--output');
    end;
    Exit;
  end;

  // --- STEP 1: Load Schema ---
  if not FileExists(lConfig.SchemaPath) then
  begin
    Writeln(ErrOutput, Format('Error: Schema file not found: %s', [lConfig.SchemaPath]));
    Exit;
  end;

  try
    lOutFile := TStringList.Create;
    try
      lOutFile.LoadFromFile(lConfig.SchemaPath, TEncoding.UTF8);
      lSchemaStr := lOutFile.Text;
    finally
      lOutFile.Free;
    end;
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, Format('Error reading schema file: %s', [E.Message]));
      Exit;
    end;
  end;

  lSchemaObj := TJSONObject.ParseJSONValue(lSchemaStr);
  if not Assigned(lSchemaObj) or not (lSchemaObj is TJSONObject) then
  begin
    lSchemaObj.Free;
    Writeln(ErrOutput, 'Error: Schema is not a valid JSON Object.');
    Exit;
  end;

  // --- STEP 2: Resolve ClassName and UnitName ---
  lClassName := lConfig.ClassName;
  if lClassName.IsEmpty then
  begin
    lClassName := ChangeFileExt(ExtractFileName(lConfig.SchemaPath), '');
    // Sanitize basic class name characters
    lClassName := StringReplace(lClassName, '.', '', [rfReplaceAll]);
    lClassName := StringReplace(lClassName, '-', '', [rfReplaceAll]);
    lClassName := StringReplace(lClassName, '_', '', [rfReplaceAll]);
    if lClassName.IsEmpty then
      lClassName := 'Root';
  end;

  lUnitName := lConfig.UnitName;
  if lUnitName.IsEmpty then
  begin
    lUnitName := ChangeFileExt(ExtractFileName(lConfig.OutputPath), '');
    lUnitName := StringReplace(lUnitName, '.', '', [rfReplaceAll]);
    if lUnitName.IsEmpty then
      lUnitName := 'GeneratedDTO';
  end;

  // --- STEP 3: Generate Code ---
  try
    lGeneratedCode := GenerateClassFromSchema(TJSONObject(lSchemaObj), lClassName, lUnitName);
  except
    on E: Exception do
    begin
      lSchemaObj.Free;
      Writeln(ErrOutput, Format('Error during code generation: %s', [E.Message]));
      Exit;
    end;
  end;

  // --- STEP 4: Save Code ---
  try
    lOutFile := TStringList.Create;
    try
      lOutFile.Text := lGeneratedCode;
      lOutFile.SaveToFile(lConfig.OutputPath, TEncoding.UTF8);
    finally
      lOutFile.Free;
    end;
    Result := 0;
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, Format('Error saving output file: %s', [E.Message]));
    end;
  end;

  lSchemaObj.Free;
end;

end.
