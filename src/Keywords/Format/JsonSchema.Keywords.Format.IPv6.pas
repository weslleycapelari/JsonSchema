unit JsonSchema.Keywords.Format.IPv6;

(*
--------------------------------------------------------------------------------
Provides IPv6 address validation helper functions.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils,
  System.RegularExpressions,
  JsonSchema.Keywords.Format.Constants;

/// <summary>Validates whether a given string is a syntactically correct IPv6 address.</summary>
/// <param name="pValue">The string value to validate.</param>
/// <returns>True if the string conforms to IPv6 address guidelines; False otherwise.</returns>
function IsValidIPv6(const pValue: string): Boolean;

implementation

function IsValidIPv6(const pValue: string): Boolean;
var
  lDoubleColonParts: TArray<string>;
  lLeftParts, lRightParts: TArray<string>;
  lIpv4Part: string;
  lHexVal: Integer;
  lActualSegments: Integer;
  lI: Integer;
  lLastColon: Integer;
  lIpv4Candidate: string;
  lRightHalf: string;
  lLeftCount: Integer;
  lRightCount: Integer;
  lIpWithoutIpv4: string;

  function ValidateSegments(const pParts: TArray<string>; out pCount: Integer): Boolean;
  var
    lSeg: string;
  begin
    pCount := 0;
    Result := True;
    for lSeg in pParts do
    begin
      if not lSeg.IsEmpty then
      begin
        if lSeg.Length > 4 then
          Exit(False);
        if not TryStrToInt('$' + lSeg, lHexVal) then
          Exit(False);
        Inc(pCount);
      end;
    end;
  end;

begin
  Result := False;
  if pValue.IsEmpty then
    Exit;

  // 1. Check for single colon at start or end that is not a double colon (invalid IPv6)
  if pValue.StartsWith(':') and not pValue.StartsWith('::') then
    Exit;

  if pValue.EndsWith(':') and not pValue.EndsWith('::') then
    Exit;

  // 2. Check for invalid characters
  for lI := 1 to Length(pValue) do
  begin
    if not CharInSet(pValue[lI], ['0'..'9', 'a'..'f', 'A'..'F', ':', '.']) then
      Exit;
  end;

  // 3. Check for double colon count (at most one)
  if pValue.Contains('::') then
  begin
    if pValue.IndexOf('::') <> pValue.LastIndexOf('::') then
      Exit;
  end;

  // 3. Extract and validate IPv4 part if present
  lIpv4Part := '';
  lLastColon := pValue.LastIndexOf(':');
  lIpv4Candidate := pValue.Substring(lLastColon + 1);
  if lIpv4Candidate.Contains('.') then
  begin
    if not TRegEx.IsMatch(lIpv4Candidate, REGEX_IPV4_CANDIDATE, [roCompiled]) then
      Exit;
    lIpv4Part := lIpv4Candidate;
  end;

  // 4. Split by double colon if present
  if pValue.Contains('::') then
  begin
    lDoubleColonParts := pValue.Split(['::'], TStringSplitOptions.None);
    if Length(lDoubleColonParts) <> 2 then
      Exit;

    lRightHalf := lDoubleColonParts[1];
    if not lIpv4Part.IsEmpty then
    begin
      if lRightHalf.EndsWith(lIpv4Part) then
        lRightHalf := lRightHalf.Substring(0, lRightHalf.Length - lIpv4Part.Length).TrimRight([':']);
    end;

    lLeftParts := lDoubleColonParts[0].Split([':']);
    lLeftCount := 0;
    if not ValidateSegments(lLeftParts, lLeftCount) then
      Exit;

    lRightParts := lRightHalf.Split([':']);
    lRightCount := 0;
    if not ValidateSegments(lRightParts, lRightCount) then
      Exit;

    lActualSegments := lLeftCount + lRightCount;
    if not lIpv4Part.IsEmpty then
      lActualSegments := lActualSegments + 2;

    Result := lActualSegments <= 7;
  end else
  begin
    lIpWithoutIpv4 := pValue;
    if not lIpv4Part.IsEmpty then
    begin
      if lIpWithoutIpv4.EndsWith(lIpv4Part) then
        lIpWithoutIpv4 := lIpWithoutIpv4.Substring(0, lIpWithoutIpv4.Length - lIpv4Part.Length).TrimRight([':']);
    end;

    lLeftParts := lIpWithoutIpv4.Split([':']);
    lLeftCount := 0;
    if not ValidateSegments(lLeftParts, lLeftCount) then
      Exit;

    lActualSegments := lLeftCount;
    if not lIpv4Part.IsEmpty then
      lActualSegments := lActualSegments + 2;

    Result := lActualSegments = 8;
  end;
end;

end.
