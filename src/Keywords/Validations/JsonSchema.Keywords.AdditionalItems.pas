unit JsonSchema.Keywords.AdditionalItems;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'additionalItems' keyword.
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
  /// <summary>Validates array items beyond the tuple length defined by a sibling 'items' array schema.</summary>
  TAdditionalItemsKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FIsTuple: Boolean;
    FTupleCount: Integer;
    FAdditionalSchema: ICompiledSchema;
    function GetKeywordName: string;
  public
    /// <summary>Initializes additionalItems keyword by inspecting the sibling 'items' schema and compiling the sub-schema.</summary>
    constructor Create(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject; const pCompileFunc: TCompileSchemaFunc);

    /// <summary>Validates additional elements in the JSON array instance.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('additionalItems').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

uses
  JsonSchema.JSONHelper,
  JsonSchema.Core.ValidationContext;

{ TAdditionalItemsKeyword }

class function TAdditionalItemsKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TAdditionalItemsKeyword.Create(pKeywordValue, pParentSchema, pCompileFunc);
end;

constructor TAdditionalItemsKeyword.Create(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc);
var
  lItemsVal: TJSONValue;
begin
  inherited Create;
  FIsTuple := False;
  FTupleCount := 0;
  FAdditionalSchema := nil;

  // 1. Inspect sibling 'items'
  if Assigned(pParentSchema) then
  begin
    if pParentSchema.TryGetValue('items', lItemsVal) then
    begin
      if lItemsVal is TJSONArray then
      begin
        FIsTuple := True;
        FTupleCount := TJSONArray(lItemsVal).Count;
      end;
    end;
  end;

  // 2. Compile additionalItems schema (if items is indeed a tuple)
  if FIsTuple and Assigned(pKeywordValue) then
  begin
    FAdditionalSchema := pCompileFunc(pKeywordValue);
  end;
end;

function TAdditionalItemsKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_ADDITIONALITEMS;
end;

function TAdditionalItemsKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
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

  // If items is not a tuple, additionalItems is ignored
  if not FIsTuple then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lArray := TJSONArray(pInstance);
  lResults := [];

  // Validate additional elements starting from FTupleCount
  if lArray.Count > FTupleCount then
  begin
    lIndex := FTupleCount;
    while lIndex < lArray.Count do
    begin
      TValidationContext.MarkItemEvaluated(pInstance, lIndex);
      if Assigned(FAdditionalSchema) then
      begin
        lResults := lResults + [FAdditionalSchema.Validate(lArray.Items[lIndex])];
      end;
      Inc(lIndex);
    end;
  end;

  Result := TValidationResult.Combined(lResults);
end;

end.
