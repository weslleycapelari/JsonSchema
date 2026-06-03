unit JsonSchema.Keywords.MinProperties;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'minProperties' keyword.
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
  /// <summary>Validates whether the number of properties in a JSON object is greater than or equal to the limit.</summary>
  TMinPropertiesKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FMinProperties: Integer;
    function GetKeywordName: string;
  public
    /// <summary>Initializes the validator with the defined minProperties limit.</summary>
    constructor Create(const pMinProperties: Integer);

    /// <summary>Validates the JSON instance object against the minProperties limit.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('minProperties').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TMinPropertiesKeyword }

class function TMinPropertiesKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TMinPropertiesKeyword.Create(Round(TJSONNumber(pKeywordValue).AsDouble));
end;

constructor TMinPropertiesKeyword.Create(const pMinProperties: Integer);
begin
  inherited Create;
  FMinProperties := pMinProperties;
end;

function TMinPropertiesKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_MINPROPERTIES;
end;

function TMinPropertiesKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lCount: Integer;
  lContext: TJSONObject;
begin
  // minProperties validation only applies to JSON objects. Other types are ignored (valid).
  if not pInstance.IsJSONObject then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lCount := TJSONObject(pInstance).Count;

  if lCount >= FMinProperties then
    Result := TValidationResult.ValidResult
  else
  begin
    lContext := TJSONObject.Create;
    try
      lContext.AddPair('limit', TJSONNumber.Create(FMinProperties));
      lContext.AddPair('actual', TJSONNumber.Create(lCount));
      Result := TValidationResult.InvalidResult(GetKeywordName, lContext);
    finally
      lContext.Free;
    end;
  end;
end;

end.
