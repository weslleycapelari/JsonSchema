unit JsonSchema.Keywords.Format.Iri;

(*
--------------------------------------------------------------------------------
Provides IRI (Internationalized Resource Identifier) validation rules.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils,
  System.RegularExpressions,
  System.Net.URLClient;

/// <summary>Validates whether a given string is a syntactically correct IRI.</summary>
/// <param name="pValue">The string value to validate.</param>
/// <returns>True if the string conforms to IRI requirements; False otherwise.</returns>
function IsValidIri(const pValue: string): Boolean;

implementation

function IsValidIri(const pValue: string): Boolean;
var
  lURI: TURI;
begin
  if TRegEx.IsMatch(pValue, '[\s<>"{}\|\\\^`\\]') then
    Exit(False);
  try
    lURI := TURI.Create(pValue);
    Result := lURI.Scheme <> '';
  except
    Result := False;
  end;
end;

end.
