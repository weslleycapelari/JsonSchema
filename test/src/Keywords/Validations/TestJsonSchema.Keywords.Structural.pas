unit TestJsonSchema.Keywords.Structural;

(*
--------------------------------------------------------------------------------
Unit tests for 'properties', 'patternProperties', and 'items'.
--------------------------------------------------------------------------------
*)

interface

uses
  TestFramework,
  System.JSON,
  System.SysUtils,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Keywords.Properties,
  JsonSchema.Keywords.PatternProperties,
  JsonSchema.Keywords.AdditionalProperties,
  JsonSchema.Keywords.Dependencies,
  JsonSchema.Keywords.Items,
  JsonSchema.Draft6.Parser,
  JsonSchema.Results;

type
  TTestStructuralKeywords = class(TTestCase)
  published
    procedure TestPropertiesPasses;
    procedure TestPropertiesFails;
    procedure TestPropertiesIgnoredOnNonObjects;
    procedure TestPatternPropertiesPasses;
    procedure TestPatternPropertiesFails;
    procedure TestPatternPropertiesIgnoredOnNonObjects;
    procedure TestPatternPropertiesSupportsUnicodeClassAliases;
    procedure TestAdditionalPropertiesUsesNormalizedPatternProperties;
    procedure TestPatternPropertiesPreservesAsciiWordClass;
    procedure TestPatternPropertiesPreservesAsciiDigitClass;
    procedure TestDependenciesRequireSiblingProperties;
    procedure TestDependenciesValidateSchemaDependencies;
    procedure TestDependenciesSupportEscapedPropertyNames;
    procedure TestItemsSinglePasses;
    procedure TestItemsSingleFails;
    procedure TestItemsTuplePasses;
    procedure TestItemsTupleFails;
    procedure TestItemsIgnoredOnNonArrays;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TTestStructuralKeywords }

procedure TTestStructuralKeywords.TestPropertiesPasses;
var
  lInstance: TJSONValue;
  lKeywordValue: TJSONObject;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lKeywordValue := TJSONObject.ParseJSONValue('{"foo": {"type": "string"}, "bar": {"type": "number"}}') as TJSONObject;
  try
    lKeyword := TPropertiesKeyword.Create(lKeywordValue, TDraft6Parser.ParseSchema);
    lInstance := TJSONObject.ParseJSONValue('{"foo": "abc", "bar": 123, "baz": true}') as TJSONObject;
    try
      lResult := lKeyword.Validate(lInstance);
      CheckTrue(lResult.IsValid, 'Properties validation should pass');
    finally
      lInstance.Free;
    end;
  finally
    lKeywordValue.Free;
  end;
end;

procedure TTestStructuralKeywords.TestPropertiesFails;
var
  lInstance: TJSONValue;
  lKeywordValue: TJSONObject;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lKeywordValue := TJSONObject.ParseJSONValue('{"foo": {"type": "string"}, "bar": {"type": "number"}}') as TJSONObject;
  try
    lKeyword := TPropertiesKeyword.Create(lKeywordValue, TDraft6Parser.ParseSchema);
    lInstance := TJSONObject.ParseJSONValue('{"foo": 123, "bar": 123}') as TJSONObject;
    try
      lResult := lKeyword.Validate(lInstance);
      CheckFalse(lResult.IsValid, 'Properties validation should fail because "foo" is not a string');
    finally
      lInstance.Free;
    end;
  finally
    lKeywordValue.Free;
  end;
end;

procedure TTestStructuralKeywords.TestPropertiesIgnoredOnNonObjects;
var
  lInstance: TJSONValue;
  lKeywordValue: TJSONObject;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lKeywordValue := TJSONObject.ParseJSONValue('{"foo": {"type": "string"}}') as TJSONObject;
  try
    lKeyword := TPropertiesKeyword.Create(lKeywordValue, TDraft6Parser.ParseSchema);
    lInstance := TJSONString.Create('abc');
    try
      lResult := lKeyword.Validate(lInstance);
      CheckTrue(lResult.IsValid, 'Properties validation should be ignored on strings');
    finally
      lInstance.Free;
    end;
  finally
    lKeywordValue.Free;
  end;
end;

