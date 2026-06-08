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
    Quiet: Boolean;
    ShowHelp: Boolean;
  end;

/// <summary>Parses command line parameters into a configuration record.</summary>
function ParseCommandLine: TSchema2DDLConfig;

/// <summary>Parses custom array of parameters into a configuration record.</summary>
function ParseCommandLineEx(const pArgs: TArray<string>): TSchema2DDLConfig;

implementation

function ParseCommandLineEx(const pArgs: TArray<string>): TSchema2DDLConfig;
var
  lI: Integer;
  lArg: string;
  lPositionalCount: Integer;
begin
  // Default values
  Result.SchemaPath := '';
  Result.Dialect := 'PostgreSQL';
  Result.OutputPath := '';
  Result.TableName := '';
  Result.GenerateDrop := False;
  Result.AutoIncPk := True;
  Result.QuoteIdentifiers := False;
  Result.Quiet := False;
  Result.ShowHelp := False;

  lI := 0;
  lPositionalCount := 0;
  while lI < Length(pArgs) do
  begin
    lArg := pArgs[lI];

    if SameText(lArg, '-h') or SameText(lArg, '--help') then
    begin
      Result.ShowHelp := True;
      Exit;
    end
    else if SameText(lArg, '-i') or SameText(lArg, '--input') or SameText(lArg, '-s') or SameText(lArg, '--schema') then
    begin
      Inc(lI);
      if lI < Length(pArgs) then
        Result.SchemaPath := pArgs[lI];
    end
    else if SameText(lArg, '-d') or SameText(lArg, '--dialect') then
    begin
      Inc(lI);
      if lI < Length(pArgs) then
        Result.Dialect := pArgs[lI];
    end
    else if SameText(lArg, '-o') or SameText(lArg, '--output') then
    begin
      Inc(lI);
      if lI < Length(pArgs) then
        Result.OutputPath := pArgs[lI];
    end
    else if SameText(lArg, '-t') or SameText(lArg, '--table') then
    begin
      Inc(lI);
      if lI < Length(pArgs) then
        Result.TableName := pArgs[lI];
    end
    else if SameText(lArg, '--drop') then
    begin
      Result.GenerateDrop := True;
    end
    else if SameText(lArg, '--no-auto-inc') then
    begin
      Result.AutoIncPk := False;
    end
    else if SameText(lArg, '-q') or SameText(lArg, '--quote') then
    begin
      Result.QuoteIdentifiers := True;
    end
    else if SameText(lArg, '--quiet') then
    begin
      Result.Quiet := True;
    end
    else if not lArg.StartsWith('-') then
    begin
      if lPositionalCount = 0 then
        Result.SchemaPath := lArg;
      Inc(lPositionalCount);
    end;

    Inc(lI);
  end;
end;

function ParseCommandLine: TSchema2DDLConfig;
var
  lArgs: TArray<string>;
  lI: Integer;
begin
  SetLength(lArgs, ParamCount);
  for lI := 1 to ParamCount do
    lArgs[lI - 1] := ParamStr(lI);
  Result := ParseCommandLineEx(lArgs);
end;

end.
