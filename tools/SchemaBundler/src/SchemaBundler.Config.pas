unit SchemaBundler.Config;

(*
--------------------------------------------------------------------------------
Command-line Configuration and Parser for SchemaBundler CLI.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils, System.Classes;

type
  /// <summary>Options configuration for SchemaBundler CLI.</summary>
  TSchemaBundlerConfig = record
    InputPath: string;
    OutputPath: string;
    UseLegacy: Boolean;
    Minify: Boolean;
    ShowHelp: Boolean;
  end;

/// <summary>Parses command line arguments into a config record.</summary>
function ParseCommandLine: TSchemaBundlerConfig;

implementation

function ParseCommandLine: TSchemaBundlerConfig;
var
  lI: Integer;
  lArg: string;
begin
  // Set default values
  Result.InputPath := '';
  Result.OutputPath := '';
  Result.UseLegacy := False;
  Result.Minify := False;
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
    else if (SameText(lArg, '-o') or SameText(lArg, '--output')) and (lI < ParamCount) then
    begin
      Result.OutputPath := ParamStr(lI + 1);
      Inc(lI, 2);
    end
    else if SameText(lArg, '--legacy') then
    begin
      Result.UseLegacy := True;
      Inc(lI);
    end
    else if SameText(lArg, '--minify') then
    begin
      Result.Minify := True;
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
