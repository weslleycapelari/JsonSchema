unit JsonSchema.Keywords.ConstKeyword;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'const' keyword under Draft 6.
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
  /// <summary>Validates whether the instance value is deeply equal to the defined constant value.</summary>
  TConstKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FConstValue: TJSONValue;
    function GetKeywordName: string;
  public
    /// <summary>Initializes the validator with the constant value to compare against.</summary>
    /// <param name="pConstValue">The defined constant value in the schema.</param>
    constructor Create(pConstValue: TJSONValue);
    destructor Destroy; override;

    /// <summary>Validates the JSON instance against the constant constraint.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('const').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TConstKeyword }

class function TConstKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TConstKeyword.Create(pKeywordValue);
end;

constructor TConstKeyword.Create(pConstValue: TJSONValue);
begin
  inherited Create;
  // We clone the schema constant value to maintain ownership isolation
  if Assigned(pConstValue) then
    FConstValue := pConstValue.Clone as TJSONValue
  else
    FConstValue := nil;
end;

destructor TConstKeyword.Destroy;
begin
  FConstValue.Free;
  inherited Destroy;
end;

function TConstKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_CONST;
end;

function TConstKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lContext: TJSONObject;
begin
  if FConstValue.DeepEquals(pInstance) then
    Result := TValidationResult.ValidResult
  else
  begin
    lContext := TJSONObject.Create;
    try
      // Store the stringified representation of the constant for translation mapping
      if Assigned(FConstValue) then
        lContext.AddPair('expected', FConstValue.ToString)
      else
        lContext.AddPair('expected', 'null');

      Result := TValidationResult.InvalidResult(GetKeywordName, lContext);
    finally
      lContext.Free;
    end;
  end;
end;

end.
