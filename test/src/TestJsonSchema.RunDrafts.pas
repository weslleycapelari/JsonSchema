unit TestJsonSchema.RunDrafts;

interface

uses
  TestFramework,
  System.SysUtils,
  System.StrUtils,
  System.IOUtils,
  System.Classes,
  System.JSON,
  System.Generics.Collections,
  JsonSchema,
  TestJsonSchema.Paths;

type
  TJsonSchemaFailure = record
    DraftName: string;
    FilePath: string;
    TestDescription: string;
    SchemaPath: string;
    InstancePath: string;
    ErrorMessage: string;
    ExpectedValid: Boolean;
    ActualValid: Boolean;
  end;

  TJsonSchemaProgressCallback = reference to procedure(const AProcessed, ATotal, APassed, AFailed: Integer);
  TJsonSchemaFailureCallback = reference to procedure(const AFailure: TJsonSchemaFailure);

  TJsonSchemaValidationTest = class(TTestCase)
  private
    FSchema: TJSONValue;
    FData: TJSONValue;
    FDescription: string;
    FExpectedValid: Boolean;
    FFormatErrors: Boolean;
    FDraftVersion: TDraftVersion;
    function GetErrors(const AErrors: TArray<IError>): string;
  public
    destructor Destroy; override;

    function Description(const AValue: string): TJsonSchemaValidationTest;
    function Schema(const AValue: string): TJsonSchemaValidationTest;
    function Data(const AValue: string): TJsonSchemaValidationTest;
    function ExpectedValid(const AValue: Boolean): TJsonSchemaValidationTest;
    function Name(const AValue: string): TJsonSchemaValidationTest;
    function FormatErrors(const AValue: Boolean): TJsonSchemaValidationTest;
    function DraftVersion(const AValue: TDraftVersion): TJsonSchemaValidationTest;

    class procedure RegisterDefaultDrafts;
    class procedure RegisterTestsFromDraft(const ADraft: string; const ADraftVersion: TDraftVersion = TDraftVersion.dvUnknown); overload;
    class procedure RegisterTestsFromDraft(const ADraft, AFileFilter: string;
      const ADraftVersion: TDraftVersion = TDraftVersion.dvUnknown); overload;
    class procedure RegisterTestsFromFile(const AFileFilter: string; const ADraftVersion: TDraftVersion = TDraftVersion.dvUnknown);
    class procedure RegisterTestsInFolder(var ASuite: ITestSuite; const APath: string; const ADraftVersion: TDraftVersion;
      const AFileFilter: string = '');

    class procedure ExecuteForConsole(const ADraft, AFileFilter: string; const ADraftVersion: TDraftVersion;
      const AOnProgress: TJsonSchemaProgressCallback; const AOnFailure: TJsonSchemaFailureCallback;
      out ATotal, APassed, AFailed: Integer; const AFailFast: Boolean = False);
  published
    procedure Run;
  end;

implementation

{ Helper Functions }

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

function ResolveTestFiles(const ARootPath, AFileFilter: string): TArray<string>;
var
  LFilePath: string;
begin
  if AFileFilter = '' then
    Exit(TDirectory.GetFiles(ARootPath, '*.json', TSearchOption.soAllDirectories));

  if TPath.IsPathRooted(AFileFilter) or (ExtractFilePath(AFileFilter) <> '') then
  begin
    LFilePath := TPath.GetFullPath(TPath.Combine(ARootPath, AFileFilter));
    if FileExists(LFilePath) then
    begin
      SetLength(Result, 1);
      Result[0] := LFilePath;
    end;
    Exit;
  end;
  Result := TDirectory.GetFiles(ARootPath, TPath.GetFileName(AFileFilter), TSearchOption.soAllDirectories);
end;

{ TJsonSchemaValidationTest }

destructor TJsonSchemaValidationTest.Destroy;
begin
  FSchema.Free;
  FData.Free;
  inherited;
end;

function TJsonSchemaValidationTest.Description(const AValue: string): TJsonSchemaValidationTest;
begin
  FDescription := AValue;
  Result := Self;
end;

function TJsonSchemaValidationTest.Schema(const AValue: string): TJsonSchemaValidationTest;
begin
  FSchema := TJSONObject.ParseJSONValue(AValue);
  Result := Self;
