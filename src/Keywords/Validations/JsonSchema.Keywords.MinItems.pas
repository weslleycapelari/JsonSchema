unit JsonSchema.Keywords.MinItems;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'minItems' keyword under Draft 6.
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
  /// <summary>Validates whether the count of a JSON array items meets the minimum items requirement.</summary>
  TMinItemsKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FMinItems: Integer;
    function GetKeywordName: string;
  public
    /// <summary>Initializes the validator with the specified minimum items count.</summary>
    /// <param name="pMinItems">The minimum number of items allowed in the array.</param>
    constructor Create(const pMinItems: Integer);

    /// <summary>Validates the count of the JSON array items.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('minItems').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TMinItemsKeyword }

class function TMinItemsKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TMinItemsKeyword.Create(Round(TJSONNumber(pKeywordValue).AsDouble));
end;

constructor TMinItemsKeyword.Create(const pMinItems: Integer);
begin
  inherited Create;
  FMinItems := pMinItems;
end;

function TMinItemsKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_MINITEMS;
end;

function TMinItemsKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lLength: Integer;
  lContext: TJSONObject;
begin
  // minItems validation only applies to JSON arrays. Other types are ignored (valid).
  if not pInstance.IsJSONArray then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lLength := TJSONArray(pInstance).Count;

  if lLength >= FMinItems then
    Result := TValidationResult.ValidResult
  else
  begin
    lContext := TJSONObject.Create;
    try
      lContext.AddPair('limit', TJSONNumber.Create(FMinItems));
      lContext.AddPair('actual', TJSONNumber.Create(lLength));
      Result := TValidationResult.InvalidResult(GetKeywordName, lContext);
    finally
      lContext.Free;
    end;
  end;
end;

end.
