unit TestJsonSchema.CLI.Parser;

(*
--------------------------------------------------------------------------------
Provides test suites verifying Command Line Interface (CLI) configuration and argument parser.
--------------------------------------------------------------------------------
*)


interface

uses
  System.Generics.Collections,
  System.StrUtils,
  System.SysUtils;

type
  TCommandLineParser = class
  public
    class function GetValue(const pSwitchName: string): string;
    class function GetValues(const pShortSwitch, pLongSwitch: string): TArray<string>;
    class function HasSwitch(const pSwitchName: string): Boolean;
  end;

implementation

class function TCommandLineParser.GetValue(const pSwitchName: string): string;
var
  lIndex: Integer;
  lParam: string;
  lPrefix: string;
  lLongPrefix: string;
  lFound: Boolean;
begin
  Result := '';
  lFound := False;
  lIndex := 1;
  lPrefix := '-' + pSwitchName + '=';
  lLongPrefix := '--' + pSwitchName + '=';

  // Substituio do comando Exit/Break por condio de parada explcita na norma
  while (lIndex <= ParamCount) and not lFound do
  begin
    lParam := ParamStr(lIndex);

    if SameText(lParam, '-' + pSwitchName) or SameText(lParam, '--' + pSwitchName) then
    begin
      if lIndex < ParamCount then
      begin
        Result := ParamStr(lIndex + 1);
        lFound := True;
      end;
    end else if StartsText(lPrefix, lParam) then
    begin
      Result := Copy(lParam, Length(lPrefix) + 1, MaxInt);
      lFound := True;
    end else if StartsText(lLongPrefix, lParam) then
    begin
      Result := Copy(lParam, Length(lLongPrefix) + 1, MaxInt);
      lFound := True;
    end;

    Inc(lIndex);
  end;
end;

class function TCommandLineParser.GetValues(const pShortSwitch, pLongSwitch: string): TArray<string>;
var
  lIndex: Integer;
  lParam: string;
  lPrefixShort: string;
  lPrefixLong: string;
  lValues: TList<string>;
begin
  lValues := TList<string>.Create;
  try
    lIndex := 1;
    lPrefixShort := '-' + pShortSwitch + '=';
    lPrefixLong := '--' + pLongSwitch + '=';

    // Substituio do comando Continue pela estrutura if..else if correta
    while lIndex <= ParamCount do
    begin
      lParam := ParamStr(lIndex);

      if SameText(lParam, '-' + pShortSwitch) or SameText(lParam, '--' + pLongSwitch) then
      begin
        if lIndex < ParamCount then
          lValues.Add(ParamStr(lIndex + 1));
      end else if StartsText(lPrefixShort, lParam) then
      begin
        lValues.Add(Copy(lParam, Length(lPrefixShort) + 1, MaxInt));
      end else if StartsText(lPrefixLong, lParam) then
      begin
        lValues.Add(Copy(lParam, Length(lPrefixLong) + 1, MaxInt));
      end;

      Inc(lIndex);
    end;

    Result := lValues.ToArray;
  finally
    lValues.Free;
  end;
end;

class function TCommandLineParser.HasSwitch(const pSwitchName: string): Boolean;
var
  lIndex: Integer;
  lParam: string;
begin
  Result := False;
  lIndex := 1;

  // Substituio do comando Exit/Break por condio de parada explcita na norma
  while (lIndex <= ParamCount) and not Result do
  begin
    lParam := ParamStr(lIndex);

    if SameText(lParam, '-' + pSwitchName) or SameText(lParam, '--' + pSwitchName) then
      Result := True;

    Inc(lIndex);
  end;
end;

end.
