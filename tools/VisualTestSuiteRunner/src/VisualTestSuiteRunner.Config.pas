unit VisualTestSuiteRunner.Config;

(*
--------------------------------------------------------------------------------
Command-line Configuration and Parser for VisualTestSuiteRunner CLI.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils, System.Classes;

type
  /// <summary>Options configuration for VisualTestSuiteRunner CLI.</summary>
  TTestSuiteRunnerConfig = record
    InputPath: string;
    DraftVersion: string;
    OutputPath: string;
    Quiet: Boolean;
    ShowHelp: Boolean;
  end;

/// <summary>Parses command line arguments into a config record.</summary>
function ParseCommandLine: TTestSuiteRunnerConfig;

implementation

function ParseCommandLine: TTestSuiteRunnerConfig;
var
  lI: Integer;
  lArg: string;
begin
  // Set default values
  Result.InputPath := '';
  Result.DraftVersion := '2020-12';
  Result.OutputPath := '';
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
    else if (SameText(lArg, '-i') or SameText(lArg, '--input')) and (lI < ParamCount) then
    begin
      Result.InputPath := ParamStr(lI + 1);
      Inc(lI, 2);
    end
    else if (SameText(lArg, '-d') or SameText(lArg, '--draft')) and (lI < ParamCount) then
    begin
      Result.DraftVersion := ParamStr(lI + 1);
      Inc(lI, 2);
    end
    else if (SameText(lArg, '-o') or SameText(lArg, '--output')) and (lI < ParamCount) then
    begin
      Result.OutputPath := ParamStr(lI + 1);
      Inc(lI, 2);
    end
    else if SameText(lArg, '--quiet') then
    begin
      Result.Quiet := True;
      Inc(lI);
    end
    else
    begin
      // Fallback: first standalone argument is the input directory path
      if Result.InputPath = '' then
        Result.InputPath := lArg;
      Inc(lI);
    end;
  end;
end;

end.
