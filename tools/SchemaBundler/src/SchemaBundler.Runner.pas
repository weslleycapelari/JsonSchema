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
  Writeln('SchemaBundler - JSON Schema Packaging Utility');
  Writeln('Consolidates split multi-file JSON schemas into a single self-contained document.');
  Writeln;
  Writeln('Usage:');
  Writeln('  SchemaBundlerCLI.exe -i <input_path> [-o <output_path>] [--legacy] [--minify]');
  Writeln;
  Writeln('Options:');
  Writeln('  -i, --input     Path to the root JSON Schema file (required)');
  Writeln('  -o, --output    Path to save the bundled schema (prints to stdout if omitted)');
  Writeln('  --legacy        Consolidate definitions under "definitions" instead of "$defs"');
  Writeln('  --minify        Minify output JSON schema instead of prettifying');
  Writeln('  -h, --help      Display this help documentation');
  Writeln;
end;

function RunSchemaBundler: Integer;
var
  lConfig: TSchemaBundlerConfig;
  lBundler: TSchemaBundler;
  lOptions: TSchemaBundlerOptions;
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
