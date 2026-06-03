unit JsonSchema.Keywords.Dependencies;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'dependencies' keyword.
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
  /// <summary>Represents a single dependency rule (either a property or a schema dependency).</summary>
  TDependencyType = (dtProperty, dtSchema);

  TDependencyRule = record
    TriggerProperty: string;
    RuleType: TDependencyType;
    RequiredProperties: TArray<string>; // Used when RuleType = dtProperty
    Schema: ICompiledSchema;            // Used when RuleType = dtSchema
  end;

  /// <summary>Validates property or schema dependencies of an object instance.</summary>
  TDependenciesKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FRules: TArray<TDependencyRule>;
    function GetKeywordName: string;
  public
    /// <summary>Initializes dependencies keyword by parsing and compiling dependency rules.</summary>
    constructor Create(const pKeywordValue: TJSONValue; const pCompileFunc: TCompileSchemaFunc);

    /// <summary>Validates dependencies of the JSON object instance.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('dependencies').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TDependenciesKeyword }

class function TDependenciesKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TDependenciesKeyword.Create(pKeywordValue, pCompileFunc);
end;

constructor TDependenciesKeyword.Create(const pKeywordValue: TJSONValue; const pCompileFunc: TCompileSchemaFunc);
var
  lObj: TJSONObject;
  lPair: TJSONPair;
  lRule: TDependencyRule;
  lArr: TJSONArray;
  lIdx: Integer;
begin
  inherited Create;
  FRules := [];

  if (Assigned(pKeywordValue)) and (pKeywordValue is TJSONObject) then
  begin
    lObj := TJSONObject(pKeywordValue);
    for lPair in lObj do
    begin
      lRule.TriggerProperty := lPair.JsonString.Value;
      lRule.RequiredProperties := [];
      lRule.Schema := nil;

      if lPair.JsonValue is TJSONArray then
      begin
        lRule.RuleType := TDependencyType.dtProperty;
        lArr := TJSONArray(lPair.JsonValue);
        lIdx := 0;
        while lIdx < lArr.Count do
        begin
          SetLength(lRule.RequiredProperties, Length(lRule.RequiredProperties) + 1);
          lRule.RequiredProperties[High(lRule.RequiredProperties)] := lArr.Items[lIdx].Value;
          Inc(lIdx);
        end;
      end else
      begin
        lRule.RuleType := TDependencyType.dtSchema;
        lRule.Schema := pCompileFunc(lPair.JsonValue);
      end;

      SetLength(FRules, Length(FRules) + 1);
      FRules[High(FRules)] := lRule;
    end;
  end;
end;

function TDependenciesKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_DEPENDENCIES;
end;

function TDependenciesKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lObj: TJSONObject;
  lResults: TArray<IValidationResult>;
  lRuleIdx: Integer;
  lPropIdx: Integer;
  lRule: TDependencyRule;
  lCtx: TJSONObject;
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

    // Trigger only if the trigger property name is present in the instance
    if lObj.TryGetValue(lRule.TriggerProperty, lCtx) then
    begin
      if lRule.RuleType = TDependencyType.dtProperty then
      begin
        lPropIdx := 0;
        while lPropIdx < Length(lRule.RequiredProperties) do
        begin
          // If the required property is missing, fail validation
          if not lObj.TryGetValue(lRule.RequiredProperties[lPropIdx], lCtx) then
          begin
            lCtx := TJSONObject.Create;
            try
              lCtx.AddPair('trigger', TJSONString.Create(lRule.TriggerProperty));
              lCtx.AddPair('missing', TJSONString.Create(lRule.RequiredProperties[lPropIdx]));
              lResults := lResults + [TValidationResult.InvalidResult(GetKeywordName, lCtx)];
            finally
              lCtx.Free;
            end;
          end;
          Inc(lPropIdx);
        end;
      end else
      begin
        // Schema dependency: validate the entire instance against the compiled schema
        if Assigned(lRule.Schema) then
        begin
          lResults := lResults + [lRule.Schema.Validate(pInstance)];
        end;
      end;
    end;

    Inc(lRuleIdx);
  end;

  Result := TValidationResult.Combined(lResults);
end;

end.
