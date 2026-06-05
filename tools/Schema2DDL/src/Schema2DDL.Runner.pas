unit Schema2DDL.Runner;

(*
--------------------------------------------------------------------------------
CLI Runner Workflow for Schema2DDL.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils, System.Classes, System.JSON, Schema2DDL.Config, Schema2DDL.Engine, Schema2DDL.Dialects;

/// <summary>Prints CLI usage syntax manual to standard error.</summary>
procedure PrintUsage;

/// <summary>Executes the CLI generation workflow.</summary>
/// <returns>Exit code: 0 for success, 2 for error.</returns>
function RunSchema2DDL: Integer;

implementation

uses
  System.IOUtils;

procedure PrintUsage;
begin
  Writeln(ErrOutput, 'Schema2DDL - JSON Schema Relational DDL Exporter');
  Writeln(ErrOutput);
  Writeln(ErrOutput, 'Usage:');
  Writeln(ErrOutput, '  Schema2DDLCLI -s <schema_path> [-d <dialect>] [-o <output_path>] [options]');
  Writeln(ErrOutput);
  Writeln(ErrOutput, 'Options:');
  Writeln(ErrOutput, '  -s, --schema    Path to the input JSON Schema file (Required).');
  Writeln(ErrOutput, '  -d, --dialect   Target SQL database: PostgreSQL, Firebird, SQLite, SQLServer (default: PostgreSQL).');
  Writeln(ErrOutput, '  -o, --output    Path to save the generated SQL DDL script (Stdout if omitted).');
  Writeln(ErrOutput, '  -t, --table     Custom main table name (defaults to schema title).');
  Writeln(ErrOutput, '  --drop          Prepend DROP TABLE IF EXISTS statement.');
  Writeln(ErrOutput, '  --no-auto-inc   Disable auto-increment columns on primary keys.');
  Writeln(ErrOutput, '  -q, --quote     Enclose identifiers in double quotes (or dialect brackets).');
  Writeln(ErrOutput, '  -h, --help      Display this help manual.');
  Writeln(ErrOutput);
end;

function RunSchema2DDL: Integer;
var
  lConfig: TSchema2DDLConfig;
  lSchemaText: string;
  lSchemaJson: TJSONObject;
  lGenerator: TSchema2DDLGenerator;
  lDialectObj: ISQLDialect;
  lDdlOutput: string;
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
    // Read and parse schema file
    lSchemaText := TFile.ReadAllText(lConfig.SchemaPath, TEncoding.UTF8);
    lSchemaJson := TJSONObject.ParseJSONValue(lSchemaText) as TJSONObject;
    if not Assigned(lSchemaJson) then
    begin
      Writeln(ErrOutput, 'Error: Failed to parse input file as a valid JSON object.');
      Exit;
    end;

    try
      lDialectObj := TDialectFactory.CreateDialect(lConfig.Dialect);
      lGenerator := TSchema2DDLGenerator.Create;
      try
        lGenerator.Dialect := lDialectObj;
        lGenerator.GenerateDropTable := lConfig.GenerateDrop;
        lGenerator.AutoIncPk := lConfig.AutoIncPk;
        lGenerator.QuoteIdentifiers := lConfig.QuoteIdentifiers;

        lDdlOutput := lGenerator.GenerateDDL(lSchemaJson, lConfig.TableName);

        // Write output
        if lConfig.OutputPath <> '' then
        begin
          TFile.WriteAllText(lConfig.OutputPath, lDdlOutput, TEncoding.UTF8);
          Writeln(ErrOutput, 'DDL script written successfully to: ' + lConfig.OutputPath);
        end
        else
        begin
          Writeln(lDdlOutput);
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
