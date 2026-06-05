unit TestSchema2Delphi;

(*
--------------------------------------------------------------------------------
DUnit unit test cases for Schema2Delphi code generator, asserting correct AST
traversal and output code generation in both Class and Record modes.
--------------------------------------------------------------------------------
*)

interface

uses
  TestFramework,
  System.JSON,
  System.SysUtils,
  Schema2Delphi.Visitor,
  Schema2Delphi.Utils,
  Schema2Delphi.Common;

type
  TTestSchema2Delphi = class(TTestCase)
  private
    FSchema: TJSONObject;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestClassGenerationBasic;
    procedure TestClassGenerationNullableAndReserved;
    procedure TestRecordGenerationReverseOrder;
  end;

implementation

uses
  System.StrUtils;

const
  TEST_SCHEMA =
    '{' +
    '  "$id": "https://example.com/test-schema.json",' +
    '  "type": "object",' +
    '  "properties": {' +
    '    "name": { "type": "string", "maxLength": 50, "description": "The person name" },' +
    '    "type": { "type": ["string", "null"] },' +
    '    "age": { "type": ["integer", "null"] },' +
    '    "isActive": { "type": ["boolean", "null"] },' +
    '    "friends": {' +
    '      "type": "array",' +
    '      "items": {' +
    '        "type": "object",' +
    '        "properties": {' +
    '          "name": { "type": "string" },' +
    '          "age": { "type": "integer" }' +
    '        }' +
    '      }' +
    '    },' +
    '    "status": {' +
    '      "enum": ["active", "inactive"]' +
    '    }' +
    '  },' +
    '  "required": ["name"]' +
    '}';

{ TTestSchema2Delphi }

procedure TTestSchema2Delphi.SetUp;
begin
  inherited;
  FSchema := TJSONObject.ParseJSONValue(TEST_SCHEMA) as TJSONObject;
end;

procedure TTestSchema2Delphi.TearDown;
begin
  FSchema.Free;
  inherited;
end;

procedure TTestSchema2Delphi.TestClassGenerationBasic;
var
  lConfig: TCodeGeneratorConfig;
  lGeneratedPas: string;
begin
  lConfig := TCodeGeneratorConfig.DefaultConfig;
  lConfig.GenerationMode := gmClass;
  lConfig.UseNullableTypes := False;

  lGeneratedPas := GenerateClassFromSchema(FSchema, 'Person', 'GeneratedDTO', lConfig);

  // Assert unit header and structures
  CheckTrue(ContainsText(lGeneratedPas, 'unit GeneratedDTO;'), 'Should contain unit name');
  CheckTrue(ContainsText(lGeneratedPas, 'interface'), 'Should contain interface section');
  CheckTrue(ContainsText(lGeneratedPas, 'type'), 'Should contain type section');
  CheckTrue(ContainsText(lGeneratedPas, '  TPerson = class;'), 'Should contain forward declaration for TPerson');
  CheckTrue(ContainsText(lGeneratedPas, '  TFriends = class;'), 'Should contain forward declaration for TFriends');
  
  // Assert fields and properties
  CheckTrue(ContainsText(lGeneratedPas, 'FName: string;'), 'Should contain FName field');
  CheckTrue(ContainsText(lGeneratedPas, 'property Name: string read FName write FName;'), 'Should contain Name property');
  CheckTrue(ContainsText(lGeneratedPas, 'FFriends: TArray<TFriends>;'), 'Should contain FFriends field');
  
  // Assert enum type
  CheckTrue(ContainsText(lGeneratedPas, 'TStatus = ('), 'Should contain TStatus enum declaration');
  CheckTrue(ContainsText(lGeneratedPas, '    StatusActive,'), 'Should contain StatusActive enum value');
  CheckTrue(ContainsText(lGeneratedPas, '    StatusInactive'), 'Should contain StatusInactive enum value');

  // Assert destructor leak protection
  CheckTrue(ContainsText(lGeneratedPas, 'destructor TPerson.Destroy;'), 'Should contain TPerson destructor implementation');
  CheckTrue(ContainsText(lGeneratedPas, 'for var lI := 0 to Length(FFriends) - 1 do'), 'Should contain loop to free array elements');
  CheckTrue(ContainsText(lGeneratedPas, 'FFriends[lI].Free;'), 'Should call Free on array elements');
end;

procedure TTestSchema2Delphi.TestClassGenerationNullableAndReserved;
var
  lConfig: TCodeGeneratorConfig;
  lGeneratedPas: string;
begin
  lConfig := TCodeGeneratorConfig.DefaultConfig;
  lConfig.GenerationMode := gmClass;
  lConfig.UseNullableTypes := True;
  lConfig.NullableTypeTemplate := 'TNullableValue<%s>';

  lGeneratedPas := GenerateClassFromSchema(FSchema, 'Person', 'GeneratedDTO', lConfig);

  // Assert nullable primitives are wrapped
  CheckTrue(ContainsText(lGeneratedPas, 'FAge: TNullableValue<Integer>;'), 'Should wrap age in TNullableValue');
  CheckTrue(ContainsText(lGeneratedPas, 'FIsActive: TNullableValue<Boolean>;'), 'Should wrap isActive in TNullableValue');

  // Assert reserved keyword sanitization ('type' is a Delphi keyword)
  CheckTrue(ContainsText(lGeneratedPas, 'FAType: string;'), 'Should sanitize field name "type" to "FAType"');
  CheckTrue(ContainsText(lGeneratedPas, 'property AType: string read FAType write FAType;'), 'Should sanitize property name "type" to "AType"');
  CheckTrue(ContainsText(lGeneratedPas, '[JSONName(''type'')]'), 'Should add JSONName attribute for sanitized property');

  // Assert validation attributes
  CheckTrue(ContainsText(lGeneratedPas, '[JsonSchema_Required]'), 'Should add JsonSchema_Required attribute');
  CheckTrue(ContainsText(lGeneratedPas, '[TJsonSchemaMaxLength(50)]'), 'Should add TJsonSchemaMaxLength attribute');
  CheckTrue(ContainsText(lGeneratedPas, '[TJsonSchemaDescription(''The person name'')]'), 'Should add TJsonSchemaDescription attribute');
end;

procedure TTestSchema2Delphi.TestRecordGenerationReverseOrder;
var
  lConfig: TCodeGeneratorConfig;
  lGeneratedPas: string;
  lFriendsIdx, lPersonIdx: Integer;
begin
  lConfig := TCodeGeneratorConfig.DefaultConfig;
  lConfig.GenerationMode := gmRecord;

  lGeneratedPas := GenerateClassFromSchema(FSchema, 'PersonRecord', 'GeneratedDTORecord', lConfig);

  // Assert records are declared (they do not use forward declarations)
  CheckTrue(ContainsText(lGeneratedPas, 'TPersonRecord = record'), 'Should contain TPersonRecord record declaration');
  CheckTrue(ContainsText(lGeneratedPas, 'TFriends = record'), 'Should contain TFriends record declaration');

  // Assert topological reverse order (TFriends must be declared BEFORE TPersonRecord)
  lFriendsIdx := Pos('TFriends = record', lGeneratedPas);
  lPersonIdx := Pos('TPersonRecord = record', lGeneratedPas);

  CheckTrue(lFriendsIdx > 0, 'TFriends declaration not found');
  CheckTrue(lPersonIdx > 0, 'TPersonRecord declaration not found');
  CheckTrue(lFriendsIdx < lPersonIdx, 'TFriends must be declared before TPersonRecord to compile correctly');
end;

initialization
  RegisterTest(TTestSchema2Delphi.Suite);

end.
