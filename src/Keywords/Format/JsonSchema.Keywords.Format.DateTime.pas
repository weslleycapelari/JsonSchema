unit JsonSchema.Keywords.Format.DateTime;

(*
--------------------------------------------------------------------------------
Provides date and time formatting and validity checks, supporting leap seconds.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils,
  System.DateUtils,
  System.RegularExpressions,
  JsonSchema.Keywords.Format.Constants;

/// <summary>Helper method to perform exception-safe ISO8601 conversion.</summary>
function SafeTryISO8601ToDate(const pStr: string; out pDate: TDateTime): Boolean;

/// <summary>Validates leap second offsets (HH:MM:60) ensuring it falls on the 23:59 UTC minute.</summary>
function IsLeapSecondTimeValid(const pHourStr, pMinStr, pOffsetSign, pOffsetHourStr, pOffsetMinStr: string): Boolean;

/// <summary>Validates a complete date-time string against RFC 3339 constraints.</summary>
function IsValidDateTime(const pValue: string): Boolean;

/// <summary>Validates a full-time string against RFC 3339 constraints.</summary>
function IsValidTime(const pValue: string): Boolean;

/// <summary>Validates a full-date string (YYYY-MM-DD) against ISO 8601 / RFC 3339 constraints.</summary>
function IsValidDate(const pValue: string): Boolean;

implementation

function SafeTryISO8601ToDate(const pStr: string; out pDate: TDateTime): Boolean;
begin
  try
    Result := TryISO8601ToDate(pStr, pDate);
  except
    Result := False;
  end;
end;

function IsLeapSecondTimeValid(const pHourStr, pMinStr, pOffsetSign, pOffsetHourStr, pOffsetMinStr: string): Boolean;
var
  lHour, lMin, lOffH, lOffM, lSign: Integer;
  lUtcHour, lUtcMin: Integer;
begin
  Result := False;
  if not TryStrToInt(pHourStr, lHour) then
    Exit;

  if not TryStrToInt(pMinStr, lMin) then
    Exit;

  if pOffsetSign.IsEmpty then
  begin
    Result := (lHour = 23) and (lMin = 59);
    Exit;
  end;

  if not TryStrToInt(pOffsetHourStr, lOffH) then
    Exit;

  if not TryStrToInt(pOffsetMinStr, lOffM) then
    Exit;

  if pOffsetSign = '+' then
    lSign := 1
  else
    lSign := -1;

  lUtcMin := lMin - (lSign * lOffM);
  lUtcHour := lHour - (lSign * lOffH);

  if lUtcMin < 0 then
  begin
    lUtcMin := lUtcMin + 60;
    Dec(lUtcHour);
  end else if lUtcMin >= 60 then
  begin
    lUtcMin := lUtcMin - 60;
    Inc(lUtcHour);
  end;

  lUtcHour := (lUtcHour + 24) mod 24;

  Result := (lUtcHour = 23) and (lUtcMin = 59);
end;

function IsValidDateTime(const pValue: string): Boolean;
var
  lTempDate: TDateTime;
  lUpperVal: string;
  lMatch: TMatch;
begin
  lUpperVal := pValue.ToUpper;
  lMatch := TRegEx.Match(lUpperVal, REGEX_DATETIME);
  if not lMatch.Success then
    Exit(False);

  if StrToIntDef(lMatch.Groups[1].Value, 0) >= 24 then
    Exit(False);

  if lMatch.Groups[3].Value = '60' then
  begin
    if lMatch.Groups[4].Value = 'Z' then
    begin
      if (lMatch.Groups[1].Value <> '23') or (lMatch.Groups[2].Value <> '59') then
        Exit(False);
    end else
    begin
      if not IsLeapSecondTimeValid(
        lMatch.Groups[1].Value,
        lMatch.Groups[2].Value,
        lMatch.Groups[5].Value,
        lMatch.Groups[6].Value,
        lMatch.Groups[7].Value
      ) then
        Exit(False);
    end;
    lUpperVal := lUpperVal.Substring(0, 17) + '59' + lUpperVal.Substring(19);
  end;

  Result := SafeTryISO8601ToDate(lUpperVal, lTempDate);
end;

function IsValidTime(const pValue: string): Boolean;
var
  lTempDate: TDateTime;
  lUpperVal: string;
  lMatch: TMatch;
begin
  lUpperVal := pValue.ToUpper;
  lMatch := TRegEx.Match(lUpperVal, REGEX_TIME);
  if not lMatch.Success then
    Exit(False);

  if StrToIntDef(lMatch.Groups[1].Value, 0) >= 24 then
    Exit(False);

  if lMatch.Groups[3].Value = '60' then
  begin
    if lMatch.Groups[4].Value = 'Z' then
    begin
      if (lMatch.Groups[1].Value <> '23') or (lMatch.Groups[2].Value <> '59') then
        Exit(False);
    end else
    begin
      if not IsLeapSecondTimeValid(
        lMatch.Groups[1].Value,
        lMatch.Groups[2].Value,
        lMatch.Groups[5].Value,
        lMatch.Groups[6].Value,
        lMatch.Groups[7].Value
      ) then
        Exit(False);
    end;
    lUpperVal := '23:59:59' + lUpperVal.Substring(8);
  end;

  Result := SafeTryISO8601ToDate('2000-01-01T' + lUpperVal, lTempDate);
end;

function IsValidDate(const pValue: string): Boolean;
var
  lTempDate: TDateTime;
begin
  Result := TRegEx.IsMatch(pValue, REGEX_DATE, [roCompiled]) and
    SafeTryISO8601ToDate(pValue + 'T00:00:00Z', lTempDate);
end;

end.
