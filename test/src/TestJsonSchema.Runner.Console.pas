unit TestJsonSchema.Runner.Console;

interface

uses
  System.Generics.Collections,
  System.IOUtils,
  System.JSON,
  System.StrUtils,
  System.SysUtils,
  JsonSchema,
  JsonSchema.Types,
  JsonSchema.Interfaces,
  TestJsonSchema.Types;

type
  TConsoleRunner = class
  strict private
    FTotal: Integer;
    FPassed: Integer;
    FFailed: Integer;
    FFailFast: Boolean;
    FStop: Boolean;
    FOnProgress: TJsonSchemaProgressCallback;
    FOnFailure: TJsonSchemaFailureCallback;

    function ResolveTestFiles(const pRootPath, pFileFilter: string): TArray<string>;

    { Fase 1: Contagem para inicialização correta das barras de progresso }
    procedure CountTestsInDraft(const pDraftPath, pFileFilter: string);
    procedure CountTestsInFile(const pFilePath: string);

    { Fase 2: Execução dos Testes }
    procedure RunDraft(const pDraftName: string; const pDraftVersion: TDraftVersion; const pDraftPath, pFileFilter: string);
    procedure RunFile(const pDraftName: string; const pDraftVersion: TDraftVersion; const pFilePath: string);
    procedure RunTestSet(const pDraftName: string; const pDraftVersion: TDraftVersion; const pFilePath: string; const pSetObj: TJSONObject);
    procedure RunTestCase(const pDraftName: string; const pDraftVersion: TDraftVersion; const pFilePath: string; const pSchema: TJSONValue;
      const pTestObj: TJSONObject);
    procedure ValidateTest(const pDraftName: string; const pDraftVersion: TDraftVersion; const pFilePath, pTestDescription: string;
      const pExpectedValid: Boolean; const pSchemaParsed, pDataParsed: TJSONValue);
    procedure BuildFailureAndNotify(const pDraftName, pFilePath, pTestDescription: string; const pExpectedValid: Boolean;
      const pResult: IValidationResult);
  public
    constructor Create(const pFailFast: Boolean; const pOnProgress: TJsonSchemaProgressCallback; const pOnFailure: TJsonSchemaFailureCallback);

    procedure Execute(const pDraft, pFileFilter: string; const pDraftVersion: TDraftVersion; out pTotal, pPassed, pFailed: Integer);
  end;

implementation

uses
  TestJsonSchema.Utils.Paths,
  TestJsonSchema.Utils.DraftResolver;

constructor TConsoleRunner.Create(const pFailFast: Boolean; const pOnProgress: TJsonSchemaProgressCallback;
  const pOnFailure: TJsonSchemaFailureCallback);
begin
  FTotal := 0;
  FPassed := 0;
  FFailed := 0;
  FFailFast := pFailFast;
  FStop := False;
  FOnProgress := pOnProgress;
  FOnFailure := pOnFailure;
end;

function TConsoleRunner.ResolveTestFiles(const pRootPath, pFileFilter: string): TArray<string>;
var
  lFilePath: string;
begin
  if pFileFilter = '' then
    Exit(TDirectory.GetFiles(pRootPath, '*.json', TSearchOption.soAllDirectories));

  if TPath.IsPathRooted(pFileFilter) or (ExtractFilePath(pFileFilter) <> '') then
  begin
    lFilePath := TPath.GetFullPath(TPath.Combine(pRootPath, pFileFilter));

    if FileExists(lFilePath) then
    begin
      SetLength(Result, 1);
      Result[0] := lFilePath;
    end else
    begin
      SetLength(Result, 0);
    end;
    Exit;
  end;

  Result := TDirectory.GetFiles(pRootPath, TPath.GetFileName(pFileFilter), TSearchOption.soAllDirectories);
end;

procedure TConsoleRunner.CountTestsInFile(const pFilePath: string);
var
  lJsonRootArray: TJSONArray;
  lSetObj: TJSONObject;
  lTestArray: TJSONArray;
  lSetIndex: Integer;
begin
  lJsonRootArray := TJSONObject.ParseJSONValue(TFile.ReadAllText(pFilePath)) as TJSONArray;

  if Assigned(lJsonRootArray) then
  begin
    try
      lSetIndex := 0;
      while lSetIndex < lJsonRootArray.Count do
      begin
        lSetObj := lJsonRootArray.Items[lSetIndex] as TJSONObject;

        if lSetObj.TryGetValue<TJSONArray>('tests', lTestArray) then
          Inc(FTotal, lTestArray.Count);

        Inc(lSetIndex);
      end;
    finally
      lJsonRootArray.Free;
    end;
  end;
