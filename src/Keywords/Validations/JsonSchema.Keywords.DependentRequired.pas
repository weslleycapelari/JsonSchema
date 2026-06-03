unit JsonSchema.Keywords.DependentRequired;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'dependentRequired' keyword.
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
  TDependentRequiredRule = record
    TriggerProperty: string;
    RequiredProperties: TArray<string>;
  end;

  /// <summary>Validates property dependencies of an object instance.</summary>
  TDependentRequiredKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FRules: TArray<TDependentRequiredRule>;
    function GetKeywordName: string;
  public
    /// <summary>Initializes dependentRequired keyword by parsing rules.</summary>
    constructor Create(const pKeywordValue: TJSONValue);

    /// <summary>Validates property dependencies of the JSON object instance.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('dependentRequired').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TDependentRequiredKeyword }

class function TDependentRequiredKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TDependentRequiredKeyword.Create(pKeywordValue);
end;

constructor TDependentRequiredKeyword.Create(const pKeywordValue: TJSONValue);
var
  lObj: TJSONObject;
  lPair: TJSONPair;
  lRule: TDependentRequiredRule;
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
      if lPair.JsonValue is TJSONArray then
      begin
        lRule.TriggerProperty := lPair.JsonString.Value;
        lRule.RequiredProperties := [];
        lArr := TJSONArray(lPair.JsonValue);
        lIdx := 0;
        while lIdx < lArr.Count do
        begin
          SetLength(lRule.RequiredProperties, Length(lRule.RequiredProperties) + 1);
          lRule.RequiredProperties[High(lRule.RequiredProperties)] := lArr.Items[lIdx].Value;
          Inc(lIdx);
        end;

        SetLength(FRules, Length(FRules) + 1);
        FRules[High(FRules)] := lRule;
      end;
    end;
  end;
end;

function TDependentRequiredKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_DEPENDENTREQUIRED;
end;

function TDependentRequiredKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lObj: TJSONObject;
  lResults: TArray<IValidationResult>;
  lRuleIdx: Integer;
  lPropIdx: Integer;
  lRule: TDependentRequiredRule;
  lCtx: TJSONObject;
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
      lPropIdx := 0;
      while lPropIdx < Length(lRule.RequiredProperties) do
      begin
        if not lObj.TryGetValue<TJSONValue>(lRule.RequiredProperties[lPropIdx], lPropertyValue) then
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
    end;
    Inc(lRuleIdx);
  end;

  Result := TValidationResult.Combined(lResults);
end;

end.
