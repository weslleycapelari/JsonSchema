unit JsonSchema.Keywords.AnyOf;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'anyOf' logical keyword.
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
  /// <summary>Validates that the JSON instance conforms to at least one of the specified sub-schemas.</summary>
  TAnyOfKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FSubSchemas: TArray<ICompiledSchema>;
    function GetKeywordName: string;
  public
    /// <summary>Initializes anyOf keyword with an array of compiled schemas.</summary>
    constructor Create(const pSubSchemas: TArray<ICompiledSchema>);

    /// <summary>Validates the JSON instance against the sub-schemas.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('anyOf').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

{ TAnyOfKeyword }

constructor TAnyOfKeyword.Create(const pSubSchemas: TArray<ICompiledSchema>);
begin
  inherited Create;
  FSubSchemas := pSubSchemas;
end;

class function TAnyOfKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
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
  Result := TAnyOfKeyword.Create(lSubSchemas);
end;

function TAnyOfKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_ANYOF;
end;

function TAnyOfKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lResults: TArray<IValidationResult>;
  lIdx: Integer;
  lAnyValid: Boolean;
  lSubRes: IValidationResult;
begin
  if Length(FSubSchemas) = 0 then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lResults := [];
  lIdx := 0;
  lAnyValid := False;

  while (not lAnyValid) and (lIdx < Length(FSubSchemas)) do
  begin
    lSubRes := FSubSchemas[lIdx].Validate(pInstance);
    if lSubRes.IsValid then
    begin
      lAnyValid := True;
    end else
    begin
      lResults := lResults + [lSubRes];
    end;
    Inc(lIdx);
  end;

  if lAnyValid then
  begin
    Result := TValidationResult.ValidResult;
  end else
  begin
    Result := TValidationResult.Combined(lResults + [TValidationResult.InvalidResult(GetKeywordName)]);
  end;
end;

end.
