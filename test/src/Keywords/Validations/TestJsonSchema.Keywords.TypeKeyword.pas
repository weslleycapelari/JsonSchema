unit TestJsonSchema.Keywords.TypeKeyword;

(*
--------------------------------------------------------------------------------
Unit tests for the 'type' keyword validator (TTypeKeyword).
--------------------------------------------------------------------------------
*)

interface

uses
  TestFramework,
  System.JSON,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Keywords.TypeKeyword;

type
  /// <summary>DUnit test suite to validate the behaviors of the TTypeKeyword validator.</summary>
  TTestTypeKeyword = class(TTestCase)
  published
    procedure TestStringPassesTypeString;
    procedure TestNumberFailsTypeString;
    procedure TestBooleanFailsTypeString;
    procedure TestNullFailsTypeString;
    procedure TestObjectFailsTypeString;
    procedure TestArrayFailsTypeString;
  end;

implementation

{ TTestTypeKeyword }

procedure TTestTypeKeyword.TestStringPassesTypeString;
var
  lKeyword: IJsonSchemaKeyword;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lKeyword := TTypeKeyword.Create('string');
  lInstance := TJSONString.Create('hello');
  try
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'A TJSONString should pass type="string"');
    CheckEquals(0, Length(lResult.Errors), 'No errors expected');
  finally
    lInstance.Free;
  end;
end;

procedure TTestTypeKeyword.TestNumberFailsTypeString;
var
  lKeyword: IJsonSchemaKeyword;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lKeyword := TTypeKeyword.Create('string');
  lInstance := TJSONNumber.Create(42);
  try
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, 'A TJSONNumber should fail type="string"');
    CheckEquals(1, Length(lResult.Errors), 'One error expected');
    CheckEquals('type', lResult.Errors[0].Keyword, 'Error keyword should be "type"');
  finally
    lInstance.Free;
  end;
end;

procedure TTestTypeKeyword.TestBooleanFailsTypeString;
var
  lKeyword: IJsonSchemaKeyword;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lKeyword := TTypeKeyword.Create('string');
  lInstance := TJSONTrue.Create;
  try
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, 'A TJSONTrue should fail type="string"');
    CheckEquals(1, Length(lResult.Errors), 'One error expected');
    CheckEquals('type', lResult.Errors[0].Keyword);
  finally
    lInstance.Free;
  end;
end;

procedure TTestTypeKeyword.TestNullFailsTypeString;
var
  lKeyword: IJsonSchemaKeyword;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lKeyword := TTypeKeyword.Create('string');
  lInstance := TJSONNull.Create;
  try
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, 'A TJSONNull should fail type="string"');
    CheckEquals(1, Length(lResult.Errors), 'One error expected');
    CheckEquals('type', lResult.Errors[0].Keyword);
  finally
    lInstance.Free;
  end;
end;

procedure TTestTypeKeyword.TestObjectFailsTypeString;
var
  lKeyword: IJsonSchemaKeyword;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lKeyword := TTypeKeyword.Create('string');
  lInstance := TJSONObject.Create;
  try
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, 'A TJSONObject should fail type="string"');
    CheckEquals(1, Length(lResult.Errors), 'One error expected');
    CheckEquals('type', lResult.Errors[0].Keyword);
  finally
    lInstance.Free;
  end;
end;

procedure TTestTypeKeyword.TestArrayFailsTypeString;
var
  lKeyword: IJsonSchemaKeyword;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lKeyword := TTypeKeyword.Create('string');
  lInstance := TJSONArray.Create;
  try
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, 'A TJSONArray should fail type="string"');
    CheckEquals(1, Length(lResult.Errors), 'One error expected');
    CheckEquals('type', lResult.Errors[0].Keyword);
  finally
    lInstance.Free;
  end;
end;

initialization
  RegisterTest(TTestTypeKeyword.Suite);

end.