end;

function TJsonSchemaValidationTest.Data(const AValue: string): TJsonSchemaValidationTest;
begin
  FData := TJSONObject.ParseJSONValue(AValue);
  Result := Self;
end;

function TJsonSchemaValidationTest.ExpectedValid(const AValue: Boolean): TJsonSchemaValidationTest;
begin
  FExpectedValid := AValue;
  Result := Self;
end;

function TJsonSchemaValidationTest.Name(const AValue: string): TJsonSchemaValidationTest;
begin
  FTestName := AValue;
  Result := Self;
end;

function TJsonSchemaValidationTest.FormatErrors(const AValue: Boolean): TJsonSchemaValidationTest;
begin
  FFormatErrors := AValue;
  Result := Self;
end;

function TJsonSchemaValidationTest.DraftVersion(const AValue: TDraftVersion): TJsonSchemaValidationTest;
begin
  FDraftVersion := AValue;
  Result := Self;
end;

function TJsonSchemaValidationTest.GetErrors(const AErrors: TArray<IError>): string;
var
  LError: IError;
begin
  Result := '';
  for LError in AErrors do
    Result := Result + LError.ErrorMessage + sLineBreak;
end;

procedure TJsonSchemaValidationTest.Run;
var
  LResult: IValidationResult;
  LMessage: string;
begin
  LResult := TJsonSchema.Validate(FSchema, FData, FDraftVersion);

  if LResult.IsValid <> FExpectedValid then
    LMessage := Format('Falha no teste: "%s". [Esperado: %s, Recebido: %s]. Erros: %s',
      [FDescription, BoolToStr(FExpectedValid), BoolToStr(LResult.IsValid), GetErrors(LResult.Errors)])
  else
    LMessage := FDescription;

  Check(LResult.IsValid = FExpectedValid, LMessage);
end;

class procedure TJsonSchemaValidationTest.RegisterDefaultDrafts;
begin
  RegisterTestsFromDraft('draft6', TDraftVersion.dvDraft6);
  RegisterTestsFromDraft('draft7', TDraftVersion.dvDraft7);
  RegisterTestsFromDraft('draft2019-09', TDraftVersion.dvDraft2019_09);
  RegisterTestsFromDraft('draft2020-12', TDraftVersion.dvDraft2020_12);
end;

class procedure TJsonSchemaValidationTest.RegisterTestsFromDraft(const ADraft: string; const ADraftVersion: TDraftVersion);
begin
  RegisterTestsFromDraft(ADraft, '', ADraftVersion);
end;

class procedure TJsonSchemaValidationTest.RegisterTestsFromDraft(const ADraft, AFileFilter: string; const ADraftVersion: TDraftVersion);
var
  LRootPath, LDraftPath: string;
  LMainSuite: ITestSuite;
begin
  LRootPath := GetSchemasTestsRootPath;
  LDraftPath := TPath.Combine(LRootPath, ResolveDraftFolderName(ADraft));

  if not TDirectory.Exists(LDraftPath) then
    Exit;

  LMainSuite := TTestSuite.Create(ResolveDraftFolderName(ADraft));
  RegisterTestsInFolder(LMainSuite, LDraftPath, ADraftVersion, AFileFilter);
  RegisterTest(LMainSuite);
end;

class procedure TJsonSchemaValidationTest.RegisterTestsFromFile(const AFileFilter: string; const ADraftVersion: TDraftVersion);
begin
  RegisterTestsFromDraft('draft6', AFileFilter, TDraftVersion.dvDraft6);
  RegisterTestsFromDraft('draft7', AFileFilter, TDraftVersion.dvDraft7);
  RegisterTestsFromDraft('draft2019-09', AFileFilter, TDraftVersion.dvDraft2019_09);
  RegisterTestsFromDraft('draft2020-12', AFileFilter, TDraftVersion.dvDraft2020_12);
end;

