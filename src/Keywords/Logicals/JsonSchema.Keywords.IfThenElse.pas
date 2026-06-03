unit JsonSchema.Keywords.IfThenElse;

(*
--------------------------------------------------------------------------------
Implements validation logic for the conditional keywords 'if', 'then', and 'else'.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  System.SysUtils,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Results;

type
  /// <summary>Conditional validator evaluating if-then-else applicator schemas.</summary>
  TIfThenElseKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FIfSchema: ICompiledSchema;
    FThenSchema: ICompiledSchema;
    FElseSchema: ICompiledSchema;
    function GetKeywordName: string;
  public
    /// <summary>Initializes conditional keyword with subschemas.</summary>
    constructor Create(const pIfSchema, pThenSchema, pElseSchema: ICompiledSchema);

    /// <summary>Performs conditional validation of the instance.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Factory method to create the conditional keyword.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword ('if').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

{ TIfThenElseKeyword }

constructor TIfThenElseKeyword.Create(const pIfSchema, pThenSchema, pElseSchema: ICompiledSchema);
begin
  inherited Create;
  FIfSchema := pIfSchema;
  FThenSchema := pThenSchema;
  FElseSchema := pElseSchema;
end;

class function TIfThenElseKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
var
  lIfSchema: ICompiledSchema;
  lThenSchema: ICompiledSchema;
  lElseSchema: ICompiledSchema;
  lThenVal: TJSONValue;
  lElseVal: TJSONValue;
begin
  Result := nil;
  if not Assigned(pKeywordValue) then
    Exit;

  lIfSchema := pCompileFunc(pKeywordValue);
  lThenSchema := nil;
  lElseSchema := nil;

  if Assigned(pParentSchema) then
  begin
    if pParentSchema.TryGetValue('then', lThenVal) then
      lThenSchema := pCompileFunc(lThenVal);

    if pParentSchema.TryGetValue('else', lElseVal) then
      lElseSchema := pCompileFunc(lElseVal);
  end;

  Result := TIfThenElseKeyword.Create(lIfSchema, lThenSchema, lElseSchema);
end;

function TIfThenElseKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_IF;
end;

function TIfThenElseKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lIfResult: IValidationResult;
begin
  if not Assigned(FIfSchema) then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lIfResult := FIfSchema.Validate(pInstance);
  if lIfResult.IsValid then
  begin
    if Assigned(FThenSchema) then
      Result := FThenSchema.Validate(pInstance)
    else
      Result := TValidationResult.ValidResult;
  end else
  begin
    if Assigned(FElseSchema) then
      Result := FElseSchema.Validate(pInstance)
    else
      Result := TValidationResult.ValidResult;
  end;
end;

end.
