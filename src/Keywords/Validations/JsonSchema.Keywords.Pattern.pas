unit JsonSchema.Keywords.Pattern;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'pattern' keyword.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  System.SysUtils,
  System.RegularExpressions,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Results;

type
  /// <summary>Validates whether a JSON string matches a defined regular expression pattern.</summary>
  TPatternKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FPattern: string;
    FRegex: TRegEx;
    FIsRegexValid: Boolean;
    function GetKeywordName: string;
  public
    /// <summary>Initializes the validator with the defined regular expression pattern.</summary>
    constructor Create(const pPattern: string);

    /// <summary>Validates the JSON instance string against the regex pattern.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('pattern').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TPatternKeyword }

class function TPatternKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TPatternKeyword.Create(TJSONString(pKeywordValue).Value);
end;

constructor TPatternKeyword.Create(const pPattern: string);
var
  lPcrePattern: string;
begin
  inherited Create;
  FPattern := pPattern;
  FIsRegexValid := True;

  // Translate JS/ECMA-262 regex features to PCRE equivalents
  lPcrePattern := pPattern;
  lPcrePattern := lPcrePattern
    .Replace('\p{Letter}', '\p{L}')
    .Replace('\P{Letter}', '\P{L}')
    .Replace('\p{digit}', '\p{Nd}')
    .Replace('\P{digit}', '\P{Nd}')
    .Replace('\s', '[\s\x{00a0}\x{feff}\p{Zs}\p{Zl}\p{Zp}]')
    .Replace('\S', '[^\s\x{00a0}\x{feff}\p{Zs}\p{Zl}\p{Zp}]');

  try
    FRegex := TRegEx.Create(lPcrePattern, [roCompiled]);
  except
    on E: Exception do
      FIsRegexValid := False;
  end;
end;

function TPatternKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_PATTERN;
end;

function TPatternKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lValue: string;
  lContext: TJSONObject;
begin
  // pattern validation only applies to JSON strings. Other types are ignored (valid).
  if not pInstance.IsJSONString then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lValue := TJSONString(pInstance).Value;

  if not FIsRegexValid then
  begin
    lContext := TJSONObject.Create;
    try
      lContext.AddPair('pattern', TJSONString.Create(FPattern));
      lContext.AddPair('actual', TJSONString.Create(lValue));
      lContext.AddPair('error', TJSONString.Create('Invalid regex pattern'));
      Result := TValidationResult.InvalidResult(GetKeywordName, lContext);
    finally
      lContext.Free;
    end;
    Exit;
  end;

  if FRegex.IsMatch(lValue) then
    Result := TValidationResult.ValidResult
  else
  begin
    lContext := TJSONObject.Create;
    try
      lContext.AddPair('pattern', TJSONString.Create(FPattern));
      lContext.AddPair('actual', TJSONString.Create(lValue));
      Result := TValidationResult.InvalidResult(GetKeywordName, lContext);
    finally
      lContext.Free;
    end;
  end;
end;

end.
