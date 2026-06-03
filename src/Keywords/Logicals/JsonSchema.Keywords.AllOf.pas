unit JsonSchema.Keywords.AllOf;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'allOf' logical keyword.
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
  /// <summary>Validates that the JSON instance conforms to all specified sub-schemas.</summary>
  TAllOfKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FSubSchemas: TArray<ICompiledSchema>;
    function GetKeywordName: string;
  public
    /// <summary>Initializes allOf keyword with an array of compiled schemas.</summary>
    constructor Create(const pSubSchemas: TArray<ICompiledSchema>);

    /// <summary>Validates the JSON instance against all sub-schemas.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('allOf').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

{ TAllOfKeyword }

constructor TAllOfKeyword.Create(const pSubSchemas: TArray<ICompiledSchema>);
begin
  inherited Create;
  FSubSchemas := pSubSchemas;
end;

class function TAllOfKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
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
  Result := TAllOfKeyword.Create(lSubSchemas);
end;

function TAllOfKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_ALLOF;
end;

function TAllOfKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lResults: TArray<IValidationResult>;
  lIdx: Integer;
begin
  if Length(FSubSchemas) = 0 then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lResults := [];
  lIdx := 0;
  while lIdx < Length(FSubSchemas) do
  begin
    lResults := lResults + [FSubSchemas[lIdx].Validate(pInstance)];
    Inc(lIdx);
  end;

  Result := TValidationResult.Combined(lResults);
end;

end.
