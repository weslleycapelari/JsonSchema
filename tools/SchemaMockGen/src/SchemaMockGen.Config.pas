unit SchemaMockGen.Config;

(*
--------------------------------------------------------------------------------
Defines the CLI configuration and handles parsing of command line arguments for SchemaMockGen.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils;

type
  /// <summary>Holds the parsed configuration settings for SchemaMockGen.</summary>
  TConfig = record
    SchemaPath: string;
    OutputPath: string;
    Seed: Int64;
    Count: Integer;
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
  lArg, lVal: string;
begin
  Result.SchemaPath := '';
  Result.OutputPath := '';
  Result.Seed := -1; // -1 indicates random seed if not specified
  Result.Count := 1;
  Result.ShowHelp := False;

  lI := 0;
  while lI < Length(pArgs) do
  begin
    lArg := pArgs[lI];

    if SameText(lArg, '-h') or SameText(lArg, '--help') then
    begin
      Result.ShowHelp := True;
      Exit;
    end else if SameText(lArg, '-s') or SameText(lArg, '--schema') then
    begin
      Inc(lI);
      if lI < Length(pArgs) then
        Result.SchemaPath := pArgs[lI];
    end else if SameText(lArg, '-o') or SameText(lArg, '--output') then
    begin
      Inc(lI);
      if lI < Length(pArgs) then
        Result.OutputPath := pArgs[lI];
    end else if SameText(lArg, '-e') or SameText(lArg, '--seed') then
    begin
      Inc(lI);
      if lI < Length(pArgs) then
      begin
        lVal := pArgs[lI];
        if not TryStrToInt64(lVal, Result.Seed) then
          Result.Seed := -1;
      end;
    end else if SameText(lArg, '-n') or SameText(lArg, '--count') then
    begin
      Inc(lI);
      if lI < Length(pArgs) then
      begin
        lVal := pArgs[lI];
        if not TryStrToInt(lVal, Result.Count) or (Result.Count < 1) then
          Result.Count := 1;
      end;
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
