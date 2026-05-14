program TestJsonSchema;

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  DUnitTestRunner,
  TestJsonSchema.Paths in '..\src\TestJsonSchema.Paths.pas',
  TestJsonSchema.RunDrafts in '..\src\TestJsonSchema.RunDrafts.pas',
  TestJsonSchema.RemoteFiles in '..\src\TestJsonSchema.RemoteFiles.pas',
  JsonSchema.Common.Utils in '..\..\src\JsonSchema.Common.Utils.pas',
  JsonSchema in '..\..\src\JsonSchema.pas',
  JsonSchema.Translate.enUS in '..\..\src\JsonSchema.Translate.enUS.pas',
  JsonSchema.Translate.Interfaces in '..\..\src\JsonSchema.Translate.Interfaces.pas',
  JsonSchema.Translate.ptBR in '..\..\src\JsonSchema.Translate.ptBR.pas',
  JsonSchema.Translate.Types in '..\..\src\JsonSchema.Translate.Types.pas',
  JsonSchema.Translate.Utils in '..\..\src\JsonSchema.Translate.Utils.pas',
  JsonSchema.Validation.Base in '..\..\src\JsonSchema.Validation.Base.pas',
  JsonSchema.Validation.Draft6 in '..\..\src\JsonSchema.Validation.Draft6.pas',
  JsonSchema.Validation.Draft7 in '..\..\src\JsonSchema.Validation.Draft7.pas',
  JsonSchema.Validation.Draft2019_09 in '..\..\src\JsonSchema.Validation.Draft2019_09.pas',
  JsonSchema.Validation.Draft2020_12 in '..\..\src\JsonSchema.Validation.Draft2020_12.pas',
  JsonSchema.Validation.Interfaces in '..\..\src\JsonSchema.Validation.Interfaces.pas',
  JsonSchema.Validation.Types in '..\..\src\JsonSchema.Validation.Types.pas',
  JsonSchema.Visitors.Base in '..\..\src\JsonSchema.Visitors.Base.pas',
  JsonSchema.Visitors.Interfaces in '..\..\src\JsonSchema.Visitors.Interfaces.pas',
  JsonSchema.Visitors.Types in '..\..\src\JsonSchema.Visitors.Types.pas',
  JsonSchema.Walker in '..\..\src\JsonSchema.Walker.pas',
  JsonSchema.Walker.Types in '..\..\src\JsonSchema.Walker.Types.pas',
  JsonSchema.Registry.Base in '..\..\src\JsonSchema.Registry.Base.pas',
  JsonSchema.Registry.Types in '..\..\src\JsonSchema.Registry.Types.pas',
  JsonSchema.Registry.Uri in '..\..\src\JsonSchema.Registry.Uri.pas',
  JsonSchema.Registry.Utils in '..\..\src\JsonSchema.Registry.Utils.pas',
  JsonSchema.Registry.Uri.Validator in '..\..\src\JsonSchema.Registry.Uri.Validator.pas',
  JsonSchema.Registry.Uri.Builder in '..\..\src\JsonSchema.Registry.Uri.Builder.pas',
  JsonSchema.Registry.Uri.ParseResult in '..\..\src\JsonSchema.Registry.Uri.ParseResult.pas',
  JsonSchema.Registry.Resource in '..\..\src\JsonSchema.Registry.Resource.pas';

{$R *.RES}

begin
  TJsonSchemaValidationTest.RegisterDefaultDrafts;
  DUnitTestRunner.RunRegisteredTests;
end.
