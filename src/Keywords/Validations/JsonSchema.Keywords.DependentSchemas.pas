unit JsonSchema.Keywords.DependentSchemas;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'dependentSchemas' keyword.
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
  TDependentSchemaRule = record
    TriggerProperty: string;
    Schema: ICompiledSchema;
  end;

  /// <summary>Validates schema dependencies of an object instance.</summary>
  TDependentSchemasKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FRules: TArray<TDependentSchemaRule>;
    function GetKeywordName: string;
  public
    /// <summary>Initializes dependentSchemas keyword by compiling rules.</summary>
    constructor Create(const pKeywordValue: TJSONValue; const pCompileFunc: TCompileSchemaFunc);

    /// <summary>Validates schema dependencies of the JSON object instance.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('dependentSchemas').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TDependentSchemasKeyword }

class function TDependentSchemasKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TDependentSchemasKeyword.Create(pKeywordValue, pCompileFunc);
end;

constructor TDependentSchemasKeyword.Create(const pKeywordValue: TJSONValue; const pCompileFunc: TCompileSchemaFunc);
var
  lObj: TJSONObject;
  lPair: TJSONPair;
  lRule: TDependentSchemaRule;
begin
  inherited Create;
  FRules := [];

  if (Assigned(pKeywordValue)) and (pKeywordValue is TJSONObject) then
  begin
    lObj := TJSONObject(pKeywordValue);
    for lPair in lObj do
    begin
      lRule.TriggerProperty := lPair.JsonString.Value;
      lRule.Schema := pCompileFunc(lPair.JsonValue);

      SetLength(FRules, Length(FRules) + 1);
      FRules[High(FRules)] := lRule;
    end;
  end;
end;

function TDependentSchemasKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_DEPENDENTSCHEMAS;
end;

function TDependentSchemasKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lObj: TJSONObject;
  lResults: TArray<IValidationResult>;
  lRuleIdx: Integer;
  lRule: TDependentSchemaRule;
  lPropertyValue: TJSONValue;
begin
  if not pInstance.IsJSONObject then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lObj := TJSONObject(pInstance);
  lResults := [];

  lRuleIdx := 0;
  while lRuleIdx < Length(FRules) do
  begin
    lRule := FRules[lRuleIdx];
    if lObj.TryGetValue<TJSONValue>(lRule.TriggerProperty, lPropertyValue) then
    begin
      if Assigned(lRule.Schema) then
      begin
        lResults := lResults + [lRule.Schema.Validate(pInstance)];
      end;
    end;
    Inc(lRuleIdx);
  end;

  Result := TValidationResult.Combined(lResults);
end;

end.
