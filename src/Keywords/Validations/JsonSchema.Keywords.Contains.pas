unit JsonSchema.Keywords.Contains;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'contains' keyword.
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
  /// <summary>Validates whether at least one element in a JSON array conforms to a sub-schema.</summary>
  TContainsKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FContainsSchema: ICompiledSchema;
    function GetKeywordName: string;
  public
    /// <summary>Initializes the contains keyword validator with the compiled sub-schema.</summary>
    constructor Create(const pContainsSchema: ICompiledSchema);

    /// <summary>Validates the JSON instance array against the contains schema.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('contains').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TContainsKeyword }

class function TContainsKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TContainsKeyword.Create(pCompileFunc(pKeywordValue));
end;

constructor TContainsKeyword.Create(const pContainsSchema: ICompiledSchema);
begin
  inherited Create;
  FContainsSchema := pContainsSchema;
end;

function TContainsKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_CONTAINS;
end;

function TContainsKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lArray: TJSONArray;
  lIndex: Integer;
  lContainsValid: Boolean;
begin
  // contains validation only applies to JSON arrays. Other types are ignored (valid).
  if not pInstance.IsJSONArray then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lArray := TJSONArray(pInstance);
  lContainsValid := False;

  lIndex := 0;
  while (not lContainsValid) and (lIndex < lArray.Count) do
  begin
    if FContainsSchema.Validate(lArray.Items[lIndex]).IsValid then
    begin
      lContainsValid := True;
    end;
    Inc(lIndex);
  end;

  if lContainsValid then
    Result := TValidationResult.ValidResult
  else
    Result := TValidationResult.InvalidResult(GetKeywordName);
end;

end.