end;

procedure TConsoleRunner.CountTestsInDraft(const pDraftPath, pFileFilter: string);
var
  lFiles: TArray<string>;
  lFileIndex: Integer;
begin
  lFiles := ResolveTestFiles(pDraftPath, pFileFilter);
  lFileIndex := 0;

  while lFileIndex < Length(lFiles) do
  begin
    CountTestsInFile(lFiles[lFileIndex]);
    Inc(lFileIndex);
  end;
end;

procedure TConsoleRunner.RunTestCase(const pDraftName: string; const pDraftVersion: TDraftVersion; const pFilePath: string;
  const pSchema: TJSONValue; const pTestObj: TJSONObject);
var
  lData: TJSONValue;
  lTestDescription: string;
  lValid: Boolean;
  lSchemaParsed: TJSONValue;
  lDataParsed: TJSONValue;
begin
  if pTestObj.TryGetValue<TJSONValue>('data', lData) and
    pTestObj.TryGetValue<string>('description', lTestDescription) and
    pTestObj.TryGetValue<Boolean>('valid', lValid) then
  begin
    lSchemaParsed := TJSONObject.ParseJSONValue(pSchema.ToJSON);
    if Assigned(lSchemaParsed) then
    begin
      try
        lDataParsed := TJSONObject.ParseJSONValue(lData.ToJSON);
        if Assigned(lDataParsed) then
        begin
          try
            ValidateTest(pDraftName, pDraftVersion, pFilePath, lTestDescription, lValid, lSchemaParsed, lDataParsed);
          finally
            lDataParsed.Free; // 1 recurso por finally, conforme a norma
          end;
        end;
      finally
        lSchemaParsed.Free; // 1 recurso por finally, conforme a norma
      end;
    end;
  end;
end;

procedure TConsoleRunner.RunTestSet(const pDraftName: string; const pDraftVersion: TDraftVersion; const pFilePath: string;
  const pSetObj: TJSONObject);
var
  lSchema: TJSONValue;
  lTestArray: TJSONArray;
  lTestIndex: Integer;
  lTestObj: TJSONObject;
begin
  if pSetObj.TryGetValue<TJSONValue>('schema', lSchema) and
    pSetObj.TryGetValue<TJSONArray>('tests', lTestArray) then
  begin
    lTestIndex := 0;
    while (not FStop) and (lTestIndex < lTestArray.Count) do
    begin
      lTestObj := lTestArray.Items[lTestIndex] as TJSONObject;
      RunTestCase(pDraftName, pDraftVersion, pFilePath, lSchema, lTestObj);
      Inc(lTestIndex);
    end;
  end;
end;

procedure TConsoleRunner.RunFile(const pDraftName: string; const pDraftVersion: TDraftVersion; const pFilePath: string);
var
  lJsonRootArray: TJSONArray;
  lSetIndex: Integer;
  lSetObj: TJSONObject;
begin
  lJsonRootArray := TJSONObject.ParseJSONValue(TFile.ReadAllText(pFilePath)) as TJSONArray;

  if Assigned(lJsonRootArray) then
  begin
    try
      lSetIndex := 0;
      while (not FStop) and (lSetIndex < lJsonRootArray.Count) do
      begin
        lSetObj := lJsonRootArray.Items[lSetIndex] as TJSONObject;
        RunTestSet(pDraftName, pDraftVersion, pFilePath, lSetObj);
        Inc(lSetIndex);
      end;
    finally
      lJsonRootArray.Free;
    end;
  end;
end;

procedure TConsoleRunner.RunDraft(const pDraftName: string; const pDraftVersion: TDraftVersion; const pDraftPath, pFileFilter: string);
var
  lFiles: TArray<string>;
  lFileIndex: Integer;
begin
  lFiles := ResolveTestFiles(pDraftPath, pFileFilter);
  lFileIndex := 0;

  while (not FStop) and (lFileIndex < Length(lFiles)) do
  begin
    RunFile(pDraftName, pDraftVersion, lFiles[lFileIndex]);
    Inc(lFileIndex);
  end;
end;

procedure TConsoleRunner.BuildFailureAndNotify(const pDraftName, pFilePath, pTestDescription: string; const pExpectedValid: Boolean;
  const pResult: IValidationResult);
var
  lFailure: TJsonSchemaFailure;
  lErrorIndex: Integer;
  lError: IError;
  lMessage: string;
