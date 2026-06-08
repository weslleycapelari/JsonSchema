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
    Quiet: Boolean;
    ShowHelp: Boolean;
  end;

/// <summary>Parses command line arguments into a config record.</summary>
function ParseCommandLine: TSchema2DocConfig;

/// <summary>Parses a custom array of command line arguments into a config record.</summary>
function ParseCommandLineEx(const pArgs: TArray<string>): TSchema2DocConfig;

implementation

function ParseCommandLineEx(const pArgs: TArray<string>): TSchema2DocConfig;
var
  lI: Integer;
  lArg: string;
  lPositionalCount: Integer;
begin
  // Set default values
  Result.SchemaPath := '';
  Result.OutputPath := '';
  Result.Format := 'markdown';
  Result.TitleOverride := '';
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
        Result.SchemaPath := pArgs[lI];
    end
    else if (SameText(lArg, '-o') or SameText(lArg, '--output')) then
    begin
      Inc(lI);
      if lI < Length(pArgs) then
        Result.OutputPath := pArgs[lI];
    end
    else if (SameText(lArg, '-f') or SameText(lArg, '--format')) then
    begin
      Inc(lI);
      if lI < Length(pArgs) then
        Result.Format := pArgs[lI];
    end
    else if (SameText(lArg, '-t') or SameText(lArg, '--title')) then
    begin
      Inc(lI);
      if lI < Length(pArgs) then
        Result.TitleOverride := pArgs[lI];
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

function ParseCommandLine: TSchema2DocConfig;
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
