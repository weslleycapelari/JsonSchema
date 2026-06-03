unit JsonSchema.Keywords.Contains;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'contains' keyword, supporting
minContains and maxContains.
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
  /// <summary>Validates whether elements in a JSON array conform to a sub-schema within contains limits.</summary>
  TContainsKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FContainsSchema: ICompiledSchema;
    FMinContains: Integer;
    FMaxContains: Integer;
    function GetKeywordName: string;
  public
    /// <summary>Initializes contains keyword validator with limits.</summary>
    constructor Create(const pContainsSchema: ICompiledSchema; const pMinContains: Integer = 1; const pMaxContains: Integer = -1);

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
  JsonSchema.JSONHelper,
  JsonSchema.Core.ValidationContext;

{ TContainsKeyword }

class function TContainsKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
var
  lMin: Integer;
  lMax: Integer;
  lVal: TJSONValue;
begin
  lMin := 1;
  lMax := -1;
  if Assigned(pParentSchema) then
  begin
    if pParentSchema.TryGetValue('minContains', lVal) and (lVal is TJSONNumber) then
      lMin := Trunc(TJSONNumber(lVal).AsDouble);
    if pParentSchema.TryGetValue('maxContains', lVal) and (lVal is TJSONNumber) then
      lMax := Trunc(TJSONNumber(lVal).AsDouble);
  end;
  Result := TContainsKeyword.Create(pCompileFunc(pKeywordValue), lMin, lMax);
end;

constructor TContainsKeyword.Create(const pContainsSchema: ICompiledSchema; const pMinContains: Integer; const pMaxContains: Integer);
begin
  inherited Create;
  FContainsSchema := pContainsSchema;
  FMinContains := pMinContains;
  FMaxContains := pMaxContains;
end;

function TContainsKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_CONTAINS;
end;

function TContainsKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lArray: TJSONArray;
  lIndex: Integer;
  lMatchCount: Integer;
  lIsValid: Boolean;
begin
  if not pInstance.IsJSONArray then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lArray := TJSONArray(pInstance);
  lMatchCount := 0;

  lIndex := 0;
  while lIndex < lArray.Count do
  begin
    if FContainsSchema.Validate(lArray.Items[lIndex]).IsValid then
    begin
      Inc(lMatchCount);
      TValidationContext.MarkItemEvaluated(pInstance, lIndex);
    end;
    Inc(lIndex);
  end;

  lIsValid := (lMatchCount >= FMinContains);
  if lIsValid and (FMaxContains >= 0) then
    lIsValid := (lMatchCount <= FMaxContains);

  if lIsValid then
    Result := TValidationResult.ValidResult
  else
    Result := TValidationResult.InvalidResult(GetKeywordName);
end;

end.
