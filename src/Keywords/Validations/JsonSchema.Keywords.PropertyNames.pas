unit JsonSchema.Keywords.PropertyNames;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'propertyNames' keyword.
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
  /// <summary>Validates whether all property names (keys) of a JSON object conform to a sub-schema.</summary>
  TPropertyNamesKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FPropertyNamesSchema: ICompiledSchema;
    function GetKeywordName: string;
  public
    /// <summary>Initializes the propertyNames validator with the compiled sub-schema.</summary>
    constructor Create(const pPropertyNamesSchema: ICompiledSchema);

    /// <summary>Validates all property names of the JSON instance object.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('propertyNames').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TPropertyNamesKeyword }

class function TPropertyNamesKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TPropertyNamesKeyword.Create(pCompileFunc(pKeywordValue));
end;

constructor TPropertyNamesKeyword.Create(const pPropertyNamesSchema: ICompiledSchema);
begin
  inherited Create;
  FPropertyNamesSchema := pPropertyNamesSchema;
end;

function TPropertyNamesKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_PROPERTYNAMES;
end;

function TPropertyNamesKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lObj: TJSONObject;
  lPair: TJSONPair;
  lKeyStr: TJSONString;
  lResults: TArray<IValidationResult>;
  lValid: Boolean;
begin
  // propertyNames validation only applies to JSON objects. Other types are ignored (valid).
  if not pInstance.IsJSONObject then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lObj := TJSONObject(pInstance);
  lResults := [];
  lValid := True;

  for lPair in lObj do
  begin
    lKeyStr := TJSONString.Create(lPair.JsonString.Value);
    try
      lResults := lResults + [FPropertyNamesSchema.Validate(lKeyStr)];
      if not lResults[High(lResults)].IsValid then
      begin
        lValid := False;
      end;
    finally
      lKeyStr.Free;
    end;
  end;

  if lValid then
    Result := TValidationResult.ValidResult
  else
    Result := TValidationResult.Combined(lResults);
end;

end.
