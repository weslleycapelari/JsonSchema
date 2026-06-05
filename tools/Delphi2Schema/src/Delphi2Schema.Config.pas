unit Delphi2Schema.Config;

(*
--------------------------------------------------------------------------------
Defines the CLI configuration and handles parsing of command line arguments.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils;

type
  /// <summary>Parsed configuration settings for Delphi2Schema CLI.</summary>
  TConfig = record
    TypeName: string;
    OutputPath: string;
    BplPath: string;
    ScanFields: Boolean;
    ScanProperties: Boolean;
    UseEnumNames: Boolean;
    ShowHelp: Boolean;
  end;

/// <summary>Parses command line arguments into a TConfig record.</summary>
function ParseArguments: TConfig;

/// <summary>Parses a custom array of command line arguments into a TConfig record.</summary>
function ParseArgumentsEx(const pArgs: TArray<string>): TConfig;

implementation

function ParseArgumentsEx(const pArgs: TArray<string>): TConfig;
var
  lI: Integer;
  lArg: string;
begin
  Result.TypeName := '';
  Result.OutputPath := '';
  Result.BplPath := '';
  Result.ScanFields := False;
  Result.ScanProperties := True;
  Result.UseEnumNames := True;
  Result.ShowHelp := False;

  lI := 0;
  while lI < Length(pArgs) do
  begin
    lArg := pArgs[lI];

    if SameText(lArg, '-h') or SameText(lArg, '--help') then
    begin
      Result.ShowHelp := True;
      Exit;
    end else if SameText(lArg, '-t') or SameText(lArg, '--type') then
    begin
      Inc(lI);
      if lI < Length(pArgs) then
        Result.TypeName := pArgs[lI];
    end else if SameText(lArg, '-o') or SameText(lArg, '--output') then
    begin
      Inc(lI);
      if lI < Length(pArgs) then
        Result.OutputPath := pArgs[lI];
    end else if SameText(lArg, '-b') or SameText(lArg, '--bpl') then
    begin
      Inc(lI);
      if lI < Length(pArgs) then
        Result.BplPath := pArgs[lI];
    end else if SameText(lArg, '-f') or SameText(lArg, '--fields') then
    begin
      Result.ScanFields := True;
      Result.ScanProperties := False;
    end else if SameText(lArg, '-p') or SameText(lArg, '--properties') then
    begin
      Result.ScanProperties := True;
    end else if SameText(lArg, '--no-enum-names') then
    begin
      Result.UseEnumNames := False;
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
