unit Schema2Doc.Config;

(*
--------------------------------------------------------------------------------
Command-line Configuration and Parser for Schema2Doc CLI.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils, System.Classes;

type
  /// <summary>Options configuration for Schema2Doc CLI converter.</summary>
  TSchema2DocConfig = record
    SchemaPath: string;
    OutputPath: string;
    Format: string;
    TitleOverride: string;
    ShowHelp: Boolean;
  end;

/// <summary>Parses command line arguments into a config record.</summary>
function ParseCommandLine: TSchema2DocConfig;

implementation

function ParseCommandLine: TSchema2DocConfig;
var
  lI: Integer;
  lArg: string;
begin
  // Set default values
  Result.SchemaPath := '';
  Result.OutputPath := '';
  Result.Format := 'markdown';
  Result.TitleOverride := '';
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
    else if (SameText(lArg, '-o') or SameText(lArg, '--output')) and (lI < ParamCount) then
    begin
      Result.OutputPath := ParamStr(lI + 1);
      Inc(lI, 2);
    end
    else if (SameText(lArg, '-f') or SameText(lArg, '--format')) and (lI < ParamCount) then
    begin
      Result.Format := ParamStr(lI + 1);
      Inc(lI, 2);
    end
    else if (SameText(lArg, '-t') or SameText(lArg, '--title')) and (lI < ParamCount) then
    begin
      Result.TitleOverride := ParamStr(lI + 1);
      Inc(lI, 2);
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