procedure TTestStructuralKeywords.TestPatternPropertiesPasses;
var
  lInstance: TJSONValue;
  lKeywordValue: TJSONObject;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lKeywordValue := TJSONObject.ParseJSONValue('{"^f": {"type": "string"}}') as TJSONObject;
  try
    lKeyword := TPatternPropertiesKeyword.Create(lKeywordValue, TDraft6Parser.ParseSchema);
    lInstance := TJSONObject.ParseJSONValue('{"foo": "abc", "bar": 123}') as TJSONObject;
    try
      lResult := lKeyword.Validate(lInstance);
      CheckTrue(lResult.IsValid, 'Pattern properties validation should pass');
    finally
      lInstance.Free;
    end;
  finally
    lKeywordValue.Free;
  end;
end;

procedure TTestStructuralKeywords.TestPatternPropertiesFails;
var
  lInstance: TJSONValue;
  lKeywordValue: TJSONObject;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lKeywordValue := TJSONObject.ParseJSONValue('{"^f": {"type": "string"}}') as TJSONObject;
  try
    lKeyword := TPatternPropertiesKeyword.Create(lKeywordValue, TDraft6Parser.ParseSchema);
    lInstance := TJSONObject.ParseJSONValue('{"foo": 123, "bar": 123}') as TJSONObject;
    try
      lResult := lKeyword.Validate(lInstance);
      CheckFalse(lResult.IsValid, 'Pattern properties validation should fail because "foo" starts with "f" and is not a string');
    finally
      lInstance.Free;
    end;
  finally
    lKeywordValue.Free;
  end;
end;

procedure TTestStructuralKeywords.TestPatternPropertiesIgnoredOnNonObjects;
var
  lInstance: TJSONValue;
  lKeywordValue: TJSONObject;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lKeywordValue := TJSONObject.ParseJSONValue('{"^f": {"type": "string"}}') as TJSONObject;
  try
    lKeyword := TPatternPropertiesKeyword.Create(lKeywordValue, TDraft6Parser.ParseSchema);
    lInstance := TJSONString.Create('abc');
    try
      lResult := lKeyword.Validate(lInstance);
      CheckTrue(lResult.IsValid, 'Pattern properties validation should be ignored on strings');
    finally
      lInstance.Free;
    end;
  finally
    lKeywordValue.Free;
  end;
end;

procedure TTestStructuralKeywords.TestPatternPropertiesSupportsUnicodeClassAliases;
var
  lInstance: TJSONObject;
  lKeywordValue: TJSONObject;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
  lUnicodeKey: string;
begin
  lKeywordValue := TJSONObject.ParseJSONValue('{"\\p{Letter}cole": {"type": "string"}}') as TJSONObject;
  try
    lKeyword := TPatternPropertiesKeyword.Create(lKeywordValue, TDraft6Parser.ParseSchema);

    lUnicodeKey := 'l''' + #$00E9 + 'cole';
    lInstance := TJSONObject.Create;
    try
      lInstance.AddPair(lUnicodeKey, TJSONString.Create('pas de vraie vie'));

      lResult := lKeyword.Validate(lInstance);
      CheckTrue(lResult.IsValid, 'patternProperties should support \\p{Letter} aliases and match unicode keys');
    finally
      lInstance.Free;
    end;
  finally
    lKeywordValue.Free;
  end;
end;

procedure TTestStructuralKeywords.TestAdditionalPropertiesUsesNormalizedPatternProperties;
var
  lInstance: TJSONObject;
  lParentSchema: TJSONObject;
  lAdditionalValue: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
  lUnicodeDigitKey: string;
begin
  lParentSchema := TJSONObject.ParseJSONValue(
    '{"patternProperties": {"^\\p{digit}+$": true}, "additionalProperties": false}') as TJSONObject;
  try
    lAdditionalValue := lParentSchema.GetValue('additionalProperties');
    lKeyword := TAdditionalPropertiesKeyword.Create(lAdditionalValue, lParentSchema, TDraft6Parser.ParseSchema);

    lUnicodeDigitKey := #$09EA + #$09E8;
    lInstance := TJSONObject.Create;
    try
      lInstance.AddPair(lUnicodeDigitKey, TJSONString.Create('khajit has wares if you have coin'));

      lResult := lKeyword.Validate(lInstance);
      CheckTrue(lResult.IsValid, 'additionalProperties should respect unicode aliases from sibling patternProperties');
    finally
      lInstance.Free;
    end;
  finally
    lParentSchema.Free;
  end;
