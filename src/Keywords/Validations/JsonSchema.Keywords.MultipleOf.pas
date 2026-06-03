unit JsonSchema.Keywords.MultipleOf;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'multipleOf' keyword.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  System.SysUtils,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Results;

type
  /// <summary>Validates whether a JSON number is a multiple of the defined value.</summary>
  TMultipleOfKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FMultipleOf: Double;
    function GetKeywordName: string;
  public
    /// <summary>Initializes the validator with the defined multipleOf constraint value.</summary>
    constructor Create(const pMultipleOf: Double);

    /// <summary>Validates the JSON instance against the multipleOf constraint.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('multipleOf').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

uses
  System.Math,
  JsonSchema.JSONHelper;

{ TMultipleOfKeyword }

class function TMultipleOfKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TMultipleOfKeyword.Create(TJSONNumber(pKeywordValue).AsDouble);
end;

constructor TMultipleOfKeyword.Create(const pMultipleOf: Double);
begin
  inherited Create;
  FMultipleOf := pMultipleOf;
end;

function TMultipleOfKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_MULTIPLEOF;
end;

function TMultipleOfKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lValue: Double;
  lQuotient: Double;
  lTemp: Double;
  lDiv: Double;
  lQuot: Double;
  lIsValid: Boolean;
  lContext: TJSONObject;
begin
  // multipleOf validation only applies to JSON numbers. Other types are ignored (valid).
  if not pInstance.IsJSONNumber then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lValue := TJSONNumber(pInstance).AsDouble;

  // Prevent division by zero just in case multipleOf was invalidly defined
  if FMultipleOf <= 0 then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lIsValid := False;
  lQuotient := Abs(lValue) / FMultipleOf;

  if (lQuotient <> System.Math.Infinity) and (lQuotient <> -System.Math.Infinity) then
  begin
    if Abs(lQuotient - Round(lQuotient)) < 1e-11 then
      lIsValid := True;
  end
  else
  begin
    lTemp := Abs(lValue);
    // Scale down using large steps to avoid exponent overflow during divisions
    while lTemp >= FMultipleOf do
    begin
      lDiv := FMultipleOf;
      while (lTemp >= lDiv * 1073741824.0) and (lDiv < 1e298) do
        lDiv := lDiv * 1073741824.0;

      lQuot := lTemp / lDiv;
      lTemp := lTemp - Int(lQuot) * lDiv;

      if lDiv = FMultipleOf then
        Break;
    end;

    if (lTemp < 1e-11) or (Abs(lTemp - FMultipleOf) < 1e-11) then
      lIsValid := True;
  end;

  if lIsValid then
    Result := TValidationResult.ValidResult
  else
  begin
    lContext := TJSONObject.Create;
    try
      lContext.AddPair('limit', TJSONNumber.Create(FMultipleOf));
      lContext.AddPair('actual', TJSONNumber.Create(lValue));
      Result := TValidationResult.InvalidResult(GetKeywordName, lContext);
    finally
      lContext.Free;
    end;
  end;
end;

end.
