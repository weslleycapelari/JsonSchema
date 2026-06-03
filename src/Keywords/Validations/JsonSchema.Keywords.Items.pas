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
    function GetKeywordName: string;
  public
    /// <summary>Initializes items keyword by compiling either a single schema or a tuple of schemas.</summary>
    constructor Create(const pKeywordValue: TJSONValue; const pCompileFunc: TCompileSchemaFunc);

    /// <summary>Validates elements of the JSON array instance.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
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
  JsonSchema.JSONHelper;

{ TItemsKeyword }

class function TItemsKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TItemsKeyword.Create(pKeywordValue, pCompileFunc);
end;

constructor TItemsKeyword.Create(const pKeywordValue: TJSONValue; const pCompileFunc: TCompileSchemaFunc);
var
  lArr: TJSONArray;
  lIndex: Integer;
begin
  inherited Create;
  FIsTuple := False;
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
      lResults := lResults + [FTupleSchemas[lIndex].Validate(lArray.Items[lIndex])];
      Inc(lIndex);
    end;
  end else
  begin
    if Assigned(FSingleSchema) then
    begin
      lIndex := 0;
      while lIndex < lArray.Count do
      begin
        lResults := lResults + [FSingleSchema.Validate(lArray.Items[lIndex])];
        Inc(lIndex);
      end;
    end;
  end;

  Result := TValidationResult.Combined(lResults);
end;

end.
