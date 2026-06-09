unit SchemaOptimizer.Runner;

(*
--------------------------------------------------------------------------------
SchemaOptimizer CLI Runner orchestrator.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.JSON,
  SchemaOptimizer.Config, SchemaOptimizer.Engine;

/// <summary>Orchestrates schema optimization via CLI.</summary>
function RunSchemaOptimizer: Integer;

implementation

procedure ShowHelpMessage;
begin
  Writeln(ErrOutput, 'SchemaOptimizer - JSON Schema Simplification Utility');
  Writeln(ErrOutput, 'Optimizes schemas by flattening allOf blocks and removing unused definitions.');
  Writeln(ErrOutput);
  Writeln(ErrOutput, 'Usage:');
  Writeln(ErrOutput, '  SchemaOptimizerCLI.exe -i <input_path> [-o <output_path>] [options]');
  Writeln(ErrOutput);
  Writeln(ErrOutput, 'Options:');
  Writeln(ErrOutput, '  -i, --input, -s, --schema  Path to the root JSON Schema file (required)');
  Writeln(ErrOutput, '  -o, --output               Path to save the optimized schema (prints to stdout if omitted)');
  Writeln(ErrOutput, '  --no-unused                Do not remove unused $defs / definitions');
  Writeln(ErrOutput, '  --no-allof                 Do not merge or flatten nested allOf blocks');
  Writeln(ErrOutput, '  --no-prune                 Do not prune empty subschemas or duplicate values');
  Writeln(ErrOutput, '  --minify                   Minify output JSON schema instead of prettifying');
  Writeln(ErrOutput, '  -q, --quiet                Suppress informational output');
  Writeln(ErrOutput, '  -h, --help                 Display this help documentation');
  Writeln(ErrOutput);
end;

function RunSchemaOptimizer: Integer;
var
  lConfig: TSchemaOptimizerConfig;
  lOptions: TOptimizerOptions;
  lOptimizer: TSchemaOptimizer;
  lSchemaJson: string;
  lJSONVal: TJSONValue;
  lSchemaObj: TJSONObject;
  lOutputText: string;
  lBytesSaved: Int64;
  lDefsRemoved: Integer;
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
    lOptions.RemoveUnused := lConfig.RemoveUnused;
    lOptions.MergeAllOf := lConfig.MergeAllOf;
    lOptions.PruneEmpty := lConfig.PruneEmpty;
    lOptions.Minify := lConfig.Minify;

    lOptimizer := TSchemaOptimizer.Create(lOptions);
    try
      lOutputText := lOptimizer.Optimize(lSchemaObj, lBytesSaved, lDefsRemoved);

      if lConfig.OutputPath <> '' then
      begin
        try
          TFile.WriteAllText(lConfig.OutputPath, lOutputText, TEncoding.UTF8);
          if not lConfig.Quiet then
            Writeln(ErrOutput, Format('Optimization complete: saved %d bytes, removed %d unused definitions.', [lBytesSaved, lDefsRemoved]));
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
      lOptimizer.Free;
    end;
  finally
    lSchemaObj.Free;
  end;
end;

end.
