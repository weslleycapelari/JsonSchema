unit SchemaValidatorCLI.Config;

(*
--------------------------------------------------------------------------------
Defines the CLI configuration and handles parsing of command line arguments.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils,
  JsonSchema.Core.Interfaces,
  JsonSchema.Localization.Enums;

type
  /// <summary>Supported validation output formats.</summary>
  TOutputFormat = (ofText, ofJson, ofJUnit);

  /// <summary>Holds the parsed configuration settings for the validator CLI.</summary>
  TConfig = record
    SchemaPath: string;
    InstancePath: string;
    Locale: TLocale;
    OutputFormat: TOutputFormat;
    ForceDraft: Boolean;
    DraftVersion: TDraftVersion;
    EnforceFormats: Boolean;
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
  Result.InstancePath := '';
  Result.Locale := TLocale.EnUS;
  Result.OutputFormat := ofText;
  Result.ForceDraft := False;
  Result.DraftVersion := TDraftVersion.dvDraft2020_12;
  Result.EnforceFormats := True;
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
    end else if SameText(lArg, '-i') or SameText(lArg, '--instance') then
    begin
      Inc(lI);
      if lI < Length(pArgs) then
        Result.InstancePath := pArgs[lI];
    end else if SameText(lArg, '-d') or SameText(lArg, '--draft') then
    begin
      Inc(lI);
      if lI < Length(pArgs) then
      begin
        lVal := pArgs[lI];
        Result.ForceDraft := True;
        if SameText(lVal, '6') or SameText(lVal, 'draft6') then
          Result.DraftVersion := TDraftVersion.dvDraft6
        else if SameText(lVal, '7') or SameText(lVal, 'draft7') then
          Result.DraftVersion := TDraftVersion.dvDraft7
        else if SameText(lVal, '2019-09') or SameText(lVal, 'draft2019-09') then
          Result.DraftVersion := TDraftVersion.dvDraft2019_09
        else if SameText(lVal, '2020-12') or SameText(lVal, 'draft2020-12') then
          Result.DraftVersion := TDraftVersion.dvDraft2020_12
        else
        begin
          Writeln(ErrOutput, 'Warning: Unknown draft version specified, falling back to auto-detect.');
          Result.ForceDraft := False;
        end;
      end;
    end else if SameText(lArg, '-l') or SameText(lArg, '--locale') then
    begin
      Inc(lI);
      if lI < Length(pArgs) then
      begin
        lVal := pArgs[lI];
        if SameText(lVal, 'pt') or SameText(lVal, 'ptbr') then
          Result.Locale := TLocale.PtBR
        else
          Result.Locale := TLocale.EnUS;
      end;
    end else if SameText(lArg, '-f') or SameText(lArg, '--format') then
    begin
      Inc(lI);
      if lI < Length(pArgs) then
      begin
        lVal := pArgs[lI];
        if SameText(lVal, 'json') then
          Result.OutputFormat := ofJson
        else if SameText(lVal, 'junit') then
          Result.OutputFormat := ofJUnit
        else
          Result.OutputFormat := ofText;
      end;
    end else if SameText(lArg, '--no-format') then
    begin
      Result.EnforceFormats := False;
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
