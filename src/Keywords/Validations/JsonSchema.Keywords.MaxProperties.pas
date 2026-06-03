unit JsonSchema.Keywords.MaxProperties;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'maxProperties' keyword.
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
  /// <summary>Validates whether the number of properties in a JSON object is less than or equal to the limit.</summary>
  TMaxPropertiesKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FMaxProperties: Integer;
    function GetKeywordName: string;
  public
    /// <summary>Initializes the validator with the defined maxProperties limit.</summary>
    constructor Create(const pMaxProperties: Integer);

    /// <summary>Validates the JSON instance object against the maxProperties limit.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('maxProperties').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TMaxPropertiesKeyword }

class function TMaxPropertiesKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TMaxPropertiesKeyword.Create(Round(TJSONNumber(pKeywordValue).AsDouble));
end;

constructor TMaxPropertiesKeyword.Create(const pMaxProperties: Integer);
begin
  inherited Create;
  FMaxProperties := pMaxProperties;
end;

function TMaxPropertiesKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_MAXPROPERTIES;
end;

function TMaxPropertiesKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lCount: Integer;
  lContext: TJSONObject;
begin
  // maxProperties validation only applies to JSON objects. Other types are ignored (valid).
  if not pInstance.IsJSONObject then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lCount := TJSONObject(pInstance).Count;

  if lCount <= FMaxProperties then
    Result := TValidationResult.ValidResult
  else
  begin
    lContext := TJSONObject.Create;
    try
      lContext.AddPair('limit', TJSONNumber.Create(FMaxProperties));
      lContext.AddPair('actual', TJSONNumber.Create(lCount));
      Result := TValidationResult.InvalidResult(GetKeywordName, lContext);
    finally
      lContext.Free;
    end;
  end;
end;

end.
