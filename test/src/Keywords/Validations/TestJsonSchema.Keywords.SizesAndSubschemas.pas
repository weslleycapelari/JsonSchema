unit TestJsonSchema.Keywords.SizesAndSubschemas;

(*
--------------------------------------------------------------------------------
Unit tests for 'contains', 'maxProperties', 'minProperties', and 'propertyNames'.
--------------------------------------------------------------------------------
*)

interface

uses
  TestFramework,
  System.JSON,
  System.SysUtils,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Keywords.Contains,
  JsonSchema.Keywords.MaxProperties,
  JsonSchema.Keywords.MinProperties,
  JsonSchema.Keywords.PropertyNames,
  JsonSchema.Draft6.Parser,
  JsonSchema.Results;

type
  TTestSizesAndSubschemasKeywords = class(TTestCase)
  published
    procedure TestContainsPasses;
    procedure TestContainsFails;
    procedure TestContainsIgnoredOnNonArrays;
    procedure TestMaxPropertiesPasses;
    procedure TestMaxPropertiesFails;
    procedure TestMaxPropertiesIgnoredOnNonObjects;
    procedure TestMinPropertiesPasses;
    procedure TestMinPropertiesFails;
    procedure TestMinPropertiesIgnoredOnNonObjects;
    procedure TestPropertyNamesPasses;
    procedure TestPropertyNamesFails;
    procedure TestPropertyNamesIgnoredOnNonObjects;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TTestSizesAndSubschemasKeywords }

procedure TTestSizesAndSubschemasKeywords.TestContainsPasses;
var
  lInstance: TJSONValue;
  lSubSchema: ICompiledSchema;
  lSubSchemaObj: TJSONObject;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lSubSchemaObj := TJSONObject.ParseJSONValue('{"type":"number"}') as TJSONObject;
  try
    lSubSchema := TDraft6Parser.Parse(lSubSchemaObj);
    lKeyword := TContainsKeyword.Create(lSubSchema);

    lInstance := TJSONObject.ParseJSONValue('["abc", 123, true]') as TJSONArray;
    try
      lResult := lKeyword.Validate(lInstance);
      CheckTrue(lResult.IsValid, 'Array with 123 should be valid since it contains a number');
    finally
      lInstance.Free;
    end;
  finally
    lSubSchemaObj.Free;
  end;
end;

procedure TTestSizesAndSubschemasKeywords.TestContainsFails;
var
  lInstance: TJSONValue;
  lSubSchema: ICompiledSchema;
  lSubSchemaObj: TJSONObject;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lSubSchemaObj := TJSONObject.ParseJSONValue('{"type":"number"}') as TJSONObject;
  try
    lSubSchema := TDraft6Parser.Parse(lSubSchemaObj);
    lKeyword := TContainsKeyword.Create(lSubSchema);

    lInstance := TJSONObject.ParseJSONValue('["abc", "def", true]') as TJSONArray;
    try
      lResult := lKeyword.Validate(lInstance);
      CheckFalse(lResult.IsValid, 'Array without any numbers should be invalid');
      CheckEquals(KEYWORD_CONTAINS, lResult.Errors[0].Keyword);
    finally
      lInstance.Free;
    end;
  finally
    lSubSchemaObj.Free;
  end;
end;

procedure TTestSizesAndSubschemasKeywords.TestContainsIgnoredOnNonArrays;
var
  lInstance: TJSONValue;
  lSubSchemaObj: TJSONObject;
  lSubSchema: ICompiledSchema;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lSubSchemaObj := TJSONObject.ParseJSONValue('{"type":"number"}') as TJSONObject;
  try
    lSubSchema := TDraft6Parser.Parse(lSubSchemaObj);
    lKeyword := TContainsKeyword.Create(lSubSchema);

    lInstance := TJSONString.Create('abc');
    try
      lResult := lKeyword.Validate(lInstance);
      CheckTrue(lResult.IsValid, 'Contains should be ignored on strings');
    finally
      lInstance.Free;
    end;
  finally
    lSubSchemaObj.Free;
  end;
end;

procedure TTestSizesAndSubschemasKeywords.TestMaxPropertiesPasses;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONObject.ParseJSONValue('{"a": 1, "b": 2}') as TJSONObject;
  try
    lKeyword := TMaxPropertiesKeyword.Create(2);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Object with 2 properties <= 2 limit should be valid');
  finally
    lInstance.Free;
  end;
end;

