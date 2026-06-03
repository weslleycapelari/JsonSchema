unit TestJsonSchema.Keywords.Core;

(*
--------------------------------------------------------------------------------
Unit tests for core keywords ($schema, $id, id, $ref).
--------------------------------------------------------------------------------
*)

interface

uses
  TestFramework,
  System.JSON,
  System.SysUtils,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Core.SchemaRegistry,
  JsonSchema.Keywords.Schema,
  JsonSchema.Keywords.Id,
  JsonSchema.Keywords.Ref,
  JsonSchema.Results;

type
  TTestCoreKeywords = class(TTestCase)
  published
    procedure TestSchemaKeywordAlwaysValid;
    procedure TestIdKeywordRegistration;
    procedure TestLocalRefPointerResolution;
    procedure TestRecursiveRefGuard;
  end;

implementation

uses
  JsonSchema.CompiledSchema,
  JsonSchema.Keywords.TypeKeyword;

{ TTestCoreKeywords }

procedure TTestCoreKeywords.TestSchemaKeywordAlwaysValid;
var
  lKeyword: IJsonSchemaKeyword;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('http://json-schema.org/draft-06/schema#');
  try
    lKeyword := TSchemaKeyword.Create('http://json-schema.org/draft-06/schema#');
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, '$schema keyword validation should always be valid');
  finally
    lInstance.Free;
  end;
end;

procedure TTestCoreKeywords.TestIdKeywordRegistration;
var
  lKeyword: IJsonSchemaKeyword;
  lParent: TJSONObject;
  lVal: TJSONValue;
  lFoundSchema: TJSONValue;
begin
  lParent := TJSONObject.Create;
  lParent.AddPair('$id', 'http://example.com/schema.json');
  try
    // Set thread base URI
    TSchemaRegistry.CurrentBaseURI := 'http://example.com/';
    
    lVal := lParent.GetValue('$id');
    lKeyword := TIdKeyword.CreateKeyword(lVal, lParent, nil);
    
    CheckTrue(TSchemaRegistry.FindSchema('http://example.com/schema.json', lFoundSchema), 'Schema should be registered in the registry');
    CheckEquals(lParent.ToJSON, lFoundSchema.ToJSON, 'Registered schema must be identical to parent schema');
  finally
    lParent.Free;
    TSchemaRegistry.Clear;
    TSchemaRegistry.CurrentBaseURI := '';
  end;
end;

procedure TTestCoreKeywords.TestLocalRefPointerResolution;
var
  lKeyword: IJsonSchemaKeyword;
  lParent: TJSONObject;
  lDefObj: TJSONObject;
  lSubSchema: TJSONObject;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  // Set up a mock root schema:
  // {
  //   "definitions": {
  //     "foo": { "type": "string" }
  //   }
  // }
  lParent := TJSONObject.Create;
  lDefObj := TJSONObject.Create;
  lSubSchema := TJSONObject.Create;
  lSubSchema.AddPair('type', 'string');
  lDefObj.AddPair('foo', lSubSchema);
  lParent.AddPair('definitions', lDefObj);

  lInstance := TJSONString.Create('hello');
  try
    TSchemaRegistry.CurrentRootSchema := lParent;
    TSchemaRegistry.CurrentBaseURI := 'http://example.com/main.json';

    // Create target mock compile function that validates string type
    lKeyword := TRefKeyword.CreateKeyword(
      TJSONString.Create('#/definitions/foo'),
      lParent,
      function(const pVal: TJSONValue): ICompiledSchema
      var
        lArr: TArray<IJsonSchemaKeyword>;
      begin
        // Mock compile definitions/foo which has "type": "string"
        lArr := [TTypeKeyword.CreateKeyword(TJSONString.Create('string'), lSubSchema, nil)];
        Result := TCompiledSchema.Create(lArr);
      end
    );

    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Instance matching string type should validate successfully through ref');
  finally
    lInstance.Free;
    lParent.Free;
    TSchemaRegistry.CurrentRootSchema := nil;
    TSchemaRegistry.CurrentBaseURI := '';
  end;
end;

procedure TTestCoreKeywords.TestRecursiveRefGuard;
var
  lKeyword: IJsonSchemaKeyword;
  lParent: TJSONObject;
  lInstance: TJSONValue;
  lResult: IValidationResult;
  lRefKeywordInstance: TRefKeyword;
begin
  lParent := TJSONObject.Create;
  lInstance := TJSONNull.Create;
  try
    TSchemaRegistry.CurrentRootSchema := lParent;
    TSchemaRegistry.CurrentBaseURI := 'http://example.com/recursive.json';

    // Set up a recursive ref pointing back to the root schema:
    // Create the keyword which compiles lazily.
    // To mock the recursive compile, the compile function returns a compiled schema
    // that contains the ref keyword itself, causing a loop.
    lRefKeywordInstance := nil;
    lKeyword := TRefKeyword.CreateKeyword(
      TJSONString.Create('#'),
      lParent,
      function(const pVal: TJSONValue): ICompiledSchema
      begin
        Result := TCompiledSchema.Create([lRefKeywordInstance]);
      end
    );
    lRefKeywordInstance := lKeyword as TRefKeyword;

    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Circular reference validation loop must terminate through recursion guard');
  finally
    lInstance.Free;
    lParent.Free;
    TSchemaRegistry.CurrentRootSchema := nil;
    TSchemaRegistry.CurrentBaseURI := '';
  end;
end;

initialization
  RegisterTest(TTestCoreKeywords.Suite);

end.
