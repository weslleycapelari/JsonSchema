unit SchemaMigrator.Runner;

(*
--------------------------------------------------------------------------------
SchemaMigrator CLI Runner orchestrator.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.JSON,
  SchemaMigrator.Config, SchemaMigrator.Engine;

/// <summary>Orchestrates schema draft migration via CLI.</summary>
function RunSchemaMigrator: Integer;

implementation

procedure ShowHelpMessage;
begin
  Writeln(ErrOutput, 'SchemaMigrator - JSON Schema Draft Migration Utility');
  Writeln(ErrOutput, 'Converts older schemas (Draft 4/6/7) to modern Draft 2020-12 dialect.');
  Writeln(ErrOutput);
  Writeln(ErrOutput, 'Usage:');
  Writeln(ErrOutput, '  SchemaMigratorCLI.exe -i <input_path> [-o <output_path>] [options]');
  Writeln(ErrOutput);
  Writeln(ErrOutput, 'Options:');
  Writeln(ErrOutput, '  -i, --input     Path to the root legacy JSON Schema file (required)');
  Writeln(ErrOutput, '  -o, --output    Path to save the migrated schema (prints to stdout if omitted)');
  Writeln(ErrOutput, '  --minify        Minify output JSON schema instead of prettifying');
  Writeln(ErrOutput, '  -q, --quiet     Suppress informational output');
  Writeln(ErrOutput, '  -h, --help      Display this help documentation');
  Writeln(ErrOutput);
end;

function RunSchemaMigrator: Integer;
var
  lConfig: TSchemaMigratorConfig;
  lMigrator: TSchemaMigrator;
  lSchemaJson: string;
  lJSONVal: TJSONValue;
  lSchemaObj: TJSONObject;
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
    Writeln(ErrOutput, 'Error: Root schema file does not exist at: ' + lConfig.InputPath);
    Exit;
  end;

  try
    lSchemaJson := TFile.ReadAllText(lConfig.InputPath, TEncoding.UTF8);
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, 'Error reading schema file: ' + E.Message);
      Exit;
    end;
  end;

  lJSONVal := TJSONObject.ParseJSONValue(lSchemaJson);
  if not Assigned(lJSONVal) or not (lJSONVal is TJSONObject) then
  begin
    if Assigned(lJSONVal) then
      lJSONVal.Free;
    Writeln(ErrOutput, 'Error: Input file is not a valid JSON Object.');
    Exit;
  end;

  lSchemaObj := TJSONObject(lJSONVal);
  try
    lMigrator := TSchemaMigrator.Create;
    try
      lOutputText := lMigrator.Migrate(lSchemaObj);

      // If minify was requested, format it to flat json string
      if lConfig.Minify then
      begin
        // Format to minified JSON
        var lTempObj := TJSONObject.ParseJSONValue(lOutputText) as TJSONObject;
        try
          lOutputText := lTempObj.ToJSON;
        finally
          lTempObj.Free;
        end;
      end;

      if lConfig.OutputPath <> '' then
      begin
        try
          TFile.WriteAllText(lConfig.OutputPath, lOutputText, TEncoding.UTF8);
          if not lConfig.Quiet then
            Writeln(ErrOutput, 'Schema migrated successfully to Draft 2020-12.');
        except
          on E: Exception do
          begin
            Writeln(ErrOutput, 'Error writing output file: ' + E.Message);
            Exit;
          end;
        end;
      end else
      begin
        Writeln(lOutputText);
      end;

      Result := 0;
    finally
      lMigrator.Free;
    end;
  finally
    lSchemaObj.Free;
  end;
end;

end.
