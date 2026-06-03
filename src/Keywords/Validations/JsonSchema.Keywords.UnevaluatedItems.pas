unit JsonSchema.Keywords.UnevaluatedItems;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'unevaluatedItems' keyword.
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
  /// <summary>Validates any array elements that are not matched by other keywords in this validation run.</summary>
  TUnevaluatedItemsKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FSchema: ICompiledSchema;
    function GetKeywordName: string;
  public
    /// <summary>Initializes unevaluatedItems keyword with the compiled schema.</summary>
    constructor Create(const pSchema: ICompiledSchema);

    /// <summary>Validates unevaluated elements of the JSON array instance.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('unevaluatedItems').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

uses
  JsonSchema.JSONHelper,
  JsonSchema.Core.ValidationContext;

{ TUnevaluatedItemsKeyword }

class function TUnevaluatedItemsKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TUnevaluatedItemsKeyword.Create(pCompileFunc(pKeywordValue));
end;

constructor TUnevaluatedItemsKeyword.Create(const pSchema: ICompiledSchema);
begin
  inherited Create;
  FSchema := pSchema;
end;

function TUnevaluatedItemsKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_UNEVALUATEDITEMS;
end;

function TUnevaluatedItemsKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lArray: TJSONArray;
  lIndex: Integer;
  lResults: TArray<IValidationResult>;
begin
  if not pInstance.IsJSONArray then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lArray := TJSONArray(pInstance);
  lResults := [];

  lIndex := 0;
  while lIndex < lArray.Count do
  begin
    if not TValidationContext.IsItemEvaluated(pInstance, lIndex) then
    begin
      TValidationContext.MarkItemEvaluated(pInstance, lIndex);

      if Assigned(FSchema) then
      begin
        lResults := lResults + [FSchema.Validate(lArray.Items[lIndex])];
      end;
    end;
    Inc(lIndex);
  end;

  Result := TValidationResult.Combined(lResults);
end;

end.
