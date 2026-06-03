unit JsonSchema.Keywords.ExclusiveMaximum;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'exclusiveMaximum' keyword.
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
  /// <summary>Validates whether a JSON number is strictly less than the defined exclusive maximum.</summary>
  TExclusiveMaximumKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FExclusiveMaximum: Double;
    function GetKeywordName: string;
  public
    /// <summary>Initializes the validator with the defined exclusive maximum limit.</summary>
    constructor Create(const pExclusiveMaximum: Double);

    /// <summary>Validates the JSON instance against the exclusiveMaximum limit.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('exclusiveMaximum').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TExclusiveMaximumKeyword }

class function TExclusiveMaximumKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TExclusiveMaximumKeyword.Create(TJSONNumber(pKeywordValue).AsDouble);
end;

constructor TExclusiveMaximumKeyword.Create(const pExclusiveMaximum: Double);
begin
  inherited Create;
  FExclusiveMaximum := pExclusiveMaximum;
end;

function TExclusiveMaximumKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_EXCLUSIVEMAXIMUM;
end;

function TExclusiveMaximumKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lValue: Double;
  lContext: TJSONObject;
begin
  // exclusiveMaximum validation only applies to JSON numbers. Other types are ignored (valid).
  if not pInstance.IsJSONNumber then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lValue := TJSONNumber(pInstance).AsDouble;

  if lValue < FExclusiveMaximum then
    Result := TValidationResult.ValidResult
  else
  begin
    lContext := TJSONObject.Create;
    try
      lContext.AddPair('limit', TJSONNumber.Create(FExclusiveMaximum));
      lContext.AddPair('actual', TJSONNumber.Create(lValue));
      Result := TValidationResult.InvalidResult(GetKeywordName, lContext);
    finally
      lContext.Free;
    end;
  end;
end;

end.
