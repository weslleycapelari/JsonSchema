unit JsonSchema.Keywords.Format.UriTemplate;

(*
--------------------------------------------------------------------------------
Provides URI Template format validation rules.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils;

/// <summary>Validates whether a given string is a syntactically correct URI template.</summary>
/// <param name="pValue">The string value to validate.</param>
/// <returns>True if the string conforms to URI template requirements; False otherwise.</returns>
function IsValidUriTemplate(const pValue: string): Boolean;

implementation

function IsValidUriTemplate(const pValue: string): Boolean;
var
  lChar: Char;
  lInBrace: Boolean;
begin
  lInBrace := False;
  for lChar in pValue do
  begin
    if lChar = '{' then
    begin
      if lInBrace then Exit(False);
      lInBrace := True;
    end else if lChar = '}' then
    begin
      if not lInBrace then Exit(False);
      lInBrace := False;
    end;
  end;
  Result := not lInBrace;
end;

end.
