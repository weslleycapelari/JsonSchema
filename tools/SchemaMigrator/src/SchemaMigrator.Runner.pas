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
  Writeln('SchemaMigrator - JSON Schema Draft Migration Utility');
  Writeln('Converts older schemas (Draft 4/6/7) to modern Draft 2020-12 dialect.');
  Writeln;
  Writeln('Usage:');
  Writeln('  SchemaMigratorCLI.exe -i <input_path> [-o <output_path>] [--minify]');
  Writeln;
  Writeln('Options:');
  Writeln('  -i, --input     Path to the root legacy JSON Schema file (required)');
  Writeln('  -o, --output    Path to save the migrated schema (prints to stdout if omitted)');
  Writeln('  --minify        Minify output JSON schema instead of prettifying');
  Writeln('  -h, --help      Display this help documentation');
  Writeln;
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
  lConfig := ParseCommandLine;

  if lConfig.ShowHelp or (lConfig.InputPath = '') then
  begin
    ShowHelpMessage;
    Exit(0);
  end;

  if not FileExists(lConfig.InputPath) then
  begin
    Writeln(ErrOutput, 'Error: Root schema file does not exist at: ' + lConfig.InputPath);
    Exit(1);
  end;

  try
    lSchemaJson := TFile.ReadAllText(lConfig.InputPath, TEncoding.UTF8);
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, 'Error reading schema file: ' + E.Message);
      Exit(1);
    end;
  end;

  lJSONVal := TJSONObject.ParseJSONValue(lSchemaJson);
  if not Assigned(lJSONVal) or not (lJSONVal is TJSONObject) then
  begin
    if Assigned(lJSONVal) then
      lJSONVal.Free;
    Writeln(ErrOutput, 'Error: Input file is not a valid JSON Object.');
    Exit(1);
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
        except
          on E: Exception do
          begin
            Writeln(ErrOutput, 'Error writing output file: ' + E.Message);
            Exit(1);
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
