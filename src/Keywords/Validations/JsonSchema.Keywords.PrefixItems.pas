unit JsonSchema.Keywords.PrefixItems;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'prefixItems' keyword.
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
  /// <summary>Validates array elements against positional sub-schemas.</summary>
  TPrefixItemsKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FSchemas: TArray<ICompiledSchema>;
    function GetKeywordName: string;
  public
    /// <summary>Initializes prefixItems keyword with the compiled schemas.</summary>
    constructor Create(const pSchemas: TArray<ICompiledSchema>);

    /// <summary>Validates elements of the JSON array instance positionally.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('prefixItems').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

uses
  JsonSchema.JSONHelper,
  JsonSchema.Core.ValidationContext;

{ TPrefixItemsKeyword }

class function TPrefixItemsKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
var
  lArr: TJSONArray;
  lSchemas: TArray<ICompiledSchema>;
  lIndex: Integer;
begin
  lSchemas := [];
  if (Assigned(pKeywordValue)) and (pKeywordValue is TJSONArray) then
  begin
    lArr := TJSONArray(pKeywordValue);
    SetLength(lSchemas, lArr.Count);
    lIndex := 0;
    while lIndex < lArr.Count do
    begin
      lSchemas[lIndex] := pCompileFunc(lArr.Items[lIndex]);
      Inc(lIndex);
    end;
  end;
  Result := TPrefixItemsKeyword.Create(lSchemas);
end;

constructor TPrefixItemsKeyword.Create(const pSchemas: TArray<ICompiledSchema>);
begin
  inherited Create;
  FSchemas := pSchemas;
end;

function TPrefixItemsKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_PREFIXITEMS;
end;

function TPrefixItemsKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lArray: TJSONArray;
  lResults: TArray<IValidationResult>;
  lIndex: Integer;
begin
  if not pInstance.IsJSONArray then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lArray := TJSONArray(pInstance);
  lResults := [];

  lIndex := 0;
  while (lIndex < lArray.Count) and (lIndex < Length(FSchemas)) do
  begin
    TValidationContext.MarkItemEvaluated(pInstance, lIndex);
    if Assigned(FSchemas[lIndex]) then
      lResults := lResults + [FSchemas[lIndex].Validate(lArray.Items[lIndex])];
    Inc(lIndex);
  end;

  Result := TValidationResult.Combined(lResults);
end;

end.
