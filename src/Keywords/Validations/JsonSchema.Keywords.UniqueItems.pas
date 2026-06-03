unit JsonSchema.Keywords.UniqueItems;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'uniqueItems' keyword.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  System.SysUtils,
  System.Generics.Collections,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Results;

type
  /// <summary>Validates whether all elements in a JSON array are unique.</summary>
  TUniqueItemsKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FUnique: Boolean;
    function GetKeywordName: string;
  public
    /// <summary>Initializes the validator with the defined uniqueItems flag.</summary>
    constructor Create(const pUnique: Boolean);

    /// <summary>Validates the JSON instance array for element uniqueness.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('uniqueItems').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TUniqueItemsKeyword }

class function TUniqueItemsKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  if pKeywordValue is TJSONBool then
    Result := TUniqueItemsKeyword.Create(TJSONBool(pKeywordValue).AsBoolean)
  else
    Result := nil;
end;

constructor TUniqueItemsKeyword.Create(const pUnique: Boolean);
begin
  inherited Create;
  FUnique := pUnique;
end;

function TUniqueItemsKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_UNIQUEITEMS;
end;

function TUniqueItemsKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lArray: TJSONArray;
  lOuter, lInner: Integer;
  lUnique: Boolean;
begin
  // uniqueItems validation only applies to JSON arrays. Other types are ignored (valid).
  if not pInstance.IsJSONArray then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  // If uniqueItems is false, any array is valid.
  if not FUnique then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lArray := TJSONArray(pInstance);
  lUnique := True;

  lOuter := 0;
  while lUnique and (lOuter < lArray.Count - 1) do
  begin
    lInner := lOuter + 1;
    while lUnique and (lInner < lArray.Count) do
    begin
      if lArray.Items[lOuter].DeepEquals(lArray.Items[lInner]) then
      begin
        lUnique := False;
      end;
      Inc(lInner);
    end;
    Inc(lOuter);
  end;

  if lUnique then
    Result := TValidationResult.ValidResult
  else
    Result := TValidationResult.InvalidResult(GetKeywordName);
end;

end.
