unit SchemaOptimizer.Config;

(*
--------------------------------------------------------------------------------
Command-line Configuration and Parser for SchemaOptimizer CLI.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils, System.Classes;

type
  /// <summary>Options configuration for SchemaOptimizer CLI.</summary>
  TSchemaOptimizerConfig = record
    InputPath: string;
    OutputPath: string;
    RemoveUnused: Boolean;
    MergeAllOf: Boolean;
    PruneEmpty: Boolean;
    Minify: Boolean;
    Quiet: Boolean;
    ShowHelp: Boolean;
  end;

/// <summary>Parses command line arguments into a config record.</summary>
function ParseCommandLine: TSchemaOptimizerConfig;

implementation

function ParseCommandLine: TSchemaOptimizerConfig;
var
  lI: Integer;
  lArg: string;
begin
  // Set default values (enabled by default)
  Result.InputPath := '';
  Result.OutputPath := '';
  Result.RemoveUnused := True;
  Result.MergeAllOf := True;
  Result.PruneEmpty := True;
  Result.Minify := False;
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
    else if (SameText(lArg, '-i') or SameText(lArg, '--input') or SameText(lArg, '-s') or SameText(lArg, '--schema')) and (lI < ParamCount) then
    begin
      Result.InputPath := ParamStr(lI + 1);
      Inc(lI, 2);
    end
    else if (SameText(lArg, '-o') or SameText(lArg, '--output')) and (lI < ParamCount) then
    begin
      Result.OutputPath := ParamStr(lI + 1);
      Inc(lI, 2);
    end
    else if SameText(lArg, '--no-unused') then
    begin
      Result.RemoveUnused := False;
      Inc(lI);
    end
    else if SameText(lArg, '--no-allof') then
    begin
      Result.MergeAllOf := False;
      Inc(lI);
    end
    else if SameText(lArg, '--no-prune') then
    begin
      Result.PruneEmpty := False;
      Inc(lI);
    end
    else if SameText(lArg, '--minify') then
    begin
      Result.Minify := True;
      Inc(lI);
    end
    else if SameText(lArg, '-q') or SameText(lArg, '--quiet') then
    begin
      Result.Quiet := True;
      Inc(lI);
    end
    else
    begin
      if Result.InputPath = '' then
        Result.InputPath := lArg;
      Inc(lI);
    end;
  end;
end;

end.