end;

procedure TTestStructuralKeywords.TestPatternPropertiesPreservesAsciiWordClass;
var
  lSchema: TJSONObject;
  lInstance: TJSONObject;
  lCompiled: ICompiledSchema;
  lResult: IValidationResult;
  lUnicodeKey: string;
begin
  lSchema := TJSONObject.ParseJSONValue(
    '{"type":"object","patternProperties":{"\\wcole":true},"additionalProperties":false}') as TJSONObject;
  try
    lCompiled := TDraft6Parser.Parse(lSchema);
    lUnicodeKey := 'l''' + #$00E9 + 'cole';
    lInstance := TJSONObject.Create;
    try
      lInstance.AddPair(lUnicodeKey, TJSONString.Create('pas de vraie vie'));
      lResult := lCompiled.Validate(lInstance);
      CheckFalse(lResult.IsValid, '\\w in patternProperties must stay ASCII-only for unicode letters');
    finally
      lInstance.Free;
    end;
  finally
    lSchema.Free;
  end;
end;

procedure TTestStructuralKeywords.TestPatternPropertiesPreservesAsciiDigitClass;
var
  lSchema: TJSONObject;
  lInstance: TJSONObject;
  lCompiled: ICompiledSchema;
  lResult: IValidationResult;
begin
  lSchema := TJSONObject.ParseJSONValue(
    '{"type":"object","patternProperties":{"^\\d+$":true},"additionalProperties":false}') as TJSONObject;
  try
    lCompiled := TDraft6Parser.Parse(lSchema);
    lInstance := TJSONObject.Create;
    try
      lInstance.AddPair(#$09EA + #$09E8, TJSONString.Create('khajit has wares if you have coin'));
      lResult := lCompiled.Validate(lInstance);
      CheckFalse(lResult.IsValid, '\\d in patternProperties must stay ASCII-only for unicode digits');
    finally
      lInstance.Free;
    end;
  finally
    lSchema.Free;
  end;
end;

procedure TTestStructuralKeywords.TestDependenciesRequireSiblingProperties;
var
  lInstance: TJSONObject;
  lKeywordValue: TJSONObject;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lKeywordValue := TJSONObject.ParseJSONValue('{"quux":["foo","bar"]}') as TJSONObject;
  try
    lKeyword := TDependenciesKeyword.Create(lKeywordValue, TDraft6Parser.ParseSchema);
    lInstance := TJSONObject.ParseJSONValue('{"foo":1,"quux":2}') as TJSONObject;
    try
      lResult := lKeyword.Validate(lInstance);
      CheckFalse(lResult.IsValid, 'dependencies should fail when a sibling dependency property is missing');
    finally
      lInstance.Free;
    end;
  finally
    lKeywordValue.Free;
  end;
end;

procedure TTestStructuralKeywords.TestDependenciesValidateSchemaDependencies;
var
  lInstance: TJSONObject;
  lKeywordValue: TJSONObject;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lKeywordValue := TJSONObject.ParseJSONValue(
    '{"bar":{"properties":{"foo":{"type":"integer"},"bar":{"type":"integer"}}}}') as TJSONObject;
  try
    lKeyword := TDependenciesKeyword.Create(lKeywordValue, TDraft6Parser.ParseSchema);
    lInstance := TJSONObject.ParseJSONValue('{"foo":"quux","bar":2}') as TJSONObject;
    try
      lResult := lKeyword.Validate(lInstance);
      CheckFalse(lResult.IsValid, 'schema dependencies should validate the full instance when the trigger property exists');
    finally
      lInstance.Free;
    end;
  finally
    lKeywordValue.Free;
  end;
end;

procedure TTestStructuralKeywords.TestDependenciesSupportEscapedPropertyNames;
var
  lInstance: TJSONObject;
  lKeywordValue: TJSONObject;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lKeywordValue := TJSONObject.ParseJSONValue(
    '{"foo\nbar":["foo\rbar"],"foo\tbar":{"minProperties":4},"foo''bar":{"required":["foo\"bar"]},"foo\"bar":["foo''bar"]}') as TJSONObject;
  try
    lKeyword := TDependenciesKeyword.Create(lKeywordValue, TDraft6Parser.ParseSchema);
    lInstance := TJSONObject.ParseJSONValue('{"foo\nbar":1,"foo":2}') as TJSONObject;
    try
      lResult := lKeyword.Validate(lInstance);
      CheckFalse(lResult.IsValid, 'dependencies should honor escaped property names when checking triggers and missing properties');
    finally
      lInstance.Free;
    end;
  finally
    lKeywordValue.Free;
  end;
end;

procedure TTestStructuralKeywords.TestItemsSinglePasses;
var
  lInstance: TJSONValue;
  lKeywordValue: TJSONObject;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lKeywordValue := TJSONObject.ParseJSONValue('{"type": "number"}') as TJSONObject;
  try
    lKeyword := TItemsKeyword.Create(lKeywordValue, TDraft6Parser.ParseSchema);
    lInstance := TJSONObject.ParseJSONValue('[1, 2.5, 3]') as TJSONArray;
    try
      lResult := lKeyword.Validate(lInstance);
      CheckTrue(lResult.IsValid, 'Single items validation should pass');
    finally
      lInstance.Free;
    end;
  finally
    lKeywordValue.Free;
  end;
end;

procedure TTestStructuralKeywords.TestItemsSingleFails;
var
  lInstance: TJSONValue;
  lKeywordValue: TJSONObject;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lKeywordValue := TJSONObject.ParseJSONValue('{"type": "number"}') as TJSONObject;
  try
    lKeyword := TItemsKeyword.Create(lKeywordValue, TDraft6Parser.ParseSchema);
    lInstance := TJSONObject.ParseJSONValue('[1, "abc", 3]') as TJSONArray;
    try
      lResult := lKeyword.Validate(lInstance);
      CheckFalse(lResult.IsValid, 'Single items validation should fail because "abc" is not a number');
    finally
      lInstance.Free;
    end;
  finally
    lKeywordValue.Free;
  end;
end;

procedure TTestStructuralKeywords.TestItemsTuplePasses;
var
  lInstance: TJSONValue;
  lKeywordValue: TJSONArray;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lKeywordValue := TJSONObject.ParseJSONValue('[{"type": "number"}, {"type": "string"}]') as TJSONArray;
  try
    lKeyword := TItemsKeyword.Create(lKeywordValue, TDraft6Parser.ParseSchema);
    lInstance := TJSONObject.ParseJSONValue('[1, "abc", true]') as TJSONArray;
    try
      lResult := lKeyword.Validate(lInstance);
      CheckTrue(lResult.IsValid, 'Tuple items validation should pass (the third item "true" is ignored by items, handled by additionalItems)');
    finally
      lInstance.Free;
    end;
  finally
    lKeywordValue.Free;
  end;
end;

procedure TTestStructuralKeywords.TestItemsTupleFails;
var
  lInstance: TJSONValue;
  lKeywordValue: TJSONArray;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lKeywordValue := TJSONObject.ParseJSONValue('[{"type": "number"}, {"type": "string"}]') as TJSONArray;
  try
    lKeyword := TItemsKeyword.Create(lKeywordValue, TDraft6Parser.ParseSchema);
    lInstance := TJSONObject.ParseJSONValue('[1, 2, true]') as TJSONArray;
    try
      lResult := lKeyword.Validate(lInstance);
      CheckFalse(lResult.IsValid, 'Tuple items validation should fail because the second item "2" is not a string');
    finally
      lInstance.Free;
    end;
  finally
    lKeywordValue.Free;
  end;
end;

procedure TTestStructuralKeywords.TestItemsIgnoredOnNonArrays;
var
  lInstance: TJSONValue;
  lKeywordValue: TJSONObject;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lKeywordValue := TJSONObject.ParseJSONValue('{"type": "number"}') as TJSONObject;
  try
    lKeyword := TItemsKeyword.Create(lKeywordValue, TDraft6Parser.ParseSchema);
    lInstance := TJSONString.Create('abc');
    try
      lResult := lKeyword.Validate(lInstance);
      CheckTrue(lResult.IsValid, 'Items validation should be ignored on strings');
    finally
      lInstance.Free;
    end;
  finally
    lKeywordValue.Free;
  end;
end;

initialization
  RegisterTest(TTestStructuralKeywords.Suite);

end.
