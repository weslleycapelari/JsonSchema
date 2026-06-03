unit JsonSchema.Keywords.Minimum;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'minimum' keyword under Draft 6.
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
  /// <summary>Validates whether a JSON number is greater than or equal to the defined minimum.</summary>
  TMinimumKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FMinimum: Double;
    function GetKeywordName: string;
  public
    /// <summary>Initializes the validator with the defined minimum threshold.</summary>
    /// <param name="pMinimum">The minimum value allowed.</param>
    constructor Create(const pMinimum: Double);

    /// <summary>Validates the JSON instance against the minimum limit.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('minimum').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TMinimumKeyword }

class function TMinimumKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TMinimumKeyword.Create(TJSONNumber(pKeywordValue).AsDouble);
end;

constructor TMinimumKeyword.Create(const pMinimum: Double);
begin
  inherited Create;
  FMinimum := pMinimum;
end;

function TMinimumKeyword.GetKeywordName: string;
begin
  Result := 'minimum';
end;

function TMinimumKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lValue: Double;
  lContext: TJSONObject;
begin
  // minimum validation only applies to JSON numbers. Other types are ignored (valid).
  if not pInstance.IsJSONNumber then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lValue := TJSONNumber(pInstance).AsDouble;

  if lValue >= FMinimum then
    Result := TValidationResult.ValidResult
  else
  begin
    lContext := TJSONObject.Create;
    try
      lContext.AddPair('limit', TJSONNumber.Create(FMinimum));
      lContext.AddPair('actual', TJSONNumber.Create(lValue));
      Result := TValidationResult.InvalidResult(GetKeywordName, lContext);
    finally
      lContext.Free;
    end;
  end;
end;

end.
