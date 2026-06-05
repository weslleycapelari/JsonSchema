unit Schema2Delphi.Sanitizer;

(*
--------------------------------------------------------------------------------
Provides string sanitization, Pascal-case conversion, and Delphi keyword checking
utilities to avoid syntax conflicts in generated code.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils,
  System.Character,
  System.RegularExpressions;

/// <summary>Checks if a string matches a Delphi language reserved keyword.</summary>
function IsDelphiKeyword(const pWord: string): Boolean;

/// <summary>Converts a string to Pascal Case (Upper Camel Case).</summary>
function ToPascalCase(const pValue: string): string;

/// <summary>Sanitizes a property name, applying Pascal Case and keyword checks.</summary>
function SanitizePropertyName(const pName: string): string;

/// <summary>Generates a safe Pascal enum identifier from a schema string value.</summary>
function SanitizeForEnumIdentifier(const pDescription: string; const pPrefix: string): string;

implementation

function IsDelphiKeyword(const pWord: string): Boolean;
const
  KEYWORDS: array[0..71] of string = (
    'and', 'array', 'as', 'asm', 'begin', 'case', 'class', 'const',
    'constructor', 'destructor', 'dispinterface', 'div', 'do', 'downto',
    'else', 'end', 'except', 'exports', 'file', 'finalization',
    'finally', 'for', 'function', 'goto', 'if', 'implementation',
    'in', 'inherited', 'initialization', 'inline', 'interface', 'is',
    'label', 'library', 'mod', 'nil', 'not', 'object', 'of', 'on',
    'or', 'out', 'packed', 'procedure', 'program', 'property', 'raise',
    'record', 'repeat', 'resourcestring', 'set', 'shl', 'shr', 'string',
    'then', 'threadvar', 'to', 'try', 'type', 'unit', 'until', 'uses',
    'var', 'while', 'with', 'xor', 'strict', 'private', 'protected',
    'public', 'published', 'helper'
  );
var
  lWord, lKeyword: string;
begin
  lWord := pWord.ToLower;
  for lKeyword in KEYWORDS do
  begin
    if lWord = lKeyword then
      Exit(True);
  end;
  Result := False;
end;

function ToPascalCase(const pValue: string): string;
var
  lI: Integer;
  lIsNewWord: Boolean;
begin
  if pValue.IsEmpty then
    Exit('');
  Result := '';
  lIsNewWord := True;
  for lI := 1 to Length(pValue) do
  begin
    if CharInSet(pValue[lI], [' ', '_', '-']) then
      lIsNewWord := True
    else if lIsNewWord then
    begin
      Result := Result + UpperCase(pValue[lI]);
      lIsNewWord := False;
    end else
      Result := Result + pValue[lI];
  end;
end;

function SanitizePropertyName(const pName: string): string;
var
  lName: string;
begin
  lName := ToPascalCase(pName);
  if (lName.Length > 0) and CharInSet(lName[1], ['0'..'9']) then
    lName := 'Prop' + lName;
  if IsDelphiKeyword(lName) then
    lName := 'A' + lName;
  Result := lName;
end;

function SanitizeForEnumIdentifier(const pDescription: string; const pPrefix: string): string;
var
  lCleanDesc: string;
begin
  lCleanDesc := TRegEx.Replace(pDescription, '[^a-zA-Z0-9_\-]', '').ToLower;
  lCleanDesc := ToPascalCase(lCleanDesc);
  if lCleanDesc.IsEmpty then
    Result := pPrefix + 'Unknown'
  else
    Result := pPrefix + lCleanDesc;
end;

end.
