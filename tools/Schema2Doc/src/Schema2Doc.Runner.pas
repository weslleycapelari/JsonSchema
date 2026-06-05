unit Schema2Doc.Runner;

(*
--------------------------------------------------------------------------------
Schema2Doc CLI Runner orchestrator.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.JSON,
  Schema2Doc.Config, Schema2Doc.Engine;

/// <summary>Orchestrates the conversion from JSON Schema to Markdown/HTML via CLI.</summary>
function RunSchema2Doc: Integer;

implementation

procedure ShowHelpMessage;
begin
  Writeln('Schema2Doc - JSON Schema Documentation Generator');
  Writeln('Generates clean, human-readable Markdown or HTML tables from JSON Schema.');
  Writeln;
  Writeln('Usage:');
  Writeln('  Schema2DocCLI.exe -s <schema_path> [-o <output_path>] [-f <format>] [-t <title>]');
  Writeln;
  Writeln('Options:');
  Writeln('  -s, --schema     Path to the input JSON Schema file (required)');
  Writeln('  -o, --output     Path to save the generated documentation (prints to stdout if omitted)');
  Writeln('  -f, --format     Output format: markdown (default) or html');
  Writeln('  -t, --title      Override default document title');
  Writeln('  -h, --help       Display this help documentation');
  Writeln;
end;

function RunSchema2Doc: Integer;
var
  lConfig: TSchema2DocConfig;
  lSchemaJson: string;
  lJSONVal: TJSONValue;
  lSchemaObj: TJSONObject;
  lGenerator: TSchema2DocGenerator;
  lOptions: TSchema2DocOptions;
  lDocOutput: string;
begin
  Result := 0;
  lConfig := ParseCommandLine;

  if lConfig.ShowHelp or (lConfig.SchemaPath = '') then
  begin
    ShowHelpMessage;
    Exit(0);
  end;

  if not FileExists(lConfig.SchemaPath) then
  begin
    Writeln(ErrOutput, 'Error: Schema file does not exist at: ' + lConfig.SchemaPath);
    Exit(1);
  end;

  try
    lSchemaJson := TFile.ReadAllText(lConfig.SchemaPath, TEncoding.UTF8);
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
    lGenerator := TSchema2DocGenerator.Create;
    try
      lOptions.TitleOverride := lConfig.TitleOverride;
      lOptions.Format := dfMarkdown;
      if SameText(lConfig.Format, 'html') or SameText(lConfig.Format, 'htm') then
        lOptions.Format := dfHTML;

      lGenerator.Options := lOptions;
      lDocOutput := lGenerator.GenerateDoc(lSchemaObj);

      if lConfig.OutputPath <> '' then
      begin
        try
          TFile.WriteAllText(lConfig.OutputPath, lDocOutput, TEncoding.UTF8);
        except
          on E: Exception do
          begin
            Writeln(ErrOutput, 'Error writing documentation output: ' + E.Message);
            Exit(1);
          end;
        end;
      end
      else
      begin
        Writeln(lDocOutput);
      end;
    finally
      lGenerator.Free;
    end;
  finally
    lSchemaObj.Free;
  end;
end;

end.