begin
  if Assigned(FOnFailure) then
  begin
    lFailure.DraftName := pDraftName;
    lFailure.FilePath := ExtractFileName(pFilePath);
    lFailure.TestDescription := pTestDescription;
    lFailure.ExpectedValid := pExpectedValid;
    lFailure.ActualValid := pResult.IsValid;
    lFailure.SchemaPath := '#';
    lFailure.InstancePath := '#';
    lFailure.ErrorMessage := '';

    if Length(pResult.Errors) > 0 then
    begin
      lErrorIndex := 0;
      while lErrorIndex < Length(pResult.Errors) do
      begin
        lError := pResult.Errors[lErrorIndex];

        if (lFailure.SchemaPath = '#') and (Trim(lError.SchemaPath) <> '') then
          lFailure.SchemaPath := lError.SchemaPath;

        if (lFailure.InstancePath = '#') and (Trim(lError.InstancePath) <> '') then
          lFailure.InstancePath := lError.InstancePath;

        lMessage := Trim(lError.ErrorMessage);
        if lMessage <> '' then
        begin
          if lFailure.ErrorMessage <> '' then
            lFailure.ErrorMessage := lFailure.ErrorMessage + ' | ';
          lFailure.ErrorMessage := lFailure.ErrorMessage + lMessage;
        end;

        Inc(lErrorIndex);
      end;
    end;

    if lFailure.ErrorMessage = '' then
      lFailure.ErrorMessage := Format(
        'Validation mismatch without explicit error details (expected=%s, actual=%s).',
        [IfThen(pExpectedValid, 'True', 'False'), IfThen(pResult.IsValid, 'True', 'False')]);

    FOnFailure(lFailure);
  end;
end;

procedure TConsoleRunner.ValidateTest(const pDraftName: string; const pDraftVersion: TDraftVersion; const pFilePath, pTestDescription: string;
  const pExpectedValid: Boolean; const pSchemaParsed, pDataParsed: TJSONValue);
var
  lResult: IValidationResult;
begin
  lResult := TJsonSchema.Validate(pSchemaParsed, pDataParsed, pDraftVersion);

  if lResult.IsValid = pExpectedValid then
  begin
    Inc(FPassed);
  end else
  begin
    Inc(FFailed);
    BuildFailureAndNotify(pDraftName, pFilePath, pTestDescription, pExpectedValid, lResult);

    if FFailFast then
      FStop := True;
  end;

  if Assigned(FOnProgress) then
    FOnProgress(FPassed + FFailed, FTotal, FPassed, FFailed);
end;

procedure TConsoleRunner.Execute(const pDraft, pFileFilter: string; const pDraftVersion: TDraftVersion; out pTotal, pPassed, pFailed: Integer);
var
  lDrafts: TArray<string>;
  lDraftVersions: TArray<TDraftVersion>;
  lIndex: Integer;
  lRootPath: string;
  lDraftPath: string;
begin
  lRootPath := GetSchemasTestsRootPath;

  if Trim(pDraft) <> '' then
  begin
    SetLength(lDrafts, 1);
    SetLength(lDraftVersions, 1);
    lDrafts[0] := ResolveDraftFolderName(pDraft);

    if pDraftVersion <> TDraftVersion.dvUnknown then
      lDraftVersions[0] := pDraftVersion
    else
      lDraftVersions[0] := ResolveDraftVersion(pDraft);
  end else
  begin
    lDrafts := TArray<string>.Create('draft6', 'draft7', 'draft2019-09', 'draft2020-12');
    lDraftVersions := TArray<TDraftVersion>.Create(
      TDraftVersion.dvDraft6,
      TDraftVersion.dvDraft7,
      TDraftVersion.dvDraft2019_09,
      TDraftVersion.dvDraft2020_12);
  end;

  // Fase 1: Contagem
  lIndex := 0;
  while lIndex < Length(lDrafts) do
  begin
    lDraftPath := TPath.Combine(lRootPath, lDrafts[lIndex]);
    if TDirectory.Exists(lDraftPath) then
      CountTestsInDraft(lDraftPath, pFileFilter);
    Inc(lIndex);
  end;

  // Fase 2: Execução
  lIndex := 0;
  while (not FStop) and (lIndex < Length(lDrafts)) do
  begin
    lDraftPath := TPath.Combine(lRootPath, lDrafts[lIndex]);
    if TDirectory.Exists(lDraftPath) then
      RunDraft(lDrafts[lIndex], lDraftVersions[lIndex], lDraftPath, pFileFilter);
    Inc(lIndex);
  end;

  pTotal := FTotal;
  pPassed := FPassed;
  pFailed := FFailed;
end;

end.