class procedure TJsonSchemaValidationTest.RegisterTestsInFolder(var ASuite: ITestSuite; const APath: string; const ADraftVersion: TDraftVersion; const AFileFilter: string);
var
  LFileSuite, LTestSuite: ITestSuite;
  LFilePath, LJsonContent, LTestTitle, LRelativeName, LDescription: string;
  LJsonRootArray, LTestArray: TJSONArray;
  LSetIndex, LTestIndex: Integer;
  LSetObj, LTestObj: TJSONObject;
  LSchema, LData: TJSONValue;
  LValid: Boolean;
  LFiles: TArray<string>;
begin
  LFiles := ResolveTestFiles(APath, AFileFilter);
  for LFilePath in LFiles do
  begin
    LRelativeName := ChangeFileExt(ExtractRelativePath(APath, LFilePath), '');
    LFileSuite := TTestSuite.Create(LRelativeName);
    ASuite.AddSuite(LFileSuite);

    LJsonContent := TFile.ReadAllText(LFilePath);
    LJsonRootArray := TJSONObject.ParseJSONValue(LJsonContent) as TJSONArray;
    if not Assigned(LJsonRootArray) then Continue;
    try
      for LSetIndex := 0 to LJsonRootArray.Count - 1 do
      begin
        LSetObj := LJsonRootArray.Items[LSetIndex] as TJSONObject;

        if not LSetObj.TryGetValue<TJSONValue>('schema', LSchema) then
          Continue;

        if not LSetObj.TryGetValue<TJSONArray>('tests', LTestArray) then
          Continue;

        if not LSetObj.TryGetValue<string>('description', LTestTitle) then
          LTestTitle := 'Set ' + IntToStr(LSetIndex);

        LTestSuite := TTestSuite.Create(LTestTitle);
        for LTestIndex := 0 to LTestArray.Count - 1 do
        begin
          LTestObj := LTestArray.Items[LTestIndex] as TJSONObject;
          if LTestObj.TryGetValue<TJSONValue>('data', LData) and
             LTestObj.TryGetValue<string>('description', LDescription) and
             LTestObj.TryGetValue<Boolean>('valid', LValid) then
          begin
            LTestSuite.AddTest(TJsonSchemaValidationTest.Create('Run')
              .Description(LDescription)
              .Schema(LSchema.ToJSON)
              .Data(LData.ToJSON)
              .ExpectedValid(LValid)
              .Name(LDescription)
              .FormatErrors(LFilePath.ToLower.Contains('format'))
              .DraftVersion(ADraftVersion));
          end;
        end;
        LFileSuite.AddSuite(LTestSuite);
      end;
    finally
      LJsonRootArray.Free;
    end;
  end;
end;

class procedure TJsonSchemaValidationTest.ExecuteForConsole(const ADraft, AFileFilter: string;
  const ADraftVersion: TDraftVersion; const AOnProgress: TJsonSchemaProgressCallback;
  const AOnFailure: TJsonSchemaFailureCallback; out ATotal, APassed, AFailed: Integer;
  const AFailFast: Boolean);
var
  LDrafts: TArray<string>;
  LDraftVersions: TArray<TDraftVersion>;
  i, LSetIndex, LTestIndex: Integer;
  LRootPath, LDraftPath, LFilePath, LDescription: string;
  LFiles: TArray<string>;
  LJsonRootArray, LTestArray: TJSONArray;
  LSetObj, LTestObj: TJSONObject;
  LSchema, LData, LSchemaParsed, LDataParsed: TJSONValue;
  LValid, LStop: Boolean;
  LResult: IValidationResult;
  LFailure: TJsonSchemaFailure;
