unit Schema2DDL.Config;

(*
--------------------------------------------------------------------------------
Command-line Configuration and Parser for Schema2DDL CLI.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils, System.Classes;

type
  /// <summary>Options configuration for Schema2DDL generator CLI.</summary>
  TSchema2DDLConfig = record
    SchemaPath: string;
    Dialect: string;
    OutputPath: string;
    TableName: string;
    GenerateDrop: Boolean;
    AutoIncPk: Boolean;
    QuoteIdentifiers: Boolean;
    ShowHelp: Boolean;
  end;

/// <summary>Parses command line parameters into a configuration record.</summary>
function ParseCommandLine: TSchema2DDLConfig;

implementation

function ParseCommandLine: TSchema2DDLConfig;
var
  lI: Integer;
  lArg: string;
begin
  // Default values
  Result.SchemaPath := '';
  Result.Dialect := 'PostgreSQL';
  Result.OutputPath := '';
  Result.TableName := '';
  Result.GenerateDrop := False;
  Result.AutoIncPk := True;
  Result.QuoteIdentifiers := False;
  Result.ShowHelp := False;

  lI := 1;
  while lI <= ParamCount do
  begin
    lArg := ParamStr(lI);

    if SameText(lArg, '-h') or SameText(lArg, '--help') then
    begin
      Result.ShowHelp := True;
      Inc(lI);
    end
    else if (SameText(lArg, '-s') or SameText(lArg, '--schema')) and (lI < ParamCount) then
    begin
      Result.SchemaPath := ParamStr(lI + 1);
      Inc(lI, 2);
    end
    else if (SameText(lArg, '-d') or SameText(lArg, '--dialect')) and (lI < ParamCount) then
    begin
      Result.Dialect := ParamStr(lI + 1);
      Inc(lI, 2);
    end
    else if (SameText(lArg, '-o') or SameText(lArg, '--output')) and (lI < ParamCount) then
    begin
      Result.OutputPath := ParamStr(lI + 1);
      Inc(lI, 2);
    end
    else if (SameText(lArg, '-t') or SameText(lArg, '--table')) and (lI < ParamCount) then
    begin
      Result.TableName := ParamStr(lI + 1);
      Inc(lI, 2);
    end
    else if SameText(lArg, '--drop') then
    begin
      Result.GenerateDrop := True;
      Inc(lI);
    end
    else if SameText(lArg, '--no-auto-inc') then
    begin
      Result.AutoIncPk := False;
      Inc(lI);
    end
    else if SameText(lArg, '-q') or SameText(lArg, '--quote') then
    begin
      Result.QuoteIdentifiers := True;
      Inc(lI);
    end
    else
    begin
      // Ignore unknown parameters or treat first free as schema path
      if Result.SchemaPath = '' then
        Result.SchemaPath := lArg;
      Inc(lI);
    end;
  end;
end;

end.
