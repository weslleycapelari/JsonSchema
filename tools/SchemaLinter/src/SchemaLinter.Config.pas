unit SchemaLinter.Config;

(*
--------------------------------------------------------------------------------
Command-line Configuration and Parser for SchemaLinter CLI.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils, System.Classes, SchemaLinter.Engine;

type
  /// <summary>Options configuration for SchemaLinter CLI.</summary>
  TSchemaLinterConfig = record
    SchemaPath: string;
    OutputPath: string;
    MinSeverity: TSeverity;
    Quiet: Boolean;
    ShowHelp: Boolean;
  end;

/// <summary>Parses command line arguments into a config record.</summary>
function ParseCommandLine: TSchemaLinterConfig;

implementation

function ParseCommandLine: TSchemaLinterConfig;
var
  lI: Integer;
  lArg: string;
  lSevStr: string;
begin
  // Set default values
  Result.SchemaPath := '';
  Result.OutputPath := '';
  Result.MinSeverity := TSeverity.Info;
  Result.Quiet := False;
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
    else if (SameText(lArg, '-s') or SameText(lArg, '--schema') or SameText(lArg, '-i') or SameText(lArg, '--input')) and (lI < ParamCount) then
    begin
      Result.SchemaPath := ParamStr(lI + 1);
      Inc(lI, 2);
    end
    else if (SameText(lArg, '-o') or SameText(lArg, '--output')) and (lI < ParamCount) then
    begin
      Result.OutputPath := ParamStr(lI + 1);
      Inc(lI, 2);
    end
    else if (SameText(lArg, '-m') or SameText(lArg, '--min-severity')) and (lI < ParamCount) then
    begin
      lSevStr := ParamStr(lI + 1);
      if SameText(lSevStr, 'error') then
        Result.MinSeverity := TSeverity.Error
      else if SameText(lSevStr, 'warning') then
        Result.MinSeverity := TSeverity.Warning
      else
        Result.MinSeverity := TSeverity.Info;
      Inc(lI, 2);
    end
    else if SameText(lArg, '-q') or SameText(lArg, '--quiet') then
    begin
      Result.Quiet := True;
      Inc(lI);
    end
    else
    begin
      if Result.SchemaPath = '' then
        Result.SchemaPath := lArg;
      Inc(lI);
    end;
  end;
end;

end.
