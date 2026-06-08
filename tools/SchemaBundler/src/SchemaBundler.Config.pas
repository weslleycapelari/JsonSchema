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
    Quiet: Boolean;
    ShowHelp: Boolean;
  end;

/// <summary>Parses command line arguments into a config record.</summary>
function ParseCommandLine: TSchemaBundlerConfig;

/// <summary>Parses a custom array of command line arguments into a config record.</summary>
function ParseCommandLineEx(const pArgs: TArray<string>): TSchemaBundlerConfig;

implementation

function ParseCommandLineEx(const pArgs: TArray<string>): TSchemaBundlerConfig;
var
  lI: Integer;
  lArg: string;
  lPositionalCount: Integer;
begin
  // Set default values
  Result.InputPath := '';
  Result.OutputPath := '';
  Result.UseLegacy := False;
  Result.Minify := False;
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
    else if (SameText(lArg, '-i') or SameText(lArg, '--input') or SameText(lArg, '-s') or SameText(lArg, '--schema')) then
    begin
      Inc(lI);
      if lI < Length(pArgs) then
        Result.InputPath := pArgs[lI];
    end
    else if (SameText(lArg, '-o') or SameText(lArg, '--output')) then
    begin
      Inc(lI);
      if lI < Length(pArgs) then
        Result.OutputPath := pArgs[lI];
    end
    else if SameText(lArg, '--legacy') then
    begin
      Result.UseLegacy := True;
    end
    else if SameText(lArg, '--minify') then
    begin
      Result.Minify := True;
    end
    else if SameText(lArg, '--quiet') then
    begin
      Result.Quiet := True;
    end
    else if not lArg.StartsWith('-') then
    begin
      if lPositionalCount = 0 then
        Result.InputPath := lArg;
      Inc(lPositionalCount);
    end;

    Inc(lI);
  end;
end;

function ParseCommandLine: TSchemaBundlerConfig;
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
