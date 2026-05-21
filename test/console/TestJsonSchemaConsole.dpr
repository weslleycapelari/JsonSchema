program TestJsonSchemaConsole;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Generics.Collections,
  TestJsonSchema.Types in '..\src\TestJsonSchema.Types.pas',
  TestJsonSchema.Runner.Console in '..\src\TestJsonSchema.Runner.Console.pas',
  TestJsonSchema.CLI.Parser in '..\src\TestJsonSchema.CLI.Parser.pas',
  TestJsonSchema.Console.Renderer in '..\src\TestJsonSchema.Console.Renderer.pas',
  TestJsonSchema.Report.Writer in '..\src\TestJsonSchema.Report.Writer.pas',
  TestJsonSchema.Mock.HttpServer in '..\src\TestJsonSchema.Mock.HttpServer.pas',
  TestJsonSchema.Utils.Paths in '..\src\TestJsonSchema.Utils.Paths.pas',
  TestJsonSchema.Utils.DraftResolver in '..\src\TestJsonSchema.Utils.DraftResolver.pas',
  JsonSchema.Consts in '..\..\src\Core\JsonSchema.Consts.pas',
  JsonSchema.Exceptions in '..\..\src\Core\JsonSchema.Exceptions.pas',
  JsonSchema.Interfaces in '..\..\src\Core\JsonSchema.Interfaces.pas',
  JsonSchema.Types in '..\..\src\Core\JsonSchema.Types.pas',
  JsonSchema.Registry.Base in '..\..\src\Registry\JsonSchema.Registry.Base.pas',
  JsonSchema.Registry.Loader in '..\..\src\Registry\JsonSchema.Registry.Loader.pas',
  JsonSchema.Registry.Resource in '..\..\src\Registry\JsonSchema.Registry.Resource.pas',
  JsonSchema.Registry.Types in '..\..\src\Registry\JsonSchema.Registry.Types.pas',
  JsonSchema.Registry.Uri.Builder in '..\..\src\Registry\JsonSchema.Registry.Uri.Builder.pas',
  JsonSchema.Registry.Uri in '..\..\src\Registry\JsonSchema.Registry.Uri.pas',
  JsonSchema.Registry.Uri.Validator in '..\..\src\Registry\JsonSchema.Registry.Uri.Validator.pas',
  JsonSchema.Registry.Utils in '..\..\src\Registry\JsonSchema.Registry.Utils.pas',
  JsonSchema.Translate.enUS in '..\..\src\Translate\JsonSchema.Translate.enUS.pas',
  JsonSchema.Translate.Interfaces in '..\..\src\Translate\JsonSchema.Translate.Interfaces.pas',
  JsonSchema.Translate.Provider in '..\..\src\Translate\JsonSchema.Translate.Provider.pas',
  JsonSchema.Translate.ptBR in '..\..\src\Translate\JsonSchema.Translate.ptBR.pas',
  JsonSchema.Translate.Types in '..\..\src\Translate\JsonSchema.Translate.Types.pas',
  JsonSchema.CollectionUtils in '..\..\src\Utils\JsonSchema.CollectionUtils.pas',
  JsonSchema.Common.Utils in '..\..\src\Utils\JsonSchema.Common.Utils.pas',
  JsonSchema.FormatValidator in '..\..\src\Utils\JsonSchema.FormatValidator.pas',
  JsonSchema.JsonPathUtils in '..\..\src\Utils\JsonSchema.JsonPathUtils.pas',
  JsonSchema.ReflectionCache in '..\..\src\Utils\JsonSchema.ReflectionCache.pas',
  JsonSchema.Validation.Base in '..\..\src\Validation\JsonSchema.Validation.Base.pas',
  JsonSchema.Validation.ErrorHandler in '..\..\src\Validation\JsonSchema.Validation.ErrorHandler.pas',
  JsonSchema.Validation.Interfaces in '..\..\src\Validation\JsonSchema.Validation.Interfaces.pas',
  JsonSchema.Validation.RefResolver in '..\..\src\Validation\JsonSchema.Validation.RefResolver.pas',
  JsonSchema.Validation.Result in '..\..\src\Validation\JsonSchema.Validation.Result.pas',
  JsonSchema.Validation.Scope in '..\..\src\Validation\JsonSchema.Validation.Scope.pas',
  JsonSchema.Validation.Draft6 in '..\..\src\Validation\Drafts\JsonSchema.Validation.Draft6.pas',
  JsonSchema.Validation.Draft7 in '..\..\src\Validation\Drafts\JsonSchema.Validation.Draft7.pas',
  JsonSchema.Validation.Draft2019_09 in '..\..\src\Validation\Drafts\JsonSchema.Validation.Draft2019_09.pas',
  JsonSchema.Validation.Draft2020_12 in '..\..\src\Validation\Drafts\JsonSchema.Validation.Draft2020_12.pas',
  JsonSchema.Validation.DraftCommon in '..\..\src\Validation\Drafts\JsonSchema.Validation.DraftCommon.pas',
  JsonSchema.Visitors.Base in '..\..\src\Validation\Visitors\JsonSchema.Visitors.Base.pas',
  JsonSchema.Visitors.Interfaces in '..\..\src\Validation\Visitors\JsonSchema.Visitors.Interfaces.pas',
  JsonSchema.Visitors.Types in '..\..\src\Validation\Visitors\JsonSchema.Visitors.Types.pas',
  JsonSchema.Visitor.Applicator.&Array in '..\..\src\Validation\Visitors\Applicator\JsonSchema.Visitor.Applicator.Array.pas',
  JsonSchema.Visitor.Applicator.Base in '..\..\src\Validation\Visitors\Applicator\JsonSchema.Visitor.Applicator.Base.pas',
  JsonSchema.Visitor.Applicator.Combiner in '..\..\src\Validation\Visitors\Applicator\JsonSchema.Visitor.Applicator.Combiner.pas',
  JsonSchema.Visitor.Applicator.Conditional in '..\..\src\Validation\Visitors\Applicator\JsonSchema.Visitor.Applicator.Conditional.pas',
  JsonSchema.Visitor.Applicator.Evaluated in '..\..\src\Validation\Visitors\Applicator\JsonSchema.Visitor.Applicator.Evaluated.pas',
  JsonSchema.Visitor.Applicator.&Object in '..\..\src\Validation\Visitors\Applicator\JsonSchema.Visitor.Applicator.Object.pas',
  JsonSchema.Visitor.Core.Base in '..\..\src\Validation\Visitors\Core\JsonSchema.Visitor.Core.Base.pas',
  JsonSchema.Visitor.Core.Registry in '..\..\src\Validation\Visitors\Core\JsonSchema.Visitor.Core.Registry.pas',
  JsonSchema.Visitor.HyperSchema.Stub in '..\..\src\Validation\Visitors\HyperSchema\JsonSchema.Visitor.HyperSchema.Stub.pas',
  JsonSchema.Visitor.RelativePointer.Stub in '..\..\src\Validation\Visitors\RelativeJsonPointer\JsonSchema.Visitor.RelativePointer.Stub.pas',
  JsonSchema.Visitor.Validation.&Array in '..\..\src\Validation\Visitors\Validation\JsonSchema.Visitor.Validation.Array.pas',
  JsonSchema.Visitor.Validation.Base in '..\..\src\Validation\Visitors\Validation\JsonSchema.Visitor.Validation.Base.pas',
  JsonSchema.Visitor.Validation.Format in '..\..\src\Validation\Visitors\Validation\JsonSchema.Visitor.Validation.Format.pas',
  JsonSchema.Visitor.Validation.Numeric in '..\..\src\Validation\Visitors\Validation\JsonSchema.Visitor.Validation.Numeric.pas',
  JsonSchema.Visitor.Validation.&Object in '..\..\src\Validation\Visitors\Validation\JsonSchema.Visitor.Validation.Object.pas',
  JsonSchema.Visitor.Validation.&String in '..\..\src\Validation\Visitors\Validation\JsonSchema.Visitor.Validation.String.pas',
  JsonSchema.Walker in '..\..\src\Walker\JsonSchema.Walker.pas',
  JsonSchema.Walker.Types in '..\..\src\Walker\JsonSchema.Walker.Types.pas',
  JsonSchema in '..\..\src\JsonSchema.pas';

