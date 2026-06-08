unit Schema2Delphi.Config;

(*
--------------------------------------------------------------------------------
Defines the CLI configuration and handles parsing of command line arguments for Schema2Delphi.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils;

type
  /// <summary>Holds the parsed configuration settings for Schema2Delphi.</summary>
  TConfig = record
    SchemaPath: string;
    OutputPath: string;
    ClassName: string;
    UnitName: string;
    Quiet: Boolean;
    ShowHelp: Boolean;
  end;

/// <summary>Parses command line arguments into a TConfig record.</summary>
/// <returns>The parsed configuration record.</returns>
function ParseArguments: TConfig;

/// <summary>Parses a custom array of command line arguments into a TConfig record.</summary>
/// <param name="pArgs">The custom array of argument strings.</param>
/// <returns>The parsed configuration record.</returns>
function ParseArgumentsEx(const pArgs: TArray<string>): TConfig;

implementation

function ParseArgumentsEx(const pArgs: TArray<string>): TConfig;
var
  lI: Integer;
  lArg: string;
  lPositionalCount: Integer;
begin
  Result.SchemaPath := '';
  Result.OutputPath := '';
  Result.ClassName := '';
  Result.UnitName := '';
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
    end else if SameText(lArg, '-i') or SameText(lArg, '--input') or SameText(lArg, '-s') or SameText(lArg, '--schema') then
    begin
      Inc(lI);
      if lI < Length(pArgs) then
        Result.SchemaPath := pArgs[lI];
    end else if SameText(lArg, '-o') or SameText(lArg, '--output') then
    begin
      Inc(lI);
      if lI < Length(pArgs) then
        Result.OutputPath := pArgs[lI];
    end else if SameText(lArg, '-c') or SameText(lArg, '--classname') then
    begin
      Inc(lI);
      if lI < Length(pArgs) then
        Result.ClassName := pArgs[lI];
    end else if SameText(lArg, '-u') or SameText(lArg, '--unitname') then
    begin
      Inc(lI);
      if lI < Length(pArgs) then
        Result.UnitName := pArgs[lI];
    end else if SameText(lArg, '--quiet') then
    begin
      Result.Quiet := True;
    end else if not lArg.StartsWith('-') then
    begin
      if lPositionalCount = 0 then
        Result.SchemaPath := lArg;
      Inc(lPositionalCount);
    end;

    Inc(lI);
  end;
end;

function ParseArguments: TConfig;
var
  lArgs: TArray<string>;
  lI: Integer;
begin
  SetLength(lArgs, ParamCount);
  for lI := 1 to ParamCount do
    lArgs[lI - 1] := ParamStr(lI);
  Result := ParseArgumentsEx(lArgs);
end;

end.
