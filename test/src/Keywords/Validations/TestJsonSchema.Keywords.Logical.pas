unit TestJsonSchema.Keywords.Logical;

(*
--------------------------------------------------------------------------------
Unit tests for logical validation keywords (allOf, anyOf, oneOf, not).
--------------------------------------------------------------------------------
*)

interface

uses
  TestFramework,
  System.JSON,
  System.SysUtils,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.CompiledSchema,
  JsonSchema.Keywords.AllOf,
  JsonSchema.Keywords.AnyOf,
  JsonSchema.Keywords.OneOf,
  JsonSchema.Keywords.NotKeyword,
  JsonSchema.Results;

type
  TTestLogicalKeywords = class(TTestCase)
  published
    // allOf Tests
    procedure TestAllOfEmpty;
    procedure TestAllOfAllTrue;
    procedure TestAllOfSomeFalse;
    procedure TestAllOfAllFalse;

    // anyOf Tests
    procedure TestAnyOfEmpty;
    procedure TestAnyOfAllTrue;
    procedure TestAnyOfSomeTrue;
    procedure TestAnyOfAllFalse;

    // oneOf Tests
    procedure TestOneOfEmpty;
    procedure TestOneOfExactlyOneTrue;
    procedure TestOneOfMultipleTrue;
    procedure TestOneOfAllFalse;

    // not Tests
    procedure TestNotWithTrueSchema;
    procedure TestNotWithFalseSchema;
  end;

implementation

{ TTestLogicalKeywords }

procedure TTestLogicalKeywords.TestAllOfEmpty;
var
  lKeyword: IJsonSchemaKeyword;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('test');
  try
    lKeyword := TAllOfKeyword.Create([]);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Empty allOf should be valid');
  finally
    lInstance.Free;
  end;
end;

procedure TTestLogicalKeywords.TestAllOfAllTrue;
var
  lKeyword: IJsonSchemaKeyword;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('test');
  try
    lKeyword := TAllOfKeyword.Create([
      TCompiledSchema.CreateTrueSchema,
      TCompiledSchema.CreateTrueSchema
    ]);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'All true subschemas should be valid');
  finally
    lInstance.Free;
  end;
end;

procedure TTestLogicalKeywords.TestAllOfSomeFalse;
var
  lKeyword: IJsonSchemaKeyword;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('test');
  try
    lKeyword := TAllOfKeyword.Create([
      TCompiledSchema.CreateTrueSchema,
      TCompiledSchema.CreateFalseSchema
    ]);
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, 'At least one false subschema should fail validation');
  finally
    lInstance.Free;
  end;
end;

procedure TTestLogicalKeywords.TestAllOfAllFalse;
var
  lKeyword: IJsonSchemaKeyword;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('test');
  try
    lKeyword := TAllOfKeyword.Create([
      TCompiledSchema.CreateFalseSchema,
      TCompiledSchema.CreateFalseSchema
    ]);
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, 'All false subschemas should fail validation');
  finally
    lInstance.Free;
  end;
end;

procedure TTestLogicalKeywords.TestAnyOfEmpty;
var
  lKeyword: IJsonSchemaKeyword;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('test');
  try
    lKeyword := TAnyOfKeyword.Create([]);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Empty anyOf should be valid');
  finally
    lInstance.Free;
  end;
end;

procedure TTestLogicalKeywords.TestAnyOfAllTrue;
var
  lKeyword: IJsonSchemaKeyword;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('test');
  try
    lKeyword := TAnyOfKeyword.Create([
      TCompiledSchema.CreateTrueSchema,
      TCompiledSchema.CreateTrueSchema
    ]);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'All true subschemas should be valid');
  finally
    lInstance.Free;
  end;
end;

procedure TTestLogicalKeywords.TestAnyOfSomeTrue;
var
  lKeyword: IJsonSchemaKeyword;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('test');
  try
    lKeyword := TAnyOfKeyword.Create([
      TCompiledSchema.CreateFalseSchema,
      TCompiledSchema.CreateTrueSchema
    ]);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'One true subschema is enough for anyOf');
  finally
    lInstance.Free;
  end;
end;

procedure TTestLogicalKeywords.TestAnyOfAllFalse;
var
  lKeyword: IJsonSchemaKeyword;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('test');
  try
    lKeyword := TAnyOfKeyword.Create([
      TCompiledSchema.CreateFalseSchema,
      TCompiledSchema.CreateFalseSchema
    ]);
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, 'All false subschemas should fail anyOf');
  finally
    lInstance.Free;
  end;
end;

procedure TTestLogicalKeywords.TestOneOfEmpty;
var
  lKeyword: IJsonSchemaKeyword;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('test');
  try
    lKeyword := TOneOfKeyword.Create([]);
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, 'Empty oneOf should be invalid');
  finally
    lInstance.Free;
  end;
end;

procedure TTestLogicalKeywords.TestOneOfExactlyOneTrue;
var
  lKeyword: IJsonSchemaKeyword;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('test');
  try
    lKeyword := TOneOfKeyword.Create([
      TCompiledSchema.CreateFalseSchema,
      TCompiledSchema.CreateTrueSchema,
      TCompiledSchema.CreateFalseSchema
    ]);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Exactly one true subschema should be valid');
  finally
    lInstance.Free;
  end;
end;

procedure TTestLogicalKeywords.TestOneOfMultipleTrue;
var
  lKeyword: IJsonSchemaKeyword;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('test');
  try
    lKeyword := TOneOfKeyword.Create([
      TCompiledSchema.CreateTrueSchema,
      TCompiledSchema.CreateTrueSchema,
      TCompiledSchema.CreateFalseSchema
    ]);
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, 'Multiple true subschemas should fail oneOf');
  finally
    lInstance.Free;
  end;
end;

procedure TTestLogicalKeywords.TestOneOfAllFalse;
var
  lKeyword: IJsonSchemaKeyword;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('test');
  try
    lKeyword := TOneOfKeyword.Create([
      TCompiledSchema.CreateFalseSchema,
      TCompiledSchema.CreateFalseSchema
    ]);
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, 'All false subschemas should fail oneOf');
  finally
    lInstance.Free;
  end;
end;

procedure TTestLogicalKeywords.TestNotWithTrueSchema;
var
  lKeyword: IJsonSchemaKeyword;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('test');
  try
    lKeyword := TNotKeyword.Create(TCompiledSchema.CreateTrueSchema);
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, 'Not validation against true schema should fail');
  finally
    lInstance.Free;
  end;
end;

procedure TTestLogicalKeywords.TestNotWithFalseSchema;
var
  lKeyword: IJsonSchemaKeyword;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('test');
  try
    lKeyword := TNotKeyword.Create(TCompiledSchema.CreateFalseSchema);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Not validation against false schema should succeed');
  finally
    lInstance.Free;
  end;
end;

initialization
  RegisterTest(TTestLogicalKeywords.Suite);

end.
