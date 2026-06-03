unit TestJsonSchema.Validator;

(*
--------------------------------------------------------------------------------
Integration test suite for the public JSON Schema validator facade (TJsonSchemaValidator).
--------------------------------------------------------------------------------
*)

interface

uses
  TestFramework,
  System.JSON,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Validator;

type
  /// <summary>DUnit test suite to validate end-to-end behaviors of TJsonSchemaValidator.</summary>
  TTestValidator = class(TTestCase)
  published
    procedure TestValidStringWithTypeAndMinLength;
    procedure TestInvalidStringTooShortWithTypeAndMinLength;
    procedure TestTypeStringWithNumberInputFails;
    procedure TestMinLengthAloneWithShortStringFails;
    procedure TestEmptySchemaWithAnyValuePasses;
    procedure TestCombinedArrayValidation;
    procedure TestCombinedObjectValidation;
    procedure TestMetadataKeywordsAreParsedSuccessfully;
    procedure TestFormatDateTimeValidation;
    procedure TestFormatEmailValidation;
    procedure TestFormatIPv4Validation;
    procedure TestFormatIPv6Validation;
    procedure TestFormatHostnameValidation;
    procedure TestFormatRegexValidation;
    procedure TestFormatUriValidation;
  end;

implementation

{ TTestValidator }

procedure TTestValidator.TestValidStringWithTypeAndMinLength;
var
  lValidator: TJsonSchemaValidator;
  lSchema: TJSONObject;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lValidator := TJsonSchemaValidator.Create;
  try
    lSchema := TJSONObject.Create;
    try
      lSchema.AddPair('type', 'string');
      lSchema.AddPair('minLength', TJSONNumber.Create(5));

      lInstance := TJSONString.Create('abcdef');
      try
        lResult := lValidator.Validate(lSchema, lInstance);
        CheckTrue(lResult.IsValid,
          '"abcdef" should be valid for {"type":"string","minLength":5}');
        CheckEquals(0, Length(lResult.Errors), 'No errors expected');
      finally
        lInstance.Free;
      end;
    finally
      lSchema.Free;
    end;
  finally
    lValidator.Free;
  end;
end;

procedure TTestValidator.TestInvalidStringTooShortWithTypeAndMinLength;
var
  lValidator: TJsonSchemaValidator;
  lSchema: TJSONObject;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lValidator := TJsonSchemaValidator.Create;
  try
    lSchema := TJSONObject.Create;
    try
      lSchema.AddPair('type', 'string');
      lSchema.AddPair('minLength', TJSONNumber.Create(5));

      lInstance := TJSONString.Create('abc');
      try
        lResult := lValidator.Validate(lSchema, lInstance);
        CheckFalse(lResult.IsValid,
          '"abc" should be invalid for {"type":"string","minLength":5}');
        Check(Length(lResult.Errors) > 0, 'Should have at least one error');
      finally
        lInstance.Free;
      end;
    finally
      lSchema.Free;
    end;
  finally
    lValidator.Free;
  end;
end;

procedure TTestValidator.TestTypeStringWithNumberInputFails;
var
  lValidator: TJsonSchemaValidator;
  lSchema: TJSONObject;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lValidator := TJsonSchemaValidator.Create;
  try
    lSchema := TJSONObject.Create;
    try
      lSchema.AddPair('type', 'string');

      lInstance := TJSONNumber.Create(123);
      try
        lResult := lValidator.Validate(lSchema, lInstance);
        CheckFalse(lResult.IsValid,
          'A number should be invalid for {"type":"string"}');
        CheckEquals(1, Length(lResult.Errors));
        CheckEquals('type', lResult.Errors[0].Keyword);
      finally
        lInstance.Free;
      end;
    finally
      lSchema.Free;
    end;
  finally
    lValidator.Free;
  end;
end;