procedure TTestSizesAndSubschemasKeywords.TestMaxPropertiesFails;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONObject.ParseJSONValue('{"a": 1, "b": 2, "c": 3}') as TJSONObject;
  try
    lKeyword := TMaxPropertiesKeyword.Create(2);
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, 'Object with 3 properties > 2 limit should be invalid');
    CheckEquals(KEYWORD_MAXPROPERTIES, lResult.Errors[0].Keyword);
    CheckEquals(2, lResult.Errors[0].Context.GetValue<Integer>('limit'));
    CheckEquals(3, lResult.Errors[0].Context.GetValue<Integer>('actual'));
  finally
    lInstance.Free;
  end;
end;

procedure TTestSizesAndSubschemasKeywords.TestMaxPropertiesIgnoredOnNonObjects;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('abc');
  try
    lKeyword := TMaxPropertiesKeyword.Create(2);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Ignored on strings');
  finally
    lInstance.Free;
  end;
end;

procedure TTestSizesAndSubschemasKeywords.TestMinPropertiesPasses;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONObject.ParseJSONValue('{"a": 1, "b": 2}') as TJSONObject;
  try
    lKeyword := TMinPropertiesKeyword.Create(2);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Object with 2 properties >= 2 limit should be valid');
  finally
    lInstance.Free;
  end;
end;

procedure TTestSizesAndSubschemasKeywords.TestMinPropertiesFails;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONObject.ParseJSONValue('{"a": 1}') as TJSONObject;
  try
    lKeyword := TMinPropertiesKeyword.Create(2);
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, 'Object with 1 property < 2 limit should be invalid');
    CheckEquals(KEYWORD_MINPROPERTIES, lResult.Errors[0].Keyword);
    CheckEquals(2, lResult.Errors[0].Context.GetValue<Integer>('limit'));
    CheckEquals(1, lResult.Errors[0].Context.GetValue<Integer>('actual'));
  finally
    lInstance.Free;
  end;
end;

procedure TTestSizesAndSubschemasKeywords.TestMinPropertiesIgnoredOnNonObjects;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('abc');
  try
    lKeyword := TMinPropertiesKeyword.Create(2);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Ignored on strings');
  finally
    lInstance.Free;
  end;
end;

procedure TTestSizesAndSubschemasKeywords.TestPropertyNamesPasses;
var
  lInstance: TJSONValue;
  lSubSchemaObj: TJSONObject;
  lSubSchema: ICompiledSchema;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lSubSchemaObj := TJSONObject.ParseJSONValue('{"maxLength":3}') as TJSONObject;
  try
    lSubSchema := TDraft6Parser.Parse(lSubSchemaObj);
    lKeyword := TPropertyNamesKeyword.Create(lSubSchema);

    lInstance := TJSONObject.ParseJSONValue('{"abc": 1, "xy": 2}') as TJSONObject;
    try
      lResult := lKeyword.Validate(lInstance);
      CheckTrue(lResult.IsValid, 'All keys have length <= 3');
    finally
      lInstance.Free;
    end;
  finally
    lSubSchemaObj.Free;
  end;
end;

procedure TTestSizesAndSubschemasKeywords.TestPropertyNamesFails;
var
  lInstance: TJSONValue;
  lSubSchemaObj: TJSONObject;
  lSubSchema: ICompiledSchema;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lSubSchemaObj := TJSONObject.ParseJSONValue('{"maxLength":3}') as TJSONObject;
  try
    lSubSchema := TDraft6Parser.Parse(lSubSchemaObj);
    lKeyword := TPropertyNamesKeyword.Create(lSubSchema);

    lInstance := TJSONObject.ParseJSONValue('{"abc": 1, "xyz123": 2}') as TJSONObject;
    try
      lResult := lKeyword.Validate(lInstance);
      CheckFalse(lResult.IsValid, '"xyz123" is too long');
    finally
      lInstance.Free;
    end;
  finally
    lSubSchemaObj.Free;
  end;
end;

procedure TTestSizesAndSubschemasKeywords.TestPropertyNamesIgnoredOnNonObjects;
var
  lInstance: TJSONValue;
  lSubSchemaObj: TJSONObject;
  lSubSchema: ICompiledSchema;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lSubSchemaObj := TJSONObject.ParseJSONValue('{"maxLength":3}') as TJSONObject;
  try
    lSubSchema := TDraft6Parser.Parse(lSubSchemaObj);
    lKeyword := TPropertyNamesKeyword.Create(lSubSchema);

    lInstance := TJSONString.Create('abc');
    try
      lResult := lKeyword.Validate(lInstance);
      CheckTrue(lResult.IsValid, 'Ignored on strings');
    finally
      lInstance.Free;
    end;
  finally
    lSubSchemaObj.Free;
  end;
end;

initialization
  RegisterTest(TTestSizesAndSubschemasKeywords.Suite);

end.
