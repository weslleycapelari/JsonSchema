program TestJsonSchemaConsole;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.StrUtils,
  System.Math,
  System.Classes,
  System.IOUtils,
  System.Generics.Collections,
  Winapi.Windows,
  TestJsonSchema.Paths in '..\src\TestJsonSchema.Paths.pas',
  JsonSchema.Common.Utils in '..\..\src\JsonSchema.Common.Utils.pas',
  TestJsonSchema.RemoteFiles in '..\src\TestJsonSchema.RemoteFiles.pas',
  TestJsonSchema.RunDrafts in '..\src\TestJsonSchema.RunDrafts.pas',
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

function GetSwitchValue(const ASwitchName: string): string;
var
  LIndex: Integer;
  LParam: string;
  LPrefix: string;
  LLongPrefix: string;
begin
  Result := '';
  LPrefix := '-' + ASwitchName + '=';
  LLongPrefix := '--' + ASwitchName + '=';

  for LIndex := 1 to ParamCount do
  begin
    LParam := ParamStr(LIndex);

    if SameText(LParam, '-' + ASwitchName) or SameText(LParam, '--' + ASwitchName) then
    begin
      if LIndex < ParamCount then
        Exit(ParamStr(LIndex + 1));
    end
    else if StartsText(LPrefix, LParam) then
      Exit(Copy(LParam, Length(LPrefix) + 1, MaxInt))
    else if StartsText(LLongPrefix, LParam) then
      Exit(Copy(LParam, Length(LLongPrefix) + 1, MaxInt));
  end;
end;

function GetSwitchValues(const AShortSwitch, ALongSwitch: string): TArray<string>;
var
  LIndex: Integer;
  LParam: string;
  LPrefixShort: string;
  LPrefixLong: string;
  LValues: TList<string>;
begin
  LValues := TList<string>.Create;
  try
    LPrefixShort := '-' + AShortSwitch + '=';
    LPrefixLong := '--' + ALongSwitch + '=';

    for LIndex := 1 to ParamCount do
    begin
      LParam := ParamStr(LIndex);

      if SameText(LParam, '-' + AShortSwitch) or SameText(LParam, '--' + ALongSwitch) then
      begin
        if LIndex < ParamCount then
          LValues.Add(ParamStr(LIndex + 1));
        Continue;
      end;

      if StartsText(LPrefixShort, LParam) then
      begin
        LValues.Add(Copy(LParam, Length(LPrefixShort) + 1, MaxInt));
        Continue;
      end;

      if StartsText(LPrefixLong, LParam) then
        LValues.Add(Copy(LParam, Length(LPrefixLong) + 1, MaxInt));
    end;

    Result := LValues.ToArray;
  finally
    LValues.Free;
  end;
end;

function HasSwitch(const ASwitchName: string): Boolean;
var
  LIndex: Integer;
  LParam: string;
begin
  for LIndex := 1 to ParamCount do
  begin
    LParam := ParamStr(LIndex);
    if SameText(LParam, '-' + ASwitchName) or SameText(LParam, '--' + ASwitchName) then
      Exit(True);
  end;

  Result := False;
end;

function ResolveDraftFolderName(const ADraft: string): string;
var
  LValue: string;
begin
  LValue := Trim(LowerCase(ADraft));
  if LValue = '' then
    Exit('');

  if StartsText('draft', LValue) then
    Result := LValue
  else
    Result := 'draft' + LValue;
end;

function ResolveDraftVersion(const ADraft: string): TDraftVersion;
var
  LValue: string;
begin
  LValue := Trim(LowerCase(ADraft));

  if (LValue = 'draft6') or (LValue = '6') then
    Exit(TDraftVersion.dvDraft6);

  if (LValue = 'draft7') or (LValue = '7') then
    Exit(TDraftVersion.dvDraft7);

  if (LValue = 'draft2019-09') or (LValue = '2019-09') then
    Exit(TDraftVersion.dvDraft2019_09);

  if (LValue = 'draft2020-12') or (LValue = '2020-12') then
    Exit(TDraftVersion.dvDraft2020_12);

  Result := TDraftVersion.dvUnknown;
end;

var
  GConsoleHandle: THandle;

function BuildBar(const APercent: Double; const AWidth: Integer): string;
var
  LPercent: Double;
  LFilled: Integer;
begin
  LPercent := EnsureRange(APercent, 0, 100);
  LFilled := Round((LPercent / 100) * AWidth);
  Result := '[' + StringOfChar('#', LFilled) + StringOfChar('-', AWidth - LFilled) + ']';
end;

procedure WriteAtLine(const ALine: SmallInt; const AText: string);
var
  LInfo: TConsoleScreenBufferInfo;
  LCoord: TCoord;
  LWritten: DWORD;
  LOutput: string;