procedure TTestValidator.TestMinLengthAloneWithShortStringFails;
var
  lValidator: TJsonSchemaValidator;
  lSchema: TJSONObject;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lValidator := TJsonSchemaValidator.Create;
  try
    lSchema := TJSONObject.Create;
    try
      lSchema.AddPair('minLength', TJSONNumber.Create(3));

      lInstance := TJSONString.Create('ab');
      try
        lResult := lValidator.Validate(lSchema, lInstance);
        CheckFalse(lResult.IsValid,
          '"ab" should be invalid for {"minLength":3}');
        CheckEquals(1, Length(lResult.Errors));
        CheckEquals('minLength', lResult.Errors[0].Keyword);
      finally
        lInstance.Free;
      end;
    finally
      lSchema.Free;
    end;
  finally
    lValidator.Free;
  end;
end;

procedure TTestValidator.TestEmptySchemaWithAnyValuePasses;
var
  lValidator: TJsonSchemaValidator;
  lSchema: TJSONObject;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lValidator := TJsonSchemaValidator.Create;
  try
    lSchema := TJSONObject.Create;
    try
      lInstance := TJSONString.Create('hello');
      try
        lResult := lValidator.Validate(lSchema, lInstance);
        CheckTrue(lResult.IsValid,
          'Any value should be valid for an empty schema {}');
        CheckEquals(0, Length(lResult.Errors));
      finally
        lInstance.Free;
      end;
    finally
      lSchema.Free;
    end;
  finally
    lValidator.Free;
  end;
end;

procedure TTestValidator.TestCombinedArrayValidation;
var
  lValidator: TJsonSchemaValidator;
  lSchema: TJSONObject;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lValidator := TJsonSchemaValidator.Create;
  try
    lSchema := TJSONObject.ParseJSONValue('{"type": "array", "minItems": 2, "maxItems": 4}') as TJSONObject;
    try
      // Test too short
      lInstance := TJSONObject.ParseJSONValue('[1]');
      try
        lResult := lValidator.Validate(lSchema, lInstance);
        CheckFalse(lResult.IsValid);
        CheckEquals(1, Length(lResult.Errors));
        CheckEquals('minItems', lResult.Errors[0].Keyword);
      finally
        lInstance.Free;
      end;

      // Test valid count
      lInstance := TJSONObject.ParseJSONValue('[1, 2, 3]');
      try
        lResult := lValidator.Validate(lSchema, lInstance);
        CheckTrue(lResult.IsValid);
      finally
        lInstance.Free;
      end;

      // Test too long
      lInstance := TJSONObject.ParseJSONValue('[1, 2, 3, 4, 5]');
      try
        lResult := lValidator.Validate(lSchema, lInstance);
        CheckFalse(lResult.IsValid);
        CheckEquals(1, Length(lResult.Errors));
        CheckEquals('maxItems', lResult.Errors[0].Keyword);
      finally
        lInstance.Free;
      end;
    finally
      lSchema.Free;
    end;
  finally
    lValidator.Free;
  end;
end;

procedure TTestValidator.TestCombinedObjectValidation;
var
  lValidator: TJsonSchemaValidator;
  lSchema: TJSONObject;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lValidator := TJsonSchemaValidator.Create;
  try
    lSchema := TJSONObject.ParseJSONValue('{"type": "object", "required": ["id", "status"]}') as TJSONObject;
    try
      // Test missing required field
      lInstance := TJSONObject.ParseJSONValue('{"id": 1}');
      try
        lResult := lValidator.Validate(lSchema, lInstance);
        CheckFalse(lResult.IsValid);
        CheckEquals(1, Length(lResult.Errors));
        CheckEquals('required', lResult.Errors[0].Keyword);
        CheckEquals('status', lResult.Errors[0].Context.GetValue<string>('missing'));
      finally
        lInstance.Free;
      end;

      // Test correct object
      lInstance := TJSONObject.ParseJSONValue('{"id": 1, "status": "active"}');
      try
        lResult := lValidator.Validate(lSchema, lInstance);
        CheckTrue(lResult.IsValid);
      finally
        lInstance.Free;
      end;
    finally
      lSchema.Free;
    end;
  finally
    lValidator.Free;
  end;
