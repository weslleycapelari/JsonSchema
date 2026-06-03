unit JsonSchema.Keywords.MaxItems;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'maxItems' keyword under Draft 6.
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
  /// <summary>Validates whether the count of a JSON array items meets the maximum items requirement.</summary>
  TMaxItemsKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FMaxItems: Integer;
    function GetKeywordName: string;
  public
    /// <summary>Initializes the validator with the specified maximum items count.</summary>
    /// <param name="pMaxItems">The maximum number of items allowed in the array.</param>
    constructor Create(const pMaxItems: Integer);

    /// <summary>Validates the count of the JSON array items.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('maxItems').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TMaxItemsKeyword }

class function TMaxItemsKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TMaxItemsKeyword.Create(Round(TJSONNumber(pKeywordValue).AsDouble));
end;

constructor TMaxItemsKeyword.Create(const pMaxItems: Integer);
begin
  inherited Create;
  FMaxItems := pMaxItems;
end;

function TMaxItemsKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_MAXITEMS;
end;

function TMaxItemsKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lLength: Integer;
  lContext: TJSONObject;
begin
  // maxItems validation only applies to JSON arrays. Other types are ignored (valid).
  if not pInstance.IsJSONArray then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lLength := TJSONArray(pInstance).Count;

  if lLength <= FMaxItems then
    Result := TValidationResult.ValidResult
  else
  begin
    lContext := TJSONObject.Create;
    try
      lContext.AddPair('limit', TJSONNumber.Create(FMaxItems));
      lContext.AddPair('actual', TJSONNumber.Create(lLength));
      Result := TValidationResult.InvalidResult(GetKeywordName, lContext);
    finally
      lContext.Free;
    end;
  end;
end;

end.
