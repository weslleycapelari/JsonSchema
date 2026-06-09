unit SchemaMockGen.Runner;

(*
--------------------------------------------------------------------------------
Orchestrates CLI execution for SchemaMockGen, handling file reading, generation, and output.
--------------------------------------------------------------------------------
*)

interface

uses
  System.Classes,
  System.JSON,
  System.SysUtils,
  SchemaMockGen.Config,
  SchemaMockGen.Generator,
  SchemaMockGen.Utils;

/// <summary>Displays the CLI usage manual on stderr.</summary>
procedure PrintUsage;

/// <summary>Runs the schema mock generator CLI workflow.</summary>
/// <returns>Exit code: 0 for success, 2 for errors.</returns>
function RunSchemaMockGen: Integer;

implementation

procedure PrintUsage;
begin
  Writeln(ErrOutput, 'SchemaMockGen - JSON Schema Mock Instance Generator');
  Writeln(ErrOutput);
  Writeln(ErrOutput, 'Usage:');
  Writeln(ErrOutput, '  SchemaMockGen -i <schema_path> [options]');
  Writeln(ErrOutput);
  Writeln(ErrOutput, 'Options:');
  Writeln(ErrOutput, '  -i, --input, -s, --schema   Path to the JSON Schema file (Required).');
  Writeln(ErrOutput, '  -o, --output                Path to save the generated mock JSON file (Optional. Prints to stdout if omitted).');
  Writeln(ErrOutput, '  -e, --seed                  Deterministic generation seed (Optional. Seed >= 0).');
  Writeln(ErrOutput, '  -n, --count                 Number of mock instances to generate (Optional. Default: 1).');
  Writeln(ErrOutput, '  --minify                    Minify generated mock JSON.');
  Writeln(ErrOutput, '  -q, --quiet                 Suppress informational output.');
  Writeln(ErrOutput, '  -h, --help                  Display this help manual.');
  Writeln(ErrOutput);
end;

function RunSchemaMockGen: Integer;
var
  lConfig: TConfig;
  lSchemaStr: string;
  lSchemaVal: TJSONValue;
  lGenerator: TSchemaMockGenerator;
  lSeed: Int64;
  lResultVal: TJSONValue;
  lResultArray: TJSONArray;
  lI: Integer;
  lOutputStr: string;
begin
  Result := 1; // Default to error exit code
  lConfig := ParseArguments;

  if lConfig.ShowHelp or lConfig.SchemaPath.IsEmpty then
  begin
    PrintUsage;
    if lConfig.SchemaPath.IsEmpty and not lConfig.ShowHelp then
      Writeln(ErrOutput, 'Error: Missing required option: -i/--input or -s/--schema');
    Exit(0);
  end;

  // --- STEP 1: Load Schema ---
  if not FileExists(lConfig.SchemaPath) then
  begin
    Writeln(ErrOutput, Format('Error: Schema file not found: %s', [lConfig.SchemaPath]));
    Exit;
  end;

  try
    lSchemaStr := ReadFileContent(lConfig.SchemaPath);
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, Format('Error reading schema file: %s', [E.Message]));
      Exit;
    end;
  end;

  lSchemaVal := TJSONObject.ParseJSONValue(lSchemaStr);
  if not Assigned(lSchemaVal) then
  begin
    Writeln(ErrOutput, 'Error: Schema is not valid JSON.');
    Exit;
  end;

  // --- STEP 2: Configure Seeded Generator ---
  if lConfig.Seed < 0 then
  begin
    // Generate a random seed if none was specified (or was negative)
    Randomize;
    lSeed := Random(2147483647);
    if not lConfig.Quiet then
      Writeln(ErrOutput, Format('Note: Seed omitted. Generated random seed: %d', [lSeed]));
  end else
    lSeed := lConfig.Seed;

  lGenerator := TSchemaMockGenerator.Create(lSeed);
  try
    // --- STEP 3: Generate Mock Instance(s) ---
    try
      if lConfig.Count = 1 then
      begin
        lResultVal := lGenerator.Generate(lSchemaVal);
        if lConfig.Minify then
          lOutputStr := lResultVal.ToJSON
        else
          lOutputStr := lResultVal.Format(2);
        lResultVal.Free;
      end else
      begin
        lResultArray := TJSONArray.Create;
        try
          for lI := 1 to lConfig.Count do
            lResultArray.AddElement(lGenerator.Generate(lSchemaVal));
          
          if lConfig.Minify then
            lOutputStr := lResultArray.ToJSON
          else
            lOutputStr := lResultArray.Format(2);
        finally
          lResultArray.Free;
        end;
      end;
    except
      on E: Exception do
      begin
        Writeln(ErrOutput, Format('Generation runtime error: %s', [E.Message]));
        Exit;
      end;
    end;

    // --- STEP 4: Output Result ---
    if not lConfig.OutputPath.IsEmpty then
    begin
      try
        WriteFileContent(lConfig.OutputPath, lOutputStr);
        if not lConfig.Quiet then
          Writeln(ErrOutput, 'Mock data generated successfully.');
      except
        on E: Exception do
        begin
          Writeln(ErrOutput, Format('Error writing output file: %s', [E.Message]));
          Exit;
        end;
      end;
    end else
    begin
      Writeln(lOutputStr);
    end;

    Result := 0;
  finally
    lGenerator.Free;
    lSchemaVal.Free;
  end;
end;

end.
