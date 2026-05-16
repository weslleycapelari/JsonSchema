program TestJsonSchemaConsole;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Generics.Collections,
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
  JsonSchema.Registry.Resource in '..\..\src\JsonSchema.Registry.Resource.pas',
  TestJsonSchema.Types in '..\src\TestJsonSchema.Types.pas',
  TestJsonSchema.Runner.Console in '..\src\TestJsonSchema.Runner.Console.pas',
  TestJsonSchema.CLI.Parser in '..\src\TestJsonSchema.CLI.Parser.pas',
  TestJsonSchema.Console.Renderer in '..\src\TestJsonSchema.Console.Renderer.pas',
  TestJsonSchema.Report.Writer in '..\src\TestJsonSchema.Report.Writer.pas',
  TestJsonSchema.Mock.HttpServer in '..\src\TestJsonSchema.Mock.HttpServer.pas',
  TestJsonSchema.Utils.Paths in '..\src\TestJsonSchema.Utils.Paths.pas',
  TestJsonSchema.Utils.DraftResolver in '..\src\TestJsonSchema.Utils.DraftResolver.pas';

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
