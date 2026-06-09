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
  Writeln(ErrOutput, 'JSON2Schema CLI Converter');
  Writeln(ErrOutput, 'Generates JSON Schema from arbitrary JSON instances.');
  Writeln(ErrOutput);
  Writeln(ErrOutput, 'Usage:');
  Writeln(ErrOutput, '  JSON2SchemaCLI.exe -i <input_path> [-o <output_path>] [options]');
  Writeln(ErrOutput);
  Writeln(ErrOutput, 'Options:');
  Writeln(ErrOutput, '  -i, --input      Path to the input JSON file (required)');
  Writeln(ErrOutput, '  -o, --output     Path to save the generated schema.json (prints to stdout if omitted)');
  Writeln(ErrOutput, '  -d, --draft      Schema draft identifier URL (default: Draft 7)');
  Writeln(ErrOutput, '  --required       Include all object properties in the required array');
  Writeln(ErrOutput, '  --no-format      Disable string format inference (date, email, uuid)');
  Writeln(ErrOutput, '  --minify         Minify output JSON schema instead of prettifying');
  Writeln(ErrOutput, '  -q, --quiet      Suppress informational output');
  Writeln(ErrOutput, '  -h, --help       Display this help documentation');
  Writeln(ErrOutput);
end;

function RunJSON2Schema: Integer;
var
  lConfig: TJSON2SchemaConfig;
  lInputJson: string;
  lJSONValue: TJSONValue;
  lGenerator: TJSON2SchemaGenerator;
  lSchemaObj: TJSONObject;
  lOptions: TJSON2SchemaOptions;
  lOutputText: string;
begin
  Result := 1; // Default to error
  lConfig := ParseCommandLine;

  if lConfig.ShowHelp or (lConfig.InputPath = '') then
  begin
    ShowHelpMessage;
    Exit(0);
  end;

  if not FileExists(lConfig.InputPath) then
  begin
    Writeln(ErrOutput, 'Error: Input file does not exist at: ' + lConfig.InputPath);
    Exit;
  end;

  try
    // Read text using ReadAllText which handles UTF-8 BOM detection automatically
    lInputJson := TFile.ReadAllText(lConfig.InputPath, TEncoding.UTF8);
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, 'Error reading input file: ' + E.Message);
      Exit;
    end;
  end;

  lJSONValue := TJSONObject.ParseJSONValue(lInputJson);
  if not Assigned(lJSONValue) then
  begin
    Writeln(ErrOutput, 'Error: Failed to parse input file as valid JSON.');
    Exit;
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
        Exit;
      end;

      try
        if lConfig.Minify then
          lOutputText := lSchemaObj.ToJSON
        else
          lOutputText := lSchemaObj.Format(2);

        if lConfig.OutputPath <> '' then
        begin
          try
            TFile.WriteAllText(lConfig.OutputPath, lOutputText, TEncoding.UTF8);
            if not lConfig.Quiet then
              Writeln(ErrOutput, 'JSON Schema generated successfully.');
          except
            on E: Exception do
            begin
              Writeln(ErrOutput, 'Error writing schema to file: ' + E.Message);
              Exit;
            end;
          end;
        end
        else
        begin
          Writeln(lOutputText);
        end;
        Result := 0; // Success
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
