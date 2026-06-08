unit SchemaBundler.Runner;

(*
--------------------------------------------------------------------------------
SchemaBundler CLI Runner orchestrator.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.JSON,
  SchemaBundler.Config, SchemaBundler.Engine;

/// <summary>Orchestrates bundling of split schemas via CLI.</summary>
function RunSchemaBundler: Integer;

implementation

procedure ShowHelpMessage;
begin
  Writeln(ErrOutput, 'SchemaBundler - JSON Schema Packaging Utility');
  Writeln(ErrOutput, 'Consolidates split multi-file JSON schemas into a single self-contained document.');
  Writeln(ErrOutput);
  Writeln(ErrOutput, 'Usage:');
  Writeln(ErrOutput, '  SchemaBundlerCLI.exe -i <input_path> -o <output_path> [options]');
  Writeln(ErrOutput, '  SchemaBundlerCLI.exe <input_path> -o <output_path> [options]');
  Writeln(ErrOutput);
  Writeln(ErrOutput, 'Options:');
  Writeln(ErrOutput, '  -i, --input, -s, --schema   Path to the root JSON Schema file (required)');
  Writeln(ErrOutput, '  -o, --output                Path to save the bundled schema (prints to stdout if omitted)');
  Writeln(ErrOutput, '  --legacy                    Consolidate definitions under "definitions" instead of "$defs"');
  Writeln(ErrOutput, '  --minify                    Minify output JSON schema instead of prettifying');
  Writeln(ErrOutput, '  --quiet                     Modo silencioso. Suprime saídas informativas.');
  Writeln(ErrOutput, '  -h, --help                  Display this help documentation');
  Writeln(ErrOutput);
end;

function RunSchemaBundler: Integer;
var
  lConfig: TSchemaBundlerConfig;
  lBundler: TSchemaBundler;
  lOptions: TSchemaBundlerOptions;
  lOutputText: string;
begin
  Result := 1; // Default to error
  lConfig := ParseCommandLine;

  if lConfig.ShowHelp or (lConfig.InputPath = '') then
  begin
    ShowHelpMessage;
    if not lConfig.ShowHelp then
    begin
      Writeln(ErrOutput, 'Error: Missing required option: -i/--input or -s/--schema');
      Exit;
    end;
    Result := 0;
    Exit;
  end;

  if not FileExists(lConfig.InputPath) then
  begin
    Writeln(ErrOutput, 'Error: Root schema file does not exist at: ' + lConfig.InputPath);
    Exit;
  end;

  try
    lBundler := TSchemaBundler.Create;
    try
      lOptions.UseLegacyDefinitions := lConfig.UseLegacy;
      lOptions.IndentOutput := not lConfig.Minify;
      lBundler.Options := lOptions;

      lOutputText := lBundler.Bundle(lConfig.InputPath);

      if lConfig.OutputPath <> '' then
      begin
        try
          TFile.WriteAllText(lConfig.OutputPath, lOutputText, TEncoding.UTF8);
          if not lConfig.Quiet then
            Writeln(ErrOutput, 'Schema bundled successfully at: ' + lConfig.OutputPath);
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
      lBundler.Free;
    end;
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, 'Error during bundling: ' + E.Message);
      Result := 1;
    end;
  end;
end;

end.
