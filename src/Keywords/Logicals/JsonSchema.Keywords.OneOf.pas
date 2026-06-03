unit JsonSchema.Keywords.OneOf;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'oneOf' logical keyword.
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
  /// <summary>Validates that the JSON instance conforms to exactly one of the specified sub-schemas.</summary>
  TOneOfKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FSubSchemas: TArray<ICompiledSchema>;
    function GetKeywordName: string;
  public
    /// <summary>Initializes oneOf keyword with an array of compiled schemas.</summary>
    constructor Create(const pSubSchemas: TArray<ICompiledSchema>);

    /// <summary>Validates the JSON instance against the sub-schemas.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('oneOf').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

{ TOneOfKeyword }

constructor TOneOfKeyword.Create(const pSubSchemas: TArray<ICompiledSchema>);
begin
  inherited Create;
  FSubSchemas := pSubSchemas;
end;

class function TOneOfKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
var
  lArr: TJSONArray;
  lSubSchemas: TArray<ICompiledSchema>;
  lIdx: Integer;
begin
  lSubSchemas := [];
  if (Assigned(pKeywordValue)) and (pKeywordValue is TJSONArray) then
  begin
    lArr := TJSONArray(pKeywordValue);
    lIdx := 0;
    while lIdx < lArr.Count do
    begin
      SetLength(lSubSchemas, Length(lSubSchemas) + 1);
      lSubSchemas[High(lSubSchemas)] := pCompileFunc(lArr.Items[lIdx]);
      Inc(lIdx);
    end;
  end;
  Result := TOneOfKeyword.Create(lSubSchemas);
end;

function TOneOfKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_ONEOF;
end;

function TOneOfKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lResults: TArray<IValidationResult>;
  lIdx: Integer;
  lValidCount: Integer;
  lSubRes: IValidationResult;
  lContext: TJSONObject;
begin
  if Length(FSubSchemas) = 0 then
  begin
    Result := TValidationResult.InvalidResult(GetKeywordName);
    Exit;
  end;

  lResults := [];
  lIdx := 0;
  lValidCount := 0;

  while lIdx < Length(FSubSchemas) do
  begin
    lSubRes := FSubSchemas[lIdx].Validate(pInstance);
    if lSubRes.IsValid then
    begin
      Inc(lValidCount);
    end else
    begin
      lResults := lResults + [lSubRes];
    end;
    Inc(lIdx);
  end;

  if lValidCount = 1 then
  begin
    Result := TValidationResult.ValidResult;
  end else
  begin
    lContext := TJSONObject.Create;
    try
      lContext.AddPair('limit', TJSONNumber.Create(1));
      lContext.AddPair('actual', TJSONNumber.Create(lValidCount));
      Result := TValidationResult.Combined(lResults + [TValidationResult.InvalidResult(GetKeywordName, lContext)]);
    finally
      lContext.Free;
    end;
  end;
end;

end.