end;

procedure TTestValidator.TestMetadataKeywordsAreParsedSuccessfully;
var
  lValidator: TJsonSchemaValidator;
  lSchema: TJSONObject;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lValidator := TJsonSchemaValidator.Create;
  try
    lSchema := TJSONObject.ParseJSONValue(
      '{"title": "Test Title", "description": "Test Description", "default": "Default Value", "examples": ["Example 1"]}'
    ) as TJSONObject;
    try
      lInstance := TJSONString.Create('any string value');
      try
        lResult := lValidator.Validate(lSchema, lInstance);
        CheckTrue(lResult.IsValid, 'Metadata should not fail validation');
        CheckEquals(0, Length(lResult.Errors));
      finally
        lInstance.Free;
      end;
    finally
      lSchema.Free;
    end;
  finally
    lValidator.Free;
  end;
end;

procedure TTestValidator.TestFormatDateTimeValidation;
var
  lValidator: TJsonSchemaValidator;
  lSchema: TJSONObject;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lValidator := TJsonSchemaValidator.Create;
  try
    lSchema := TJSONObject.ParseJSONValue('{"type": "string", "format": "date-time"}') as TJSONObject;
    try
      lInstance := TJSONString.Create('2026-06-03T00:00:00Z');
      try
        lResult := lValidator.Validate(lSchema, lInstance);
        CheckTrue(lResult.IsValid, 'Valid RFC3339 DateTime should pass');
      finally
        lInstance.Free;
      end;

      lInstance := TJSONString.Create('invalid-date-time');
      try
        lResult := lValidator.Validate(lSchema, lInstance);
        CheckFalse(lResult.IsValid, 'Invalid DateTime should fail');
        CheckEquals(1, Length(lResult.Errors));
        CheckEquals('format', lResult.Errors[0].Keyword);
      finally
        lInstance.Free;
      end;
    finally
      lSchema.Free;
    end;
  finally
    lValidator.Free;
  end;
end;

procedure TTestValidator.TestFormatEmailValidation;
var
  lValidator: TJsonSchemaValidator;
  lSchema: TJSONObject;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lValidator := TJsonSchemaValidator.Create;
  try
    lSchema := TJSONObject.ParseJSONValue('{"type": "string", "format": "email"}') as TJSONObject;
    try
      lInstance := TJSONString.Create('test@example.com');
      try
        lResult := lValidator.Validate(lSchema, lInstance);
        CheckTrue(lResult.IsValid, 'Valid email should pass');
      finally
        lInstance.Free;
      end;

      lInstance := TJSONString.Create('invalid-email');
      try
        lResult := lValidator.Validate(lSchema, lInstance);
        CheckFalse(lResult.IsValid, 'Invalid email should fail');
      finally
        lInstance.Free;
      end;
    finally
      lSchema.Free;
    end;
  finally
    lValidator.Free;
  end;
end;

procedure TTestValidator.TestFormatIPv4Validation;
var
  lValidator: TJsonSchemaValidator;
  lSchema: TJSONObject;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lValidator := TJsonSchemaValidator.Create;
  try
    lSchema := TJSONObject.ParseJSONValue('{"type": "string", "format": "ipv4"}') as TJSONObject;
    try
      lInstance := TJSONString.Create('192.168.1.1');
      try
        lResult := lValidator.Validate(lSchema, lInstance);
        CheckTrue(lResult.IsValid, 'Valid IPv4 should pass');
      finally
        lInstance.Free;
      end;

      lInstance := TJSONString.Create('256.0.0.1');
      try
        lResult := lValidator.Validate(lSchema, lInstance);
        CheckFalse(lResult.IsValid, 'Invalid IPv4 should fail');
      finally
        lInstance.Free;
      end;
    finally
      lSchema.Free;
    end;
  finally
    lValidator.Free;
  end;
