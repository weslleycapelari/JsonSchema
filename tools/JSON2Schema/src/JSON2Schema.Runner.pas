unit JSON2Schema.Runner;

(*
--------------------------------------------------------------------------------
JSON2Schema CLI Runner orchestrator.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.JSON,
  JSON2Schema.Config, JSON2Schema.Engine;

/// <summary>Orchestrates the conversion from JSON to JSON Schema via CLI.</summary>
function RunJSON2Schema: Integer;

implementation

procedure ShowHelpMessage;
begin
  Writeln('JSON2Schema CLI Converter');
  Writeln('Generates JSON Schema from arbitrary JSON instances.');
  Writeln;
  Writeln('Usage:');
  Writeln('  JSON2SchemaCLI.exe -i <input_path> [-o <output_path>] [-d <draft>] [--required] [--no-format]');
  Writeln;
  Writeln('Options:');
  Writeln('  -i, --input      Path to the input JSON file (required)');
  Writeln('  -o, --output     Path to save the generated schema.json (prints to stdout if omitted)');
  Writeln('  -d, --draft      Schema draft identifier URL (default: Draft 7)');
  Writeln('  --required       Include all object properties in the required array');
  Writeln('  --no-format      Disable string format inference (date, email, uuid)');
  Writeln('  -h, --help       Display this help documentation');
  Writeln;
end;

function RunJSON2Schema: Integer;
var
  lConfig: TJSON2SchemaConfig;
  lInputJson: string;
  lJSONValue: TJSONValue;
  lGenerator: TJSON2SchemaGenerator;
  lSchemaObj: TJSONObject;
  lOptions: TJSON2SchemaOptions;
  lPrettySchema: string;
begin
  Result := 0;
  lConfig := ParseCommandLine;

  if lConfig.ShowHelp or (lConfig.InputPath = '') then
  begin
    ShowHelpMessage;
    Exit(0);
  end;

  if not FileExists(lConfig.InputPath) then
  begin
    Writeln(ErrOutput, 'Error: Input file does not exist at: ' + lConfig.InputPath);
    Exit(1);
  end;

  try
    // Read text using ReadAllText which handles UTF-8 BOM detection automatically
    lInputJson := TFile.ReadAllText(lConfig.InputPath, TEncoding.UTF8);
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, 'Error reading input file: ' + E.Message);
      Exit(1);
    end;
  end;

  lJSONValue := TJSONObject.ParseJSONValue(lInputJson);
  if not Assigned(lJSONValue) then
  begin
    Writeln(ErrOutput, 'Error: Failed to parse input file as valid JSON.');
    Exit(1);
  end;

  try
    lGenerator := TJSON2SchemaGenerator.Create;
    try
      lOptions.Draft := lConfig.Draft;
      lOptions.InferFormats := lConfig.InferFormats;
      lOptions.MakeRequired := lConfig.MakeRequired;

      lGenerator.Options := lOptions;
      lSchemaObj := lGenerator.GenerateSchema(lJSONValue);

      if not Assigned(lSchemaObj) then
      begin
        Writeln(ErrOutput, 'Error: Inference produced no output.');
        Exit(1);
      end;

      try
        lPrettySchema := lSchemaObj.Format(2);

        if lConfig.OutputPath <> '' then
        begin
          try
            TFile.WriteAllText(lConfig.OutputPath, lPrettySchema, TEncoding.UTF8);
          except
            on E: Exception do
            begin
              Writeln(ErrOutput, 'Error writing schema to file: ' + E.Message);
              Exit(1);
            end;
          end;
        end
        else
        begin
          Writeln(lPrettySchema);
        end;
      finally
        lSchemaObj.Free;
      end;
    finally
      lGenerator.Free;
    end;
  finally
    lJSONValue.Free;
  end;
end;

end.
