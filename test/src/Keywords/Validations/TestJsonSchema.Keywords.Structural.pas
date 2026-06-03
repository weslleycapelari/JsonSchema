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
