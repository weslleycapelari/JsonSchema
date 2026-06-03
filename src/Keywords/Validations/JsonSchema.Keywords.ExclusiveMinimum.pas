unit JsonSchema.Keywords.ExclusiveMinimum;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'exclusiveMinimum' keyword.
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
  /// <summary>Validates whether a JSON number is strictly greater than the defined exclusive minimum.</summary>
  TExclusiveMinimumKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FExclusiveMinimum: Double;
    function GetKeywordName: string;
  public
    /// <summary>Initializes the validator with the defined exclusive minimum limit.</summary>
    constructor Create(const pExclusiveMinimum: Double);

    /// <summary>Validates the JSON instance against the exclusiveMinimum limit.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('exclusiveMinimum').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TExclusiveMinimumKeyword }

class function TExclusiveMinimumKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TExclusiveMinimumKeyword.Create(TJSONNumber(pKeywordValue).AsDouble);
end;

constructor TExclusiveMinimumKeyword.Create(const pExclusiveMinimum: Double);
begin
  inherited Create;
  FExclusiveMinimum := pExclusiveMinimum;
end;

function TExclusiveMinimumKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_EXCLUSIVEMINIMUM;
end;

function TExclusiveMinimumKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lValue: Double;
  lContext: TJSONObject;
begin
  // exclusiveMinimum validation only applies to JSON numbers. Other types are ignored (valid).
  if not pInstance.IsJSONNumber then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lValue := TJSONNumber(pInstance).AsDouble;

  if lValue > FExclusiveMinimum then
    Result := TValidationResult.ValidResult
  else
  begin
    lContext := TJSONObject.Create;
    try
      lContext.AddPair('limit', TJSONNumber.Create(FExclusiveMinimum));
      lContext.AddPair('actual', TJSONNumber.Create(lValue));
      Result := TValidationResult.InvalidResult(GetKeywordName, lContext);
    finally
      lContext.Free;
    end;
  end;
end;

end.
