unit JsonSchema.Keywords.Maximum;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'maximum' keyword under Draft 6.
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
  /// <summary>Validates whether a JSON number is less than or equal to the defined maximum.</summary>
  TMaximumKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FMaximum: Double;
    function GetKeywordName: string;
  public
    /// <summary>Initializes the validator with the defined maximum threshold.</summary>
    /// <param name="pMaximum">The maximum value allowed.</param>
    constructor Create(const pMaximum: Double);

    /// <summary>Validates the JSON instance against the maximum limit.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('maximum').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TMaximumKeyword }

class function TMaximumKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TMaximumKeyword.Create(TJSONNumber(pKeywordValue).AsDouble);
end;

constructor TMaximumKeyword.Create(const pMaximum: Double);
begin
  inherited Create;
  FMaximum := pMaximum;
end;

function TMaximumKeyword.GetKeywordName: string;
begin
  Result := 'maximum';
end;

function TMaximumKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lValue: Double;
  lContext: TJSONObject;
begin
  // maximum validation only applies to JSON numbers. Other types are ignored (valid).
  if not pInstance.IsJSONNumber then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lValue := TJSONNumber(pInstance).AsDouble;

  if lValue <= FMaximum then
    Result := TValidationResult.ValidResult
  else
  begin
    lContext := TJSONObject.Create;
    try
      lContext.AddPair('limit', TJSONNumber.Create(FMaximum));
      lContext.AddPair('actual', TJSONNumber.Create(lValue));
      Result := TValidationResult.InvalidResult(GetKeywordName, lContext);
    finally
      lContext.Free;
    end;
  end;
end;

end.