{$R *.RES}

const
  PORTA_SERVIDOR_REMOTO = 1234;

var
  lDraftValue: string;
  lFileFilters: TArray<string>;
  lReportFile: string;
  lResolvedReportFile: string;
  lQuiet: Boolean;
  lFailFast: Boolean;
  lStop: Boolean;
  lServer: TMockHttpServer;
  lRenderer: TConsoleRenderer;
  lRunner: TConsoleRunner;
  lFailures: TList<TJsonSchemaFailure>;
  lTotal, lPassed, lFailed: Integer;
  lRunTotal, lRunPassed, lRunFailed: Integer;
  lFilterIndex: Integer;

begin
  try
    lRenderer := TConsoleRenderer.Create;
    try
      Writeln;
      Writeln;

      { Leitura de Argumentos (CLI) }
      lDraftValue := TCommandLineParser.GetValue('d');
      if lDraftValue = '' then
        lDraftValue := TCommandLineParser.GetValue('draft');

      lFileFilters := TCommandLineParser.GetValues('f', 'file');
      if Length(lFileFilters) = 0 then
        lFileFilters := TArray<string>.Create('');

      lReportFile := TCommandLineParser.GetValue('r');
      if lReportFile = '' then
        lReportFile := TCommandLineParser.GetValue('report');

      lQuiet := TCommandLineParser.HasSwitch('quiet') or TCommandLineParser.HasSwitch('q');
      lFailFast := TCommandLineParser.HasSwitch('fail-fast') or TCommandLineParser.HasSwitch('failfast');

      { Inicialização da Infraestrutura e Runner }
      lServer := TMockHttpServer.Create;
      try
        lServer.Start(PORTA_SERVIDOR_REMOTO);

        lFailures := TList<TJsonSchemaFailure>.Create;
        try
          lTotal := 0;
          lPassed := 0;
          lFailed := 0;
          lStop := False;

          lRunner := TConsoleRunner.Create(lFailFast,
            // Callback de Progresso
            procedure(const pProcessed, pTotal, pPassed, pFailed: Integer)
            begin
              if not lQuiet then
                lRenderer.RenderBars(pProcessed, pTotal, pPassed, pFailed);
            end,
            // Callback de Falhas
            procedure(const pFailure: TJsonSchemaFailure)
            begin
              lFailures.Add(pFailure);
              if not lQuiet then
                lRenderer.PrintFailure(pFailure);
            end);

          try
            { Execução dos Testes }
            lFilterIndex := 0;

            // Laço condicionado sem uso de Break (Normas de Codificação)
            while (not lStop) and (lFilterIndex < Length(lFileFilters)) do
            begin
              if (Length(lFileFilters) > 1) and (not lQuiet) then
                Writeln(Format('Executando filtro --file=%s', [lFileFilters[lFilterIndex]]));

              lRunner.Execute(lDraftValue, lFileFilters[lFilterIndex],
                ResolveDraftVersion(lDraftValue), lRunTotal, lRunPassed, lRunFailed);

              Inc(lTotal, lRunTotal);
              Inc(lPassed, lRunPassed);
              Inc(lFailed, lRunFailed);

              if lFailFast and (lRunFailed > 0) then
                lStop := True;

              Inc(lFilterIndex);
            end;
          finally
            lRunner.Free;
          end;

          { Finalização e Relatórios }
          if not lQuiet and (lTotal > 0) then
            lRenderer.RenderBars(lTotal, lTotal, lPassed, lFailed);

          Writeln;
          Writeln;
          Writeln(Format('Resumo: Total=%d, Passou=%d, Falhou=%d', [lTotal, lPassed, lFailed]));

          if lReportFile <> '' then
          begin
            lResolvedReportFile := TReportWriter.SaveFailureReport(lReportFile, lFailures);
            Writeln(Format('Relatorio salvo em: %s', [lResolvedReportFile]));
          end;

        finally
          lFailures.Free;
        end;
      finally
        lServer.Stop;
        lServer.Free;
      end;
    finally
      lRenderer.Free;
    end;

    { Saída do Sistema }
    if lFailed > 0 then
      Halt(1);

  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