begin
  ATotal := 0;
  APassed := 0;
  AFailed := 0;
  LStop := False;

  LRootPath := GetSchemasTestsRootPath;

  { Setup Drafts to run }
  if ADraft <> '' then
  begin
    SetLength(LDrafts, 1); SetLength(LDraftVersions, 1);
    LDrafts[0] := ResolveDraftFolderName(ADraft);

    if ADraftVersion <> TDraftVersion.dvUnknown then
      LDraftVersions[0] := ADraftVersion
    else
      LDraftVersions[0] := ResolveDraftVersion(ADraft)
  end else
  begin
    LDrafts := TArray<string>.Create('draft6', 'draft7', 'draft2019-09', 'draft2020-12');
    LDraftVersions := TArray<TDraftVersion>.Create(
      TDraftVersion.dvDraft6,
      TDraftVersion.dvDraft7,
      TDraftVersion.dvDraft2019_09,
      TDraftVersion.dvDraft2020_12);
  end;

  { Pass 1: Count Total }
  for i := 0 to High(LDrafts) do
  begin
    LDraftPath := TPath.Combine(LRootPath, LDrafts[i]);

    if not TDirectory.Exists(LDraftPath) then
      Continue;

    LFiles := ResolveTestFiles(LDraftPath, AFileFilter);
    for LFilePath in LFiles do
    begin
      LJsonRootArray := TJSONObject.ParseJSONValue(TFile.ReadAllText(LFilePath)) as TJSONArray;
      if Assigned(LJsonRootArray) then
      try
        for LSetIndex := 0 to LJsonRootArray.Count - 1 do
        begin
          LSetObj := LJsonRootArray.Items[LSetIndex] as TJSONObject;

          if LSetObj.TryGetValue<TJSONArray>('tests', LTestArray) then
            Inc(ATotal, LTestArray.Count);
        end;
      finally
        LJsonRootArray.Free;
      end;
    end;
  end;

  { Pass 2: Execute }
  for i := 0 to High(LDrafts) do
  begin
    if LStop then
      Break;

    LDraftPath := TPath.Combine(LRootPath, LDrafts[i]);

    if not TDirectory.Exists(LDraftPath) then
      Continue;

    LFiles := ResolveTestFiles(LDraftPath, AFileFilter);
    for LFilePath in LFiles do
    begin
      if LStop then
        Break;

      LJsonRootArray := TJSONObject.ParseJSONValue(TFile.ReadAllText(LFilePath)) as TJSONArray;
      if Assigned(LJsonRootArray) then
      try
        for LSetIndex := 0 to LJsonRootArray.Count - 1 do
        begin
          if LStop then
            Break;

          LSetObj := LJsonRootArray.Items[LSetIndex] as TJSONObject;

          if not LSetObj.TryGetValue<TJSONValue>('schema', LSchema) then
            Continue;

          if not LSetObj.TryGetValue<TJSONArray>('tests', LTestArray) then
            Continue;

          for LTestIndex := 0 to LTestArray.Count - 1 do
          begin
            if LStop then
              Break;

            LTestObj := LTestArray.Items[LTestIndex] as TJSONObject;
            if LTestObj.TryGetValue<TJSONValue>('data', LData) and
               LTestObj.TryGetValue<string>('description', LDescription) and
               LTestObj.TryGetValue<Boolean>('valid', LValid) then
            begin
              LSchemaParsed := TJSONObject.ParseJSONValue(LSchema.ToJSON);
              LDataParsed := TJSONObject.ParseJSONValue(LData.ToJSON);
              try
                LResult := TJsonSchema.Validate(LSchemaParsed, LDataParsed, LDraftVersions[i]);

                if LResult.IsValid = LValid then
                  Inc(APassed)
                else
                begin
                  Inc(AFailed);
                  if Assigned(AOnFailure) then
                  begin
                    LFailure.DraftName := LDrafts[i];
                    LFailure.FilePath := ExtractFileName(LFilePath);
                    LFailure.TestDescription := LDescription;
                    LFailure.ExpectedValid := LValid;
                    LFailure.ActualValid := LResult.IsValid;

                    if Length(LResult.Errors) > 0 then
                    begin
                      LFailure.SchemaPath := LResult.Errors[0].SchemaPath;
                      LFailure.InstancePath := LResult.Errors[0].InstancePath;
                      LFailure.ErrorMessage := LResult.Errors[0].ErrorMessage;
                    end
                    else
                      LFailure.ErrorMessage := 'No details';

                    AOnFailure(LFailure);
                  end;
                  if AFailFast then LStop := True;
                end;
              finally
                LSchemaParsed.Free;
                LDataParsed.Free;
              end;

              if Assigned(AOnProgress) then
                AOnProgress(APassed + AFailed, ATotal, APassed, AFailed);
            end;
          end;
        end;
      finally
        LJsonRootArray.Free;
      end;
    end;
  end;
end;

end.
