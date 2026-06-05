unit JsonSchema.Keywords.Required;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'required' keyword under Draft 6.
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
  /// <summary>Validates whether a JSON object contains all listed required property keys.</summary>
  TRequiredKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FRequiredProperties: TJSONArray;
    function GetKeywordName: string;
  public
    /// <summary>Initializes the validator with the array of required properties.</summary>
    /// <param name="pRequiredProperties">The defined array of required property names in the schema.</param>
    constructor Create(pRequiredProperties: TJSONArray);
    destructor Destroy; override;

    /// <summary>Validates the presence of required properties in the JSON object instance.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('required').</summary>
    property KeywordName: string read GetKeywordName;

    /// <summary>Array of required property names.</summary>
    property RequiredProperties: TJSONArray read FRequiredProperties;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TRequiredKeyword }

class function TRequiredKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  if pKeywordValue is TJSONArray then
  begin
    Result := TRequiredKeyword.Create(TJSONArray(pKeywordValue));
  end else
  begin
    Result := nil;
  end;
end;

constructor TRequiredKeyword.Create(pRequiredProperties: TJSONArray);
begin
  inherited Create;
  // We clone the required properties array to maintain ownership isolation
  if Assigned(pRequiredProperties) then
    FRequiredProperties := pRequiredProperties.Clone as TJSONArray
  else
    FRequiredProperties := nil;
end;

destructor TRequiredKeyword.Destroy;
begin
  FRequiredProperties.Free;
  inherited Destroy;
end;

function TRequiredKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_REQUIRED;
end;

function TRequiredKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lIndex: Integer;
  lReqProp: string;
  lErrors: TArray<IValidationError>;
  lContext: TJSONObject;
begin
  // required validation only applies to JSON objects
  if not pInstance.IsJSONObject then
    Exit(TValidationResult.ValidResult);

  if (FRequiredProperties = nil) or (FRequiredProperties.Count = 0) then
    Exit(TValidationResult.ValidResult);

  lErrors := nil;
  for lIndex := 0 to FRequiredProperties.Count - 1 do
  begin
    if FRequiredProperties.Items[lIndex] is TJSONString then
      lReqProp := TJSONString(FRequiredProperties.Items[lIndex]).Value
    else
      lReqProp := FRequiredProperties.Items[lIndex].ToString;

    // Check if the property is missing from the JSON object
    if TJSONObject(pInstance).Values[lReqProp] = nil then
    begin
      lContext := TJSONObject.Create;
      try
        lContext.AddPair('missing', lReqProp);
        
        SetLength(lErrors, Length(lErrors) + 1);
        lErrors[High(lErrors)] := TValidationError.Create(GetKeywordName, lContext);
      finally
        lContext.Free;
      end;
    end;
  end;

  if Length(lErrors) = 0 then
    Result := TValidationResult.ValidResult
  else
    Result := TValidationResult.Create(False, lErrors);
end;

end.