begin
  if not GetConsoleScreenBufferInfo(GConsoleHandle, LInfo) then
    Exit;

  LCoord.X := 0;
  LCoord.Y := ALine;
  FillConsoleOutputCharacter(GConsoleHandle, ' ', LInfo.dwSize.X, LCoord, LWritten);
  SetConsoleCursorPosition(GConsoleHandle, LCoord);

  LOutput := AText;
  if Length(LOutput) > LInfo.dwSize.X then
    SetLength(LOutput, LInfo.dwSize.X);

  Write(LOutput);
end;

procedure RenderBars(const AProcessed, ATotal, APassed, AFailed: Integer);
var
  LInfo: TConsoleScreenBufferInfo;
  LGeneralPercent: Double;
  LPassPercent: Double;
  LRestore: TCoord;
begin
  if not GetConsoleScreenBufferInfo(GConsoleHandle, LInfo) then
    Exit;

  LRestore := LInfo.dwCursorPosition;

  if ATotal > 0 then
    LGeneralPercent := (AProcessed / ATotal) * 100
  else
    LGeneralPercent := 0;

  if AProcessed > 0 then
    LPassPercent := (APassed / AProcessed) * 100
  else
    LPassPercent := 100;

  WriteAtLine(0, Format('Progresso Geral: %s %6.2f%%  (%d/%d)', [BuildBar(LGeneralPercent, 30), LGeneralPercent, AProcessed, ATotal]));
  WriteAtLine(1, Format('Taxa de Sucesso: %s %6.2f%%  (OK=%d FALHAS=%d)', [BuildBar(LPassPercent, 30), LPassPercent, APassed, AFailed]));

  if LRestore.Y < 2 then
    LRestore.Y := 2;
  SetConsoleCursorPosition(GConsoleHandle, LRestore);
end;

procedure PrintFailure(const AFailure: TJsonSchemaFailure);
var
  LInfo: TConsoleScreenBufferInfo;
begin
  if GetConsoleScreenBufferInfo(GConsoleHandle, LInfo) and (LInfo.dwCursorPosition.Y < 2) then
  begin
    LInfo.dwCursorPosition.Y := 2;
    LInfo.dwCursorPosition.X := 0;
    SetConsoleCursorPosition(GConsoleHandle, LInfo.dwCursorPosition);
  end;

  Writeln;
  Writeln(Format('[FALHA] Draft: %s', [AFailure.DraftName]));
  Writeln(Format('Arquivo de teste: %s', [AFailure.FilePath]));
  Writeln(Format('Caso: %s', [AFailure.TestDescription]));
  Writeln(Format('Caminho do schema: %s', [AFailure.SchemaPath]));
  Writeln(Format('Caminho do valor: %s', [AFailure.InstancePath]));
  Writeln(Format('Erro: %s', [AFailure.ErrorMessage]));
  Writeln(Format('Esperado: %s | Obtido: %s', [BoolToStr(AFailure.ExpectedValid, True), BoolToStr(AFailure.ActualValid, True)]));
end;

