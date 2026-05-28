program TestJsonSchema;

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  DUnitTestRunner,
  TestJsonSchema.Mock.HttpServer in '..\src\TestJsonSchema.Mock.HttpServer.pas',
  TestJsonSchema.Runner.DUnit in '..\src\TestJsonSchema.Runner.DUnit.pas',
  TestJsonSchema.Types in '..\src\TestJsonSchema.Types.pas',
  TestJsonSchema.Utils.DraftResolver in '..\src\TestJsonSchema.Utils.DraftResolver.pas',
  TestJsonSchema.Utils.Paths in '..\src\TestJsonSchema.Utils.Paths.pas',
  JsonSchema.Common.Utils in '..\..\src\Utils\JsonSchema.Common.Utils.pas',
  JsonSchema.CollectionUtils in '..\..\src\Utils\JsonSchema.CollectionUtils.pas',
  JsonSchema.ReflectionCache in '..\..\src\Utils\JsonSchema.ReflectionCache.pas',
  JsonSchema.JsonPathUtils in '..\..\src\Utils\JsonSchema.JsonPathUtils.pas',
  JsonSchema.FormatValidator in '..\..\src\Utils\JsonSchema.FormatValidator.pas',
  JsonSchema.Walker in '..\..\src\Walker\JsonSchema.Walker.pas',
  JsonSchema.Walker.Types in '..\..\src\Walker\JsonSchema.Walker.Types.pas',
  JsonSchema.Visitor.Validation.Numeric in '..\..\src\Validation\Visitors\Validation\JsonSchema.Visitor.Validation.Numeric.pas',
  JsonSchema.Visitor.Validation.&Object in '..\..\src\Validation\Visitors\Validation\JsonSchema.Visitor.Validation.Object.pas',
  JsonSchema.Visitor.Validation.&String in '..\..\src\Validation\Visitors\Validation\JsonSchema.Visitor.Validation.String.pas',
  JsonSchema.Visitor.Validation.Format in '..\..\src\Validation\Visitors\Validation\JsonSchema.Visitor.Validation.Format.pas',
  JsonSchema.Visitor.Validation.&Array in '..\..\src\Validation\Visitors\Validation\JsonSchema.Visitor.Validation.Array.pas',
  JsonSchema.Visitor.Validation.Base in '..\..\src\Validation\Visitors\Validation\JsonSchema.Visitor.Validation.Base.pas',
  JsonSchema.Visitor.RelativePointer.Stub in '..\..\src\Validation\Visitors\RelativeJsonPointer\JsonSchema.Visitor.RelativePointer.Stub.pas',
  JsonSchema.Visitors.Types in '..\..\src\Validation\Visitors\JsonSchema.Visitors.Types.pas',
  JsonSchema.Visitor.HyperSchema.Stub in '..\..\src\Validation\Visitors\HyperSchema\JsonSchema.Visitor.HyperSchema.Stub.pas',
  JsonSchema.Visitors.Base in '..\..\src\Validation\Visitors\JsonSchema.Visitors.Base.pas',
  JsonSchema.Visitors.Interfaces in '..\..\src\Validation\Visitors\JsonSchema.Visitors.Interfaces.pas',
  JsonSchema.Visitor.Core.Base in '..\..\src\Validation\Visitors\Core\JsonSchema.Visitor.Core.Base.pas',
  JsonSchema.Visitor.Core.Registry in '..\..\src\Validation\Visitors\Core\JsonSchema.Visitor.Core.Registry.pas',
  JsonSchema.Visitor.Applicator.Evaluated in '..\..\src\Validation\Visitors\Applicator\JsonSchema.Visitor.Applicator.Evaluated.pas',
  JsonSchema.Visitor.Applicator.&Object in '..\..\src\Validation\Visitors\Applicator\JsonSchema.Visitor.Applicator.Object.pas',
  JsonSchema.Visitor.Applicator.Base in '..\..\src\Validation\Visitors\Applicator\JsonSchema.Visitor.Applicator.Base.pas',
  JsonSchema.Visitor.Applicator.Combiner in '..\..\src\Validation\Visitors\Applicator\JsonSchema.Visitor.Applicator.Combiner.pas',
  JsonSchema.Visitor.Applicator.Conditional in '..\..\src\Validation\Visitors\Applicator\JsonSchema.Visitor.Applicator.Conditional.pas',
  JsonSchema.Validation.Scope in '..\..\src\Validation\JsonSchema.Validation.Scope.pas',
  JsonSchema.Visitor.Applicator.&Array in '..\..\src\Validation\Visitors\Applicator\JsonSchema.Visitor.Applicator.Array.pas',
  JsonSchema.Validation.Interfaces in '..\..\src\Validation\JsonSchema.Validation.Interfaces.pas',
  JsonSchema.Validation.RefResolver in '..\..\src\Validation\JsonSchema.Validation.RefResolver.pas',
  JsonSchema.Validation.Result in '..\..\src\Validation\JsonSchema.Validation.Result.pas',
  JsonSchema.Validation.Base in '..\..\src\Validation\JsonSchema.Validation.Base.pas',
  JsonSchema.Validation.ErrorHandler in '..\..\src\Validation\JsonSchema.Validation.ErrorHandler.pas',
  JsonSchema.Validation.Draft7 in '..\..\src\Validation\Drafts\JsonSchema.Validation.Draft7.pas',
  JsonSchema.Validation.DraftCommon in '..\..\src\Validation\Drafts\JsonSchema.Validation.DraftCommon.pas',
  JsonSchema.Validation.Draft6 in '..\..\src\Validation\Drafts\JsonSchema.Validation.Draft6.pas',
  JsonSchema.Validation.Draft2020_12 in '..\..\src\Validation\Drafts\JsonSchema.Validation.Draft2020_12.pas',
  JsonSchema.Validation.Draft2019_09 in '..\..\src\Validation\Drafts\JsonSchema.Validation.Draft2019_09.pas',
  JsonSchema.Translate.enUS in '..\..\src\Translate\JsonSchema.Translate.enUS.pas',
  JsonSchema.Translate.ptBR in '..\..\src\Translate\JsonSchema.Translate.ptBR.pas',
  JsonSchema.Translate.Provider in '..\..\src\Translate\JsonSchema.Translate.Provider.pas',
  JsonSchema.Translate.Types in '..\..\src\Translate\JsonSchema.Translate.Types.pas',
  JsonSchema.Registry.Uri in '..\..\src\Registry\JsonSchema.Registry.Uri.pas',
  JsonSchema.Registry.Utils in '..\..\src\Registry\JsonSchema.Registry.Utils.pas',
  JsonSchema.Translate.Interfaces in '..\..\src\Translate\JsonSchema.Translate.Interfaces.pas',
  JsonSchema.Registry.Types in '..\..\src\Registry\JsonSchema.Registry.Types.pas',
  JsonSchema.Registry.Uri.Builder in '..\..\src\Registry\JsonSchema.Registry.Uri.Builder.pas',
  JsonSchema.Registry.Uri.Validator in '..\..\src\Registry\JsonSchema.Registry.Uri.Validator.pas',
  JsonSchema.Registry.Base in '..\..\src\Registry\JsonSchema.Registry.Base.pas',
  JsonSchema.Registry.Loader in '..\..\src\Registry\JsonSchema.Registry.Loader.pas',
  JsonSchema.Registry.Resource in '..\..\src\Registry\JsonSchema.Registry.Resource.pas',
  JsonSchema in '..\..\src\JsonSchema.pas',
  JsonSchema.Types in '..\..\src\Core\JsonSchema.Types.pas',
  JsonSchema.Exceptions in '..\..\src\Core\JsonSchema.Exceptions.pas',
  JsonSchema.Interfaces in '..\..\src\Core\JsonSchema.Interfaces.pas',
  JsonSchema.Consts in '..\..\src\Core\JsonSchema.Consts.pas';

{$R *.RES}

const
  PORTA_SERVIDOR_REMOTO = 1234;

var
  lServer: TMockHttpServer;

begin
  { Inicialização da Infraestrutura de Mock (Mocks para testes remotos) }
  lServer := TMockHttpServer.Create;
  try
    lServer.Start(PORTA_SERVIDOR_REMOTO);

    { Registro dos Drafts seguindo o padrão Builder / Fluente (KISS) }
    TJsonSchemaValidationTest.RegisterDefaultDrafts;

    { Dispara a interface do DUnit (GUI ou Console dependendo da compilação) }
    DUnitTestRunner.RunRegisteredTests;
  finally
    lServer.Stop;
    lServer.Free;
  end;
end.
