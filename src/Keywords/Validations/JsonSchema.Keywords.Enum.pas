unit JsonSchema.Keywords.Enum;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'enum' keyword under Draft 6.
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
  /// <summary>Validates whether the instance value is deeply equal to one of the defined enum values.</summary>
  TEnumKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FEnumValues: TJSONArray;
    function GetKeywordName: string;
  public
    /// <summary>Initializes the validator with the array of allowed values.</summary>
    /// <param name="pEnumValues">The defined array of allowed values in the schema.</param>
    constructor Create(pEnumValues: TJSONArray);
    destructor Destroy; override;

    /// <summary>Validates the JSON instance against the enum array constraint.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('enum').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TEnumKeyword }

class function TEnumKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  if pKeywordValue is TJSONArray then
  begin
    Result := TEnumKeyword.Create(TJSONArray(pKeywordValue));
  end else
  begin
    Result := nil;
  end;
end;

constructor TEnumKeyword.Create(pEnumValues: TJSONArray);
begin
  inherited Create;
  // We clone the enum values array to maintain ownership isolation
  if Assigned(pEnumValues) then
    FEnumValues := pEnumValues.Clone as TJSONArray
  else
    FEnumValues := nil;
end;

destructor TEnumKeyword.Destroy;
begin
  FEnumValues.Free;
  inherited Destroy;
end;

function TEnumKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_ENUM;
end;

function TEnumKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lIndex: Integer;
  lFound: Boolean;
  lContext: TJSONObject;
begin
  if FEnumValues = nil then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lFound := False;
  lIndex := 0;
  while not lFound and (lIndex < FEnumValues.Count) do
  begin
    lFound := FEnumValues.Items[lIndex].DeepEquals(pInstance);
    Inc(lIndex);
  end;

  if lFound then
    Result := TValidationResult.ValidResult
  else
  begin
    lContext := TJSONObject.Create;
    try
      lContext.AddPair('allowed', FEnumValues.ToString);
      Result := TValidationResult.InvalidResult(GetKeywordName, lContext);
    finally
      lContext.Free;
    end;
  end;
end;

end.