function JsonEscape(const AValue: string): string;
begin
  Result := StringReplace(AValue, '\', '\\', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '\"', [rfReplaceAll]);
  Result := StringReplace(Result, #13#10, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '\n', [rfReplaceAll]);
end;

function ResolveReportPath(const AReportPath: string): string;
var
  LTrimmedPath: string;
  LRepoRootPath: string;
begin
  LTrimmedPath := Trim(AReportPath);
  if LTrimmedPath = '' then
    Exit('');

  if TPath.IsPathRooted(LTrimmedPath) then
    Exit(TPath.GetFullPath(LTrimmedPath));

  LRepoRootPath := TPath.GetFullPath(TPath.Combine(GetTestRootPath, '..'));
  Result := TPath.GetFullPath(TPath.Combine(LRepoRootPath, LTrimmedPath));
end;

procedure SaveFailureReport(const AFilePath: string; const AFailures: TList<TJsonSchemaFailure>);
var
  LLines: TStringList;
  LFailure: TJsonSchemaFailure;
  LIsJson: Boolean;
  LIndex: Integer;
  LDirectory: string;
begin
  if Trim(AFilePath) = '' then
    Exit;

  LDirectory := ExtractFilePath(AFilePath);
  if (LDirectory <> '') and not TDirectory.Exists(LDirectory) then
    TDirectory.CreateDirectory(LDirectory);

  LIsJson := SameText(ExtractFileExt(AFilePath), '.json');
  LLines := TStringList.Create;
  try
    if LIsJson then
    begin
      LLines.Add('[');
      for LIndex := 0 to AFailures.Count - 1 do
      begin
        LFailure := AFailures[LIndex];
        LLines.Add('  {');
        LLines.Add(Format('    "draft": "%s",', [JsonEscape(LFailure.DraftName)]));
        LLines.Add(Format('    "file": "%s",', [JsonEscape(LFailure.FilePath)]));
        LLines.Add(Format('    "test": "%s",', [JsonEscape(LFailure.TestDescription)]));
        LLines.Add(Format('    "schemaPath": "%s",', [JsonEscape(LFailure.SchemaPath)]));
        LLines.Add(Format('    "instancePath": "%s",', [JsonEscape(LFailure.InstancePath)]));
        LLines.Add(Format('    "error": "%s",', [JsonEscape(LFailure.ErrorMessage)]));
        LLines.Add(Format('    "expectedValid": %s,', [LowerCase(BoolToStr(LFailure.ExpectedValid, True))]));
        LLines.Add(Format('    "actualValid": %s', [LowerCase(BoolToStr(LFailure.ActualValid, True))]));
        if LIndex < AFailures.Count - 1 then
          LLines.Add('  },')
        else
          LLines.Add('  }');
      end;
      LLines.Add(']');
    end
    else
    begin
      for LFailure in AFailures do
      begin
        LLines.Add('[FALHA]');
        LLines.Add('Draft=' + LFailure.DraftName);
        LLines.Add('Arquivo=' + LFailure.FilePath);
        LLines.Add('Teste=' + LFailure.TestDescription);
        LLines.Add('SchemaPath=' + LFailure.SchemaPath);
        LLines.Add('InstancePath=' + LFailure.InstancePath);
        LLines.Add('Erro=' + LFailure.ErrorMessage);
        LLines.Add('Esperado=' + BoolToStr(LFailure.ExpectedValid, True));
        LLines.Add('Obtido=' + BoolToStr(LFailure.ActualValid, True));
        LLines.Add('');
      end;
    end;

    LLines.SaveToFile(AFilePath, TEncoding.UTF8);
  finally
    LLines.Free;
  end;
end;

var
  LDraftValue: string;
  LFileFilters: TArray<string>;
  LFileFilter: string;
  LReportFile: string;
  LQuiet: Boolean;
  LFailFast: Boolean;
  LResolvedReportFile: string;
  LServer: TFileServer;
  LTotal: Integer;
  LPassed: Integer;
  LFailed: Integer;
  LRunTotal: Integer;
  LRunPassed: Integer;
  LRunFailed: Integer;
  LFilterIndex: Integer;
  LFailures: TList<TJsonSchemaFailure>;

begin
  try
    GConsoleHandle := GetStdHandle(STD_OUTPUT_HANDLE);

    Writeln;
    Writeln;

    LDraftValue := GetSwitchValue('d');
    if LDraftValue = '' then
      LDraftValue := GetSwitchValue('draft');

    LFileFilters := GetSwitchValues('f', 'file');
    if Length(LFileFilters) = 0 then
      LFileFilters := TArray<string>.Create('');

    LReportFile := GetSwitchValue('r');
    if LReportFile = '' then
      LReportFile := GetSwitchValue('report');

    LQuiet := HasSwitch('quiet') or HasSwitch('q');
    LFailFast := HasSwitch('fail-fast') or HasSwitch('failfast');

    LFailures := TList<TJsonSchemaFailure>.Create;

    LServer := TFileServer.Create;
    try
      LServer.StartFileServer(1234);

      LTotal := 0;
      LPassed := 0;
      LFailed := 0;

      for LFilterIndex := 0 to High(LFileFilters) do
      begin
        LFileFilter := LFileFilters[LFilterIndex];
        if (Length(LFileFilters) > 1) and (not LQuiet) then
          Writeln(Format('Executando filtro --file=%s', [LFileFilter]));

        TJsonSchemaValidationTest.ExecuteForConsole(
          ResolveDraftFolderName(LDraftValue),
          LFileFilter,
          ResolveDraftVersion(LDraftValue),
          procedure(const AProcessed, ATotal, APassed, AFailed: Integer)
          begin
            if not LQuiet then
              RenderBars(AProcessed, ATotal, APassed, AFailed);
          end,
          procedure(const AFailure: TJsonSchemaFailure)
          begin
            LFailures.Add(AFailure);
            if not LQuiet then
              PrintFailure(AFailure);
          end,
          LRunTotal,
          LRunPassed,
          LRunFailed,
          LFailFast);

        Inc(LTotal, LRunTotal);
        Inc(LPassed, LRunPassed);
        Inc(LFailed, LRunFailed);

        if LFailFast and (LRunFailed > 0) then
          Break;
      end;

      if not LQuiet and (LTotal > 0) then
        RenderBars(LTotal, LTotal, LPassed, LFailed);

      Writeln;
      Writeln;
      Writeln(Format('Resumo: Total=%d, Passou=%d, Falhou=%d', [LTotal, LPassed, LFailed]));

      if LReportFile <> '' then
      begin
        LResolvedReportFile := ResolveReportPath(LReportFile);
        SaveFailureReport(LResolvedReportFile, LFailures);
        Writeln(Format('Relatorio salvo em: %s', [LResolvedReportFile]));
      end;

//      WriteLn('Pressione qualquer tecla para continuar...');
//      Readln;
    finally
      LServer.StopFileServer;
      LServer.Free;
      LFailures.Free;
    end;

    if LFailed > 0 then
      Halt(1);
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