end;

procedure TTestValidator.TestFormatIPv6Validation;
var
  lValidator: TJsonSchemaValidator;
  lSchema: TJSONObject;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lValidator := TJsonSchemaValidator.Create;
  try
    lSchema := TJSONObject.ParseJSONValue('{"type": "string", "format": "ipv6"}') as TJSONObject;
    try
      lInstance := TJSONString.Create('2001:0db8:85a3:0000:0000:8a2e:0370:7334');
      try
        lResult := lValidator.Validate(lSchema, lInstance);
        CheckTrue(lResult.IsValid, 'Valid IPv6 should pass');
      finally
        lInstance.Free;
      end;

      lInstance := TJSONString.Create('2001:xyz::1');
      try
        lResult := lValidator.Validate(lSchema, lInstance);
        CheckFalse(lResult.IsValid, 'Invalid IPv6 should fail');
      finally
        lInstance.Free;
      end;
    finally
      lSchema.Free;
    end;
  finally
    lValidator.Free;
  end;
end;

procedure TTestValidator.TestFormatHostnameValidation;
var
  lValidator: TJsonSchemaValidator;
  lSchema: TJSONObject;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lValidator := TJsonSchemaValidator.Create;
  try
    lSchema := TJSONObject.ParseJSONValue('{"type": "string", "format": "hostname"}') as TJSONObject;
    try
      lInstance := TJSONString.Create('www.google.com');
      try
        lResult := lValidator.Validate(lSchema, lInstance);
        CheckTrue(lResult.IsValid, 'Valid hostname should pass');
      finally
        lInstance.Free;
      end;

      lInstance := TJSONString.Create('invalid_hostname');
      try
        lResult := lValidator.Validate(lSchema, lInstance);
        CheckFalse(lResult.IsValid, 'Invalid hostname should fail');
      finally
        lInstance.Free;
      end;
    finally
      lSchema.Free;
    end;
  finally
    lValidator.Free;
  end;
end;

procedure TTestValidator.TestFormatRegexValidation;
var
  lValidator: TJsonSchemaValidator;
  lSchema: TJSONObject;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lValidator := TJsonSchemaValidator.Create;
  try
    lSchema := TJSONObject.ParseJSONValue('{"type": "string", "format": "regex"}') as TJSONObject;
    try
      lInstance := TJSONString.Create('^[a-z]+$');
      try
        lResult := lValidator.Validate(lSchema, lInstance, TDraftVersion.dvDraft7);
        CheckTrue(lResult.IsValid, 'Valid regex should pass');
      finally
        lInstance.Free;
      end;

      lInstance := TJSONString.Create('[a-z');
      try
        lResult := lValidator.Validate(lSchema, lInstance, TDraftVersion.dvDraft7);
        CheckFalse(lResult.IsValid, 'Invalid regex should fail');
      finally
        lInstance.Free;
      end;
    finally
      lSchema.Free;
    end;
  finally
    lValidator.Free;
  end;
end;

procedure TTestValidator.TestFormatUriValidation;
var
  lValidator: TJsonSchemaValidator;
  lSchema: TJSONObject;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lValidator := TJsonSchemaValidator.Create;
  try
    lSchema := TJSONObject.ParseJSONValue('{"type": "string", "format": "uri"}') as TJSONObject;
    try
      lInstance := TJSONString.Create('https://google.com');
      try
        lResult := lValidator.Validate(lSchema, lInstance);
        CheckTrue(lResult.IsValid, 'Valid URI should pass');
      finally
        lInstance.Free;
      end;

      lInstance := TJSONString.Create('not-a-uri');
      try
        lResult := lValidator.Validate(lSchema, lInstance);
        CheckFalse(lResult.IsValid, 'Invalid URI should fail');
      finally
        lInstance.Free;
      end;
    finally
      lSchema.Free;
    end;
  finally
    lValidator.Free;
  end;
end;

initialization
  RegisterTest(TTestValidator.Suite);

end.
