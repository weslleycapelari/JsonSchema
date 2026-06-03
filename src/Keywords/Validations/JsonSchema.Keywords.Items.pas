unit JsonSchema.Keywords.Items;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'items' keyword.
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
  /// <summary>Validates array elements against one or more sub-schemas.</summary>
  TItemsKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FSingleSchema: ICompiledSchema;
    FTupleSchemas: TArray<ICompiledSchema>;
    FIsTuple: Boolean;
    FPrefixCount: Integer;
    function GetKeywordName: string;
  public
    /// <summary>Initializes items keyword by compiling either a single schema or a tuple of schemas.</summary>
    constructor Create(const pKeywordValue: TJSONValue; const pCompileFunc: TCompileSchemaFunc); overload;

    /// <summary>Initializes items keyword with prefix count offset for Draft 2020-12.</summary>
    constructor CreateDraft2020_12(const pKeywordValue: TJSONValue; const pPrefixCount: Integer;
      const pCompileFunc: TCompileSchemaFunc); overload;

    /// <summary>Validates elements of the JSON array instance.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Creates Draft 2020-12 items keyword with prefix items offset.</summary>
    class function CreateKeywordDraft2020_12(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('items').</summary>
    property KeywordName: string read GetKeywordName;

    /// <summary>Returns true if items keyword is configured as a tuple (array of schemas).</summary>
    property IsTuple: Boolean read FIsTuple;

    /// <summary>Returns the count of schemas in the tuple (if IsTuple is true).</summary>
    function GetTupleCount: Integer;
  end;

implementation

uses
  JsonSchema.JSONHelper,
  JsonSchema.Core.ValidationContext;

{ TItemsKeyword }

class function TItemsKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TItemsKeyword.Create(pKeywordValue, pCompileFunc);
end;

class function TItemsKeyword.CreateKeywordDraft2020_12(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
var
  lPrefixCount: Integer;
  lPrefixVal: TJSONValue;
begin
  lPrefixCount := 0;
  if Assigned(pParentSchema) then
  begin
    lPrefixVal := pParentSchema.Values['prefixItems'];
    if Assigned(lPrefixVal) and (lPrefixVal is TJSONArray) then
      lPrefixCount := TJSONArray(lPrefixVal).Count;
  end;
  Result := TItemsKeyword.CreateDraft2020_12(pKeywordValue, lPrefixCount, pCompileFunc);
end;

constructor TItemsKeyword.Create(const pKeywordValue: TJSONValue; const pCompileFunc: TCompileSchemaFunc);
var
  lArr: TJSONArray;
  lIndex: Integer;
begin
  inherited Create;
  FIsTuple := False;
  FPrefixCount := 0;
  FSingleSchema := nil;
  FTupleSchemas := [];

  if not Assigned(pKeywordValue) then
  begin
    Exit;
  end;

  if pKeywordValue is TJSONArray then
  begin
    FIsTuple := True;
    lArr := TJSONArray(pKeywordValue);
    lIndex := 0;
    while lIndex < lArr.Count do
    begin
      SetLength(FTupleSchemas, Length(FTupleSchemas) + 1);
      FTupleSchemas[High(FTupleSchemas)] := pCompileFunc(lArr.Items[lIndex]);
      Inc(lIndex);
    end;
  end else
  begin
    FSingleSchema := pCompileFunc(pKeywordValue);
  end;
end;

constructor TItemsKeyword.CreateDraft2020_12(const pKeywordValue: TJSONValue; const pPrefixCount: Integer;
  const pCompileFunc: TCompileSchemaFunc);
begin
  inherited Create;
  FIsTuple := False;
  FPrefixCount := pPrefixCount;
  FTupleSchemas := [];
  if Assigned(pKeywordValue) then
    FSingleSchema := pCompileFunc(pKeywordValue)
  else
    FSingleSchema := nil;
end;

function TItemsKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_ITEMS;
end;

function TItemsKeyword.GetTupleCount: Integer;
begin
  if FIsTuple then
    Result := Length(FTupleSchemas)
  else
    Result := 0;
end;

function TItemsKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
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

  if FIsTuple then
  begin
    lIndex := 0;
    // For tuple validation, only validate up to the size of the tuple or array, whichever is smaller.
    // Sibling additionalItems keyword will handle items beyond the tuple length.
    while (lIndex < lArray.Count) and (lIndex < Length(FTupleSchemas)) do
    begin
      TValidationContext.MarkItemEvaluated(pInstance, lIndex);
      lResults := lResults + [FTupleSchemas[lIndex].Validate(lArray.Items[lIndex])];
      Inc(lIndex);
    end;
  end else
  begin
    if Assigned(FSingleSchema) then
    begin
      lIndex := FPrefixCount;
      while lIndex < lArray.Count do
      begin
        TValidationContext.MarkItemEvaluated(pInstance, lIndex);
        lResults := lResults + [FSingleSchema.Validate(lArray.Items[lIndex])];
        Inc(lIndex);
      end;
    end;
  end;

  Result := TValidationResult.Combined(lResults);
end;

end.
