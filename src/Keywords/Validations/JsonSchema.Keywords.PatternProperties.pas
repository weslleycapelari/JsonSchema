unit JsonSchema.Keywords.PatternProperties;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'patternProperties' keyword.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  System.SysUtils,
  System.RegularExpressions,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Results;

type
  /// <summary>Represents a compiled pattern property rule.</summary>
  TPatternPropertyRule = record
    Pattern: string;
    Regex: TRegEx;
    Schema: ICompiledSchema;
  end;

  /// <summary>Validates object properties whose names match specified regex patterns against their sub-schemas.</summary>
  TPatternPropertiesKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FRules: TArray<TPatternPropertyRule>;
    function GetKeywordName: string;
  public
    /// <summary>Initializes patternProperties keyword by parsing and compiling regexes and sub-schemas.</summary>
    constructor Create(const pKeywordValue: TJSONValue; const pCompileFunc: TCompileSchemaFunc); overload;

    /// <summary>Initializes patternProperties keyword directly with precompiled rules.</summary>
    constructor Create(const pRules: TArray<TPatternPropertyRule>); overload;

    /// <summary>Validates properties of the JSON object instance matching regex patterns.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('patternProperties').</summary>
    property KeywordName: string read GetKeywordName;

    /// <summary>Exposes the compiled pattern property rules (for sibling keywords like additionalProperties).</summary>
    property Rules: TArray<TPatternPropertyRule> read FRules;
  end;

implementation

uses
  JsonSchema.Keywords.Pattern,
  JsonSchema.JSONHelper,
  JsonSchema.Core.ValidationContext;

{ TPatternPropertiesKeyword }

class function TPatternPropertiesKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TPatternPropertiesKeyword.Create(pKeywordValue, pCompileFunc);
end;

constructor TPatternPropertiesKeyword.Create(const pKeywordValue: TJSONValue; const pCompileFunc: TCompileSchemaFunc);
var
  lPair: TJSONPair;
  lObj: TJSONObject;
  lRule: TPatternPropertyRule;
begin
  inherited Create;
  FRules := [];
  if (Assigned(pKeywordValue)) and (pKeywordValue is TJSONObject) then
  begin
    lObj := TJSONObject(pKeywordValue);
    for lPair in lObj do
    begin
      lRule.Pattern := lPair.JsonString.Value;
      // Compile TRegEx once during construction for efficiency
      lRule.Regex := TRegEx.Create(TPatternKeyword.NormalizeEcma262Pattern(lRule.Pattern), [roCompiled]);
      lRule.Schema := pCompileFunc(lPair.JsonValue);

      SetLength(FRules, Length(FRules) + 1);
      FRules[High(FRules)] := lRule;
    end;
  end;
end;

constructor TPatternPropertiesKeyword.Create(const pRules: TArray<TPatternPropertyRule>);
begin
  inherited Create;
  FRules := pRules;
end;

function TPatternPropertiesKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_PATTERNPROPERTIES;
end;

function TPatternPropertiesKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lObj: TJSONObject;
  lPair: TJSONPair;
  lResults: TArray<IValidationResult>;
  lIndex: Integer;
  lKeyName: string;
begin
  if not pInstance.IsJSONObject then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lObj := TJSONObject(pInstance);
  lResults := [];

  for lPair in lObj do
  begin
    lKeyName := lPair.JsonString.Value;
    lIndex := 0;
    while lIndex < Length(FRules) do
    begin
      if FRules[lIndex].Regex.IsMatch(lKeyName) then
      begin
        TValidationContext.MarkPropertyEvaluated(pInstance, lKeyName);
        lResults := lResults + [FRules[lIndex].Schema.Validate(lPair.JsonValue)];
      end;
      Inc(lIndex);
    end;
  end;

  Result := TValidationResult.Combined(lResults);
end;

end.
