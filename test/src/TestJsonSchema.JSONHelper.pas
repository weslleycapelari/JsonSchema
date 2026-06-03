unit TestJsonSchema.JSONHelper;

(*
--------------------------------------------------------------------------------
Unit tests for the TJSONValue class helper (TJsonSchemaValueHelper).
--------------------------------------------------------------------------------
*)

interface

uses
  TestFramework,
  System.JSON,
  System.SysUtils;

type
  /// <summary>DUnit test suite to validate all secure JSON type checking helper methods.</summary>
  TTestJSONHelper = class(TTestCase)
  published
    procedure TestIsJSONString;
    procedure TestIsJSONNumber;
    procedure TestIsJSONInteger;
    procedure TestIsJSONBoolean;
    procedure TestIsJSONNull;
    procedure TestIsJSONArray;
    procedure TestIsJSONObject;
    procedure TestGetJSONType;
    procedure TestNilInstanceSafelyReturnsFalse;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TTestJSONHelper }

procedure TTestJSONHelper.TestIsJSONString;
var
  lStr: TJSONValue;
  lNum: TJSONValue;
begin
  lStr := TJSONString.Create('hello');
  lNum := TJSONNumber.Create(12.3);
  try
    CheckTrue(lStr.IsJSONString, 'TJSONString should return true for IsJSONString');
    CheckFalse(lNum.IsJSONString, 'TJSONNumber should return false for IsJSONString');
  finally
    lStr.Free;
    lNum.Free;
  end;
end;

procedure TTestJSONHelper.TestIsJSONNumber;
var
  lNum: TJSONValue;
  lStr: TJSONValue;
begin
  lNum := TJSONNumber.Create(12.3);
  lStr := TJSONString.Create('hello');
  try
    CheckTrue(lNum.IsJSONNumber);
    CheckFalse(lStr.IsJSONNumber);
  finally
    lNum.Free;
    lStr.Free;
  end;
end;

procedure TTestJSONHelper.TestIsJSONInteger;
var
  lInt: TJSONValue;
  lFloat: TJSONValue;
begin
  lInt := TJSONNumber.Create(42);
  lFloat := TJSONNumber.Create(42.5);
  try
    CheckTrue(lInt.IsJSONInteger);
    CheckFalse(lFloat.IsJSONInteger);
  finally
    lInt.Free;
    lFloat.Free;
  end;
end;

procedure TTestJSONHelper.TestIsJSONBoolean;
var
  lTrue: TJSONValue;
  lFalse: TJSONValue;
  lBool: TJSONValue;
  lStr: TJSONValue;
begin
  lTrue := TJSONTrue.Create;
  lFalse := TJSONFalse.Create;
  lBool := TJSONBool.Create(True);
  lStr := TJSONString.Create('true');
  try
    CheckTrue(lTrue.IsJSONBoolean);
    CheckTrue(lFalse.IsJSONBoolean);
    CheckTrue(lBool.IsJSONBoolean);
    CheckFalse(lStr.IsJSONBoolean);
  finally
    lTrue.Free;
    lFalse.Free;
    lBool.Free;
    lStr.Free;
  end;
end;

procedure TTestJSONHelper.TestIsJSONNull;
var
  lNull: TJSONValue;
  lStr: TJSONValue;
begin
  lNull := TJSONNull.Create;
  lStr := TJSONString.Create('null');
  try
    CheckTrue(lNull.IsJSONNull);
    CheckFalse(lStr.IsJSONNull);
  finally
    lNull.Free;
    lStr.Free;
  end;
end;

procedure TTestJSONHelper.TestIsJSONArray;
var
  lArr: TJSONValue;
  lObj: TJSONValue;
begin
  lArr := TJSONArray.Create;
  lObj := TJSONObject.Create;
  try
    CheckTrue(lArr.IsJSONArray);
    CheckFalse(lObj.IsJSONArray);
  finally
    lArr.Free;
    lObj.Free;
  end;
end;

procedure TTestJSONHelper.TestIsJSONObject;
var
  lObj: TJSONValue;
  lArr: TJSONValue;
begin
  lObj := TJSONObject.Create;
  lArr := TJSONArray.Create;
  try
    CheckTrue(lObj.IsJSONObject);
    CheckFalse(lArr.IsJSONObject);
  finally
    lObj.Free;
    lArr.Free;
  end;
end;

procedure TTestJSONHelper.TestGetJSONType;
var
  lStr: TJSONValue;
  lNum: TJSONValue;
  lNull: TJSONValue;
begin
  lStr := TJSONString.Create('abc');
  lNum := TJSONNumber.Create(10);
  lNull := TJSONNull.Create;
  try
    CheckEquals('string', lStr.GetJSONType);
    CheckEquals('number', lNum.GetJSONType);
    CheckEquals('null', lNull.GetJSONType);
  finally
    lStr.Free;
    lNum.Free;
    lNull.Free;
  end;
end;

procedure TTestJSONHelper.TestNilInstanceSafelyReturnsFalse;
var
  lVal: TJSONValue;
begin
  lVal := nil;
  CheckFalse(lVal.IsJSONString);
  CheckFalse(lVal.IsJSONNumber);
  CheckFalse(lVal.IsJSONInteger);
  CheckFalse(lVal.IsJSONBoolean);
  CheckFalse(lVal.IsJSONNull);
  CheckFalse(lVal.IsJSONArray);
  CheckFalse(lVal.IsJSONObject);
  CheckEquals('null', lVal.GetJSONType);
end;

initialization
  RegisterTest(TTestJSONHelper.Suite);

end.
