unit Schema2REST.Runner;

(*
--------------------------------------------------------------------------------
CLI Runner Workflow for Schema2REST.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.IOUtils, Schema2REST.Config, Schema2REST.Engine;

/// <summary>Prints CLI usage syntax manual to standard error.</summary>
procedure PrintUsage;

/// <summary>Executes the CLI generation workflow.</summary>
/// <returns>Exit code: 0 for success, 2 for error.</returns>
function RunSchema2REST: Integer;

implementation

procedure PrintUsage;
begin
  Writeln(ErrOutput, 'Schema2REST - JSON Schema REST Router/Controller Generator');
  Writeln(ErrOutput);
  Writeln(ErrOutput, 'Usage:');
  Writeln(ErrOutput, '  Schema2RESTCLI -s <schema_path> [-f <framework>] [-o <output_path>] [options]');
  Writeln(ErrOutput);
  Writeln(ErrOutput, 'Options:');
  Writeln(ErrOutput, '  -s, --schema    Path to the input JSON Schema file (Required).');
  Writeln(ErrOutput, '  -f, --framework Target REST framework: Horse, DMVC (default: Horse).');
  Writeln(ErrOutput, '  -o, --output    Path to save the generated Delphi unit .pas file (Stdout if omitted).');
  Writeln(ErrOutput, '  -e, --entity    Custom entity/unit name (defaults to schema title).');
  Writeln(ErrOutput, '  -h, --help      Display this help manual.');
  Writeln(ErrOutput);
end;

function RunSchema2REST: Integer;
var
  lConfig: TSchema2RESTConfig;
  lSchemaText: string;
  lSchemaJson: TJSONObject;
  lGenerator: TSchema2RESTGenerator;
  lFrameworkType: TRESTFramework;
  lPascalOutput: string;
begin
  Result := 2;
  lConfig := ParseCommandLine;

  if lConfig.ShowHelp or (lConfig.SchemaPath = '') then
  begin
    PrintUsage;
    Exit;
  end;

  if not FileExists(lConfig.SchemaPath) then
  begin
    Writeln(ErrOutput, 'Error: Schema file not found: ' + lConfig.SchemaPath);
    Exit;
  end;

  try
    lSchemaText := TFile.ReadAllText(lConfig.SchemaPath);
    lSchemaJson := TJSONObject.ParseJSONValue(lSchemaText) as TJSONObject;
    if not Assigned(lSchemaJson) then
    begin
      Writeln(ErrOutput, 'Error: Failed to parse input file as a valid JSON object.');
      Exit;
    end;

    try
      lGenerator := TSchema2RESTGenerator.Create;
      try
        lFrameworkType := rfHorse;
        if SameText(lConfig.Framework, 'DMVC') then
          lFrameworkType := rfDMVC;

        lGenerator.Framework := lFrameworkType;
        lPascalOutput := lGenerator.GenerateRESTCode(lSchemaJson, lConfig.EntityName);

        // Write output
        if lConfig.OutputPath <> '' then
        begin
          TFile.WriteAllText(lConfig.OutputPath, lPascalOutput, TEncoding.UTF8);
          Writeln(ErrOutput, 'Delphi REST unit written successfully to: ' + lConfig.OutputPath);
        end
        else
        begin
          Writeln(lPascalOutput);
        end;

        Result := 0; // Success
      finally
        lGenerator.Free;
      end;
    finally
      lSchemaJson.Free;
    end;
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, 'Execution failed: ' + E.Message);
      Result := 2;
    end;
  end;
end;

end.
