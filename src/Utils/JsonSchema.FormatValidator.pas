unit JsonSchema.FormatValidator;

interface

uses
  System.JSON,
  System.RegularExpressions;

type
  /// <summary>
  ///   Validates string values against JSON Schema format assertions
  ///   (ipv4, ipv6, date-time, email, uri, json-pointer, etc.).
  ///   All methods are thread-safe and stateless.
  /// </summary>
  TFormatValidator = class
  public
    /// <summary>Validates an IPv4 address (e.g., "192.168.0.1").</summary>
    class function IsIPv4(const pValue: string): Boolean; static;

    /// <summary>Validates an IPv6 address (e.g., "2001:0db8:85a3::8a2e:0370:7334").</summary>
    class function IsIPv6(const pValue: string): Boolean; static;

    /// <summary>Validates a date-time string per RFC 3339 (e.g., "2024-01-15T14:30:00Z").</summary>
    class function IsDateTime(const pValue: string): Boolean; static;

    /// <summary>Validates a date string (e.g., "2024-01-15").</summary>
    class function IsDate(const pValue: string): Boolean; static;

    /// <summary>Validates a time string (e.g., "14:30:00Z").</summary>
    class function IsTime(const pValue: string): Boolean; static;

    /// <summary>Validates an email address (RFC 5322 simplified).</summary>
    class function IsEmail(const pValue: string): Boolean; static;

    /// <summary>Validates an IDN email (internationalized, Unicode).</summary>
    class function IsIDNEmail(const pValue: string): Boolean; static;

    /// <summary>Validates an IDN hostname (RFC 5890).</summary>
    class function IsIDNHostname(const pValue: string): Boolean; static;

    /// <summary>Validates a URI (absolute, with scheme).</summary>
    class function IsURI(const pValue: string): Boolean; static;

    /// <summary>Validates a URI-reference (absolute or relative).</summary>
    class function IsURIReference(const pValue: string): Boolean; static;

    /// <summary>Validates an IRI (internationalized URI).</summary>
    class function IsIRI(const pValue: string): Boolean; static;

    /// <summary>Validates an IRI-reference (IRI or relative).</summary>
    class function IsIRIReference(const pValue: string): Boolean; static;

    /// <summary>Validates a JSON Pointer (RFC 6901).</summary>
    class function IsJSONPointer(const pValue: string): Boolean; static;

    /// <summary>Validates a Relative JSON Pointer (draft-handrews-relative-json-pointer).</summary>
    class function IsRelativeJSONPointer(const pValue: string): Boolean; static;

    /// <summary>Validates a regular expression string (syntax only).</summary>
    class function IsRegex(const pValue: string): Boolean; static;

    /// <summary>Validates a hostname (RFC 1123, without Unicode).</summary>
    class function IsHostname(const pValue: string): Boolean; static;

    /// <summary>Validates a UUID (RFC 4122).</summary>
    class function IsUUID(const pValue: string): Boolean; static;

    /// <summary>Validates a duration per ISO 8601 (e.g., "P3Y6M4DT12H30M5S").</summary>
    class function IsDuration(const pValue: string): Boolean; static;

    /// <summary>Validates a URI Template (RFC 6570).</summary>
    class function IsURITemplate(const pValue: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  System.DateUtils,
  System.NetEncoding,
  JsonSchema.Registry.Utils,
  JsonSchema.Common.Utils;

{ TFormatValidator }

class function TFormatValidator.IsIPv4(const pValue: string): Boolean;
var
  lParts: TArray<string>;
  lPart: string;
  lNumber: Integer;
begin
  lParts := pValue.Split(['.']);
  if Length(lParts) <> 4 then
    Exit(False);

  for lPart in lParts do
  begin
    if lPart.IsEmpty or not TRegEx.IsMatch(lPart, '^\d+$') then
      Exit(False);

    if (lPart.Length > 1) and (lPart[1] = '0') then
      Exit(False);

    if not TryStrToInt(lPart, lNumber) or (lNumber < 0) or (lNumber > 255) then
      Exit(False);
  end;

  Result := True;
end;

class function TFormatValidator.IsIPv6(const pValue: string): Boolean;
var
  lWorkValue: string;
  lHasCompression: Boolean;
  lParts: TArray<string>;
  lLeftParts: TArray<string>;
  lRightParts: TArray<string>;
  lPart: string;
  lHextetCount: Integer;
  lSplitPos: Integer;
  lLastColon: Integer;
  lIPv4Tail: string;
  lIPv4Valid: Boolean;
  lExpectedHextets: Integer;
begin
  lWorkValue := pValue;
  lExpectedHextets := 8;
  Result := not lWorkValue.IsEmpty;

  if Result and (Pos('.', lWorkValue) > 0) then
  begin
    lLastColon := LastDelimiter(':', lWorkValue);
    if lLastColon = 0 then
      Exit(False);

    lIPv4Tail := Copy(lWorkValue, lLastColon + 1, MaxInt);
    lIPv4Valid := IsIPv4(lIPv4Tail);
    if not lIPv4Valid then
      Exit(False);

    lExpectedHextets := 6;
    if (lLastColon > 1) and (lWorkValue[lLastColon - 1] = ':') then
      lWorkValue := Copy(lWorkValue, 1, lLastColon)
    else
      lWorkValue := Copy(lWorkValue, 1, lLastColon - 1);
  end;

  if Result then
  begin
    if Pos(':::', lWorkValue) > 0 then
      Exit(False);

    lHasCompression := Pos('::', lWorkValue) > 0;

    if lHasCompression then
    begin
      if PosEx('::', lWorkValue, Pos('::', lWorkValue) + 2) > 0 then
        Exit(False);

      lSplitPos := Pos('::', lWorkValue);
      lHextetCount := 0;
      lLeftParts := Copy(lWorkValue, 1, lSplitPos - 1).Split([':']);
      lRightParts := Copy(lWorkValue, lSplitPos + 2, MaxInt).Split([':']);

      for lPart in lLeftParts do
      begin
        if lPart.IsEmpty or not TRegEx.IsMatch(lPart, '^[0-9A-Fa-f]{1,4}$') then
          Exit(False);
        Inc(lHextetCount);
      end;

      for lPart in lRightParts do
      begin
        if lPart.IsEmpty or not TRegEx.IsMatch(lPart, '^[0-9A-Fa-f]{1,4}$') then
          Exit(False);
        Inc(lHextetCount);
      end;

      Result := lHextetCount < lExpectedHextets;
    end
    else
    begin
      lParts := lWorkValue.Split([':']);
      if Length(lParts) <> lExpectedHextets then
        Exit(False);

      for lPart in lParts do
        if lPart.IsEmpty or not TRegEx.IsMatch(lPart, '^[0-9A-Fa-f]{1,4}$') then
          Exit(False);
    end;
  end;
end;

class function TFormatValidator.IsDateTime(const pValue: string): Boolean;
var
  lMatch: TMatch;
  lYear: Integer;
  lMonth: Integer;
  lDay: Integer;
  lHour: Integer;
  lMinute: Integer;
  lSecond: Integer;
  lDateTime: TDateTime;

  function IsLeapSecondValid(const pTimezone: string; const pHour, pMinute: Integer): Boolean;
  var
    lOffsetHour: Integer;
    lOffsetMinute: Integer;
    lOffsetTotal: Integer;
    lUtcTotal: Integer;
    lUtcHour: Integer;
    lUtcMinute: Integer;
    lOffsetSign: Char;
  begin
    if SameText(pTimezone, 'Z') then
      Exit((pHour = 23) and (pMinute = 59));

    lOffsetSign := pTimezone[1];
    if not TryStrToInt(Copy(pTimezone, 2, 2), lOffsetHour) or
       not TryStrToInt(Copy(pTimezone, 5, 2), lOffsetMinute) then
      Exit(False);

    if (lOffsetHour > 23) or (lOffsetMinute > 59) then
      Exit(False);

    lOffsetTotal := (lOffsetHour * 60) + lOffsetMinute;
    lUtcTotal := (pHour * 60) + pMinute;

    if lOffsetSign = '+' then
      lUtcTotal := lUtcTotal - lOffsetTotal
    else
      lUtcTotal := lUtcTotal + lOffsetTotal;

    lUtcTotal := ((lUtcTotal mod 1440) + 1440) mod 1440;
    lUtcHour := lUtcTotal div 60;
    lUtcMinute := lUtcTotal mod 60;
    Result := (lUtcHour = 23) and (lUtcMinute = 59);
  end;

begin
  lMatch := TRegEx.Match(pValue,
    '^(\d{4})-(\d{2})-(\d{2})[Tt](\d{2}):(\d{2}):(\d{2})(?:\.\d+)?([Zz]|[+\-]\d{2}:\d{2})$',
    [roCompiled]);
  if not lMatch.Success then
    Exit(False);

  if not (TryStrToInt(lMatch.Groups[1].Value, lYear) and
          TryStrToInt(lMatch.Groups[2].Value, lMonth) and
          TryStrToInt(lMatch.Groups[3].Value, lDay) and
          TryStrToInt(lMatch.Groups[4].Value, lHour) and
          TryStrToInt(lMatch.Groups[5].Value, lMinute) and
          TryStrToInt(lMatch.Groups[6].Value, lSecond)) then
    Exit(False);

  if not TryEncodeDate(Word(lYear), Word(lMonth), Word(lDay), lDateTime) then
    Exit(False);

  if (lHour > 23) or (lMinute > 59) or (lSecond > 60) then
    Exit(False);

  if lSecond = 60 then
    Exit(IsLeapSecondValid(lMatch.Groups[7].Value, lHour, lMinute));

  Result := True;
end;

class function TFormatValidator.IsDate(const pValue: string): Boolean;
var
  lMatch: TMatch;
  lYear: Integer;
  lMonth: Integer;
  lDay: Integer;
  lDateTime: TDateTime;
begin
  lMatch := TRegEx.Match(pValue,
    '^([0-9]{4})-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$',
    [roCompiled]);
  if not lMatch.Success then
    Exit(False);

  if not (TryStrToInt(lMatch.Groups[1].Value, lYear) and
          TryStrToInt(lMatch.Groups[2].Value, lMonth) and
          TryStrToInt(lMatch.Groups[3].Value, lDay)) then
    Exit(False);

  Result := TryEncodeDate(Word(lYear), Word(lMonth), Word(lDay), lDateTime);
end;

class function TFormatValidator.IsTime(const pValue: string): Boolean;
var
  lMatch: TMatch;
  lHour: Integer;
  lMinute: Integer;
  lSecond: Integer;

  function IsLeapSecondValid(const pTimezone: string; const pHour, pMinute: Integer): Boolean;
  var
    lOffsetHourVal: Integer;
    lOffsetMinuteVal: Integer;
  begin
    if SameText(pTimezone, 'Z') then
      Exit((pHour = 23) and (pMinute = 59));

    if (pTimezone.Length < 6) or not TryStrToInt(pTimezone.Substring(1, 2), lOffsetHourVal) or
       not TryStrToInt(pTimezone.Substring(4, 2), lOffsetMinuteVal) then
      Exit(False);

    Result := (lOffsetHourVal <= 23) and (lOffsetMinuteVal <= 59);
  end;

begin
  lMatch := TRegEx.Match(pValue,
    '^([01][0-9]|2[0-3]):([0-5][0-9]):((?:[0-5][0-9]|60))(?:\.[0-9]+)?([Zz]|[+\-]([01][0-9]|2[0-3]):([0-5][0-9]))$',
    [roCompiled]);
  if not lMatch.Success then
    Exit(False);

  if not (TryStrToInt(lMatch.Groups[1].Value, lHour) and
          TryStrToInt(lMatch.Groups[2].Value, lMinute) and
          TryStrToInt(lMatch.Groups[3].Value, lSecond)) then
    Exit(False);

  if (lHour > 23) or (lMinute > 59) or (lSecond > 60) then
    Exit(False);

  if lSecond = 60 then
  begin
    if lMatch.Groups.Count > 4 then
      Exit(IsLeapSecondValid(lMatch.Groups[4].Value, lHour, lMinute))
    else
      Exit(False);
  end;

  Result := True;
end;

class function TFormatValidator.IsEmail(const pValue: string): Boolean;
begin
  Result := TRegEx.IsMatch(pValue,
    '^[A-Za-z0-9!#$%&''*+/=?^_`{|}~-]+(?:\.[A-Za-z0-9!#$%&''*+/=?^_`{|}~-]+)*@(?:(?!-)[A-Za-z0-9-]{1,63}(?<!-))(?:\.(?:(?!-)[A-Za-z0-9-]{1,63}(?<!-)))*$',
    [roCompiled]);
end;

class function TFormatValidator.IsIDNEmail(const pValue: string): Boolean;
begin
  // Simplified IDN email: Unicode letters, digits, and some symbols, with local@domain
  Result := TRegEx.IsMatch(pValue,
    '^[^\s@]+@(?=.{1,253}$)(?:(?!-)[\p{L}\p{N}-]{1,63}(?<!-))(?:\.(?:(?!-)[\p{L}\p{N}-]{1,63}(?<!-)))*$',
    [roCompiled]);
end;

class function TFormatValidator.IsIDNHostname(const pValue: string): Boolean;
var
  lWorkValue: string;
  lLabels: TArray<string>;
  lLabel: string;
  lIndex: Integer;
  lCodePoint: Integer;
begin
  lWorkValue := pValue;
  for lIndex := 1 to Length(lWorkValue) do
  begin
    lCodePoint := Ord(lWorkValue[lIndex]);
    if (lCodePoint = $3002) or (lCodePoint = $FF0E) or (lCodePoint = $FF61) then
      lWorkValue[lIndex] := '.';
  end;

  if lWorkValue.IsEmpty or (lWorkValue.Length > 253) then
    Exit(False);

  if TRegEx.IsMatch(lWorkValue, '[\x00-\x1F\x7F\s]', [roCompiled]) then
    Exit(False);

  if (lWorkValue[1] = '.') or (lWorkValue[lWorkValue.Length] = '.') then
    Exit(False);

  if Pos('..', lWorkValue) > 0 then
    Exit(False);

  lLabels := lWorkValue.Split(['.']);
  for lLabel in lLabels do
  begin
    if lLabel.IsEmpty or (lLabel.Length > 63) then
      Exit(False);

    if (lLabel[1] = '-') or (lLabel[lLabel.Length] = '-') then
      Exit(False);

    if lLabel.StartsWith('xn--') then
    begin
      if (lLabel.Length <= 4) or not TRegEx.IsMatch(lLabel.Substring(4), '^[a-z0-9-]+$', [roCompiled]) then
        Exit(False);
    end;
  end;

  Result := True;
end;

class function TFormatValidator.IsURI(const pValue: string): Boolean;
begin
  Result := TURIUtils.IsValidURI(pValue);
end;

class function TFormatValidator.IsURIReference(const pValue: string): Boolean;
begin
  Result := TURIUtils.IsValidURIReference(pValue);
end;

class function TFormatValidator.IsIRI(const pValue: string): Boolean;
begin
  // Simplified IRI: scheme:// + Unicode authority/path
  Result := TRegEx.IsMatch(pValue, '^[A-Za-z][A-Za-z0-9+.-]*:[^\s<>"{}|\^`\\]*$', [roCompiled]);
  if Result then
    Result := TRegEx.IsMatch(pValue, '^[^\x00-\x1F\x7F<>"{}|\\^`]+$', [roCompiled]);
end;

class function TFormatValidator.IsIRIReference(const pValue: string): Boolean;
begin
  // Allows relative IRIs and fragments
  if pValue.IsEmpty then
    Exit(True);

  Result := TRegEx.IsMatch(pValue, '^[^\x00-\x1F\x7F<>"{}|\\^`]*$', [roCompiled]);
end;

class function TFormatValidator.IsJSONPointer(const pValue: string): Boolean;
begin
  Result := TURIUtils.IsValidJsonPointer(pValue);
end;

class function TFormatValidator.IsRelativeJSONPointer(const pValue: string): Boolean;
begin
  // non-negative integer, then '#' or JSON Pointer
  Result := TRegEx.IsMatch(pValue, '^(0|[1-9][0-9]*)(#|(/([^~/]|~[01])*)*)$', [roCompiled]);
end;

class function TFormatValidator.IsRegex(const pValue: string): Boolean;
begin
  try
    TRegEx.IsMatch('', pValue);
    Result := True;
  except
    Result := False;
  end;
end;

class function TFormatValidator.IsHostname(const pValue: string): Boolean;
begin
  Result := TRegEx.IsMatch(pValue,
    '^(?=.{1,253}$)(?:(?!-)[A-Za-z0-9-]{1,63}(?<!-))(?:\.(?:(?!-)[A-Za-z0-9-]{1,63}(?<!-)))*$',
    [roCompiled]);
end;

class function TFormatValidator.IsUUID(const pValue: string): Boolean;
begin
  Result := TRegEx.IsMatch(pValue,
    '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    [roCompiled]);
end;

class function TFormatValidator.IsDuration(const pValue: string): Boolean;
begin
  // ISO 8601 duration: PnY nM nDTnH nM nS
  Result := TRegEx.IsMatch(pValue,
    '^P(?!$)((\d+Y)?(\d+M)?(\d+D)?(T(?=\d)(\d+H)?(\d+M)?(\d+S)?)?|(\d+W))$',
    [roCompiled]);
end;

class function TFormatValidator.IsURITemplate(const pValue: string): Boolean;
begin
  // Simplified URI Template validation (RFC 6570)
  Result := TRegEx.IsMatch(pValue,
    '^[A-Za-z][A-Za-z0-9+.-]*:[^\s]*$',
    [roCompiled]);
end;

end.
