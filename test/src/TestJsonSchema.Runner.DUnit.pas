(*
--------------------------------------------------------------------------------
Core test case execution engine wrapping the official JSON Schema test suite with DUnit assertion hooks.
--------------------------------------------------------------------------------
*)

unit TestJsonSchema.Runner.DUnit;

interface

uses
  System.IOUtils,
  System.JSON,
  System.SysUtils,
  System.Generics.Collections,
  TestFramework,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Validator;

type
  /// <summary>
  /// DUnit test case execution class that maps JSON Schema Test Suite files into DUnit tests.
  /// </summary>
  TJsonSchemaValidationTest = class(TTestCase)
  strict private
    FSchema: TJSONValue;
    FData: TJSONValue;
    FDescription: string;
    FExpectedValid: Boolean;
    FFormatErrors: Boolean;
    FDraftVersion: TDraftVersion;

    function GetErrors(const pErrors: TArray<IValidationError>): string;
    class function ResolveTestFiles(const pRootPath, pFileFilter: string): TArray<string>;

    { SRP Methods for registering test trees }
    class procedure RegisterTestFile(const pSuite: ITestSuite; const pFilePath: string;
      const pDraftVersion: TDraftVersion);
    class procedure RegisterTestSet(const pSuite: ITestSuite; const pFilePath: string;
      const pSetObj: TJSONObject; const pDraftVersion: TDraftVersion);
    class procedure RegisterTestCase(const pSuite: ITestSuite; const pFilePath, pTestTitle: string;
      const pSchema: TJSONValue; const pTestObj: TJSONObject; const pDraftVersion: TDraftVersion);
  public
    destructor Destroy; override;

    { Fluent Builder }
    function Description(const pValue: string): TJsonSchemaValidationTest;
    function Schema(const pValue: string): TJsonSchemaValidationTest;
    function Data(const pValue: string): TJsonSchemaValidationTest;
    function ExpectedValid(const pValue: Boolean): TJsonSchemaValidationTest;
    function Name(const pValue: string): TJsonSchemaValidationTest;
    function FormatErrors(const pValue: Boolean): TJsonSchemaValidationTest;
    function DraftVersion(const pValue: TDraftVersion): TJsonSchemaValidationTest;

    { DUnit Registration API }
    class procedure RegisterDefaultDrafts;
    class procedure RegisterTestsFromDraft(const pDraft: string;
      const pDraftVersion: TDraftVersion = TDraftVersion.dvUnknown); overload;
    class procedure RegisterTestsFromDraft(const pDraft, pFileFilter: string;
      const pDraftVersion: TDraftVersion = TDraftVersion.dvUnknown); overload;
    class procedure RegisterTestsFromFile(const pFileFilter: string;
      const pDraftVersion: TDraftVersion = TDraftVersion.dvUnknown);
    class procedure RegisterTestsInFolder(var pSuite: ITestSuite; const pPath: string;
      const pDraftVersion: TDraftVersion; const pFileFilter: string = '');
  published
    procedure Run;
  end;

implementation

uses
  TestJsonSchema.Utils.Paths,
  TestJsonSchema.Utils.DraftResolver;

destructor TJsonSchemaValidationTest.Destroy;
begin
  FSchema.Free;
  FData.Free;
  inherited;
end;

function TJsonSchemaValidationTest.Description(const pValue: string): TJsonSchemaValidationTest;
begin
  FDescription := pValue;
  Result := Self;
end;

function TJsonSchemaValidationTest.Schema(const pValue: string): TJsonSchemaValidationTest;
begin
  FSchema := TJSONObject.ParseJSONValue(pValue);
  Result := Self;
end;

function TJsonSchemaValidationTest.Data(const pValue: string): TJsonSchemaValidationTest;
begin
  FData := TJSONObject.ParseJSONValue(pValue);
  Result := Self;
end;

function TJsonSchemaValidationTest.ExpectedValid(const pValue: Boolean): TJsonSchemaValidationTest;
begin
  FExpectedValid := pValue;
  Result := Self;
end;

function TJsonSchemaValidationTest.Name(const pValue: string): TJsonSchemaValidationTest;
begin
  FTestName := pValue;
  Result := Self;
end;

function TJsonSchemaValidationTest.FormatErrors(const pValue: Boolean): TJsonSchemaValidationTest;
begin
  FFormatErrors := pValue;
  Result := Self;
end;

function TJsonSchemaValidationTest.DraftVersion(const pValue: TDraftVersion): TJsonSchemaValidationTest;
begin
  FDraftVersion := pValue;
  Result := Self;
end;

function TJsonSchemaValidationTest.GetErrors(const pErrors: TArray<IValidationError>): string;
var
  lIndex: Integer;
begin
  Result := '';
  lIndex := 0;

  while lIndex < Length(pErrors) do
  begin
    Result := Result + pErrors[lIndex].Message + sLineBreak;
    Inc(lIndex);
  end;
end;

procedure TJsonSchemaValidationTest.Run;
var
  lValidator: TJsonSchemaValidator;
  lResult: IValidationResult;
  lMessage: string;
begin
  lValidator := TJsonSchemaValidator.Create;
  try
    lResult := lValidator.Validate(FSchema, FData, FDraftVersion);

    if lResult.IsValid <> FExpectedValid then
    begin
      lMessage := Format('Falha no teste: "%s" with schema: "%s". [Esperado: %s, Recebido: %s]. Erros: %s',
        [FDescription, FSchema.ToJSON, BoolToStr(FExpectedValid), BoolToStr(lResult.IsValid), GetErrors(lResult.Errors)]);
    end else
    begin
      lMessage := FDescription;
    end;

    Check(lResult.IsValid = FExpectedValid, lMessage);
  finally
    lValidator.Free;
  end;
end;

class function TJsonSchemaValidationTest.ResolveTestFiles(const pRootPath, pFileFilter: string): TArray<string>;
var
  lAllFiles: TArray<string>;
  lFile: string;
  lFiltered: TList<string>;
begin
  if pFileFilter = '' then
  begin
    lAllFiles := TDirectory.GetFiles(pRootPath, '*.json', TSearchOption.soAllDirectories);
  end else if TPath.IsPathRooted(pFileFilter) or (ExtractFilePath(pFileFilter) <> '') then
  begin
    lFile := TPath.GetFullPath(TPath.Combine(pRootPath, pFileFilter));
    if FileExists(lFile) then
    begin
      SetLength(Result, 1);
      Result[0] := lFile;
    end else
    begin
      SetLength(Result, 0);
    end;
    Exit;
  end else
  begin
    lAllFiles := TDirectory.GetFiles(pRootPath, TPath.GetFileName(pFileFilter), TSearchOption.soAllDirectories);
  end;

  lFiltered := TList<string>.Create;
  try
    for lFile in lAllFiles do
    begin
      if not (lFile.Contains('idn-hostname') or lFile.Contains('idn-email') or
              lFile.Contains('iri.json') or lFile.Contains('iri-reference') or
              lFile.Contains('cross-draft') or lFile.Contains('content.json')) then
      begin
        lFiltered.Add(lFile);
      end;
    end;
    Result := lFiltered.ToArray;
  finally
    lFiltered.Free;
  end;
end;

class procedure TJsonSchemaValidationTest.RegisterTestCase(const pSuite: ITestSuite;
  const pFilePath, pTestTitle: string; const pSchema: TJSONValue;
  const pTestObj: TJSONObject; const pDraftVersion: TDraftVersion);
var
  lData: TJSONValue;
  lDescription: string;
  lValid: Boolean;
begin
  if pTestObj.TryGetValue<TJSONValue>('data', lData) and
     pTestObj.TryGetValue<string>('description', lDescription) and
     pTestObj.TryGetValue<Boolean>('valid', lValid) then
  begin
    pSuite.AddTest(TJsonSchemaValidationTest.Create('Run')
      .Description(lDescription)
      .Schema(pSchema.ToJSON)
      .Data(lData.ToJSON)
      .ExpectedValid(lValid)
      .Name(lDescription)
      .FormatErrors(pFilePath.ToLower.Contains('format'))
      .DraftVersion(pDraftVersion));
  end;
end;

class procedure TJsonSchemaValidationTest.RegisterTestSet(const pSuite: ITestSuite;
  const pFilePath: string; const pSetObj: TJSONObject; const pDraftVersion: TDraftVersion);
var
  lSchema: TJSONValue;
  lTestArray: TJSONArray;
  lTestTitle: string;
  lTestSuite: ITestSuite;
  lTestIndex: Integer;
  lTestObj: TJSONObject;
begin
  if pSetObj.TryGetValue<TJSONValue>('schema', lSchema) and
     pSetObj.TryGetValue<TJSONArray>('tests', lTestArray) then
  begin
    if not pSetObj.TryGetValue<string>('description', lTestTitle) then
      lTestTitle := 'Set';

    lTestSuite := TTestSuite.Create(lTestTitle);
    lTestIndex := 0;

    while lTestIndex < lTestArray.Count do
    begin
      lTestObj := lTestArray.Items[lTestIndex] as TJSONObject;
      RegisterTestCase(lTestSuite, pFilePath, lTestTitle, lSchema, lTestObj, pDraftVersion);
      Inc(lTestIndex);
    end;

    pSuite.AddSuite(lTestSuite);
  end;
end;

class procedure TJsonSchemaValidationTest.RegisterTestFile(const pSuite: ITestSuite;
  const pFilePath: string; const pDraftVersion: TDraftVersion);
var
  lFileSuite: ITestSuite;
  lJsonRootArray: TJSONArray;
  lSetIndex: Integer;
  lSetObj: TJSONObject;
begin
  lFileSuite := TTestSuite.Create(ExtractFileName(pFilePath));
  pSuite.AddSuite(lFileSuite);

  lJsonRootArray := TJSONObject.ParseJSONValue(TFile.ReadAllText(pFilePath)) as TJSONArray;

  if Assigned(lJsonRootArray) then
  begin
    try
      lSetIndex := 0;
      while lSetIndex < lJsonRootArray.Count do
      begin
        lSetObj := lJsonRootArray.Items[lSetIndex] as TJSONObject;
        RegisterTestSet(lFileSuite, pFilePath, lSetObj, pDraftVersion);
        Inc(lSetIndex);
      end;
    finally
      lJsonRootArray.Free;
    end;
  end;
end;

class procedure TJsonSchemaValidationTest.RegisterTestsInFolder(var pSuite: ITestSuite;
  const pPath: string; const pDraftVersion: TDraftVersion; const pFileFilter: string);
var
  lFiles: TArray<string>;
  lFileIndex: Integer;
begin
  lFiles := ResolveTestFiles(pPath, pFileFilter);
  lFileIndex := 0;

  while lFileIndex < Length(lFiles) do
  begin
    RegisterTestFile(pSuite, lFiles[lFileIndex], pDraftVersion);
    Inc(lFileIndex);
  end;
end;

class procedure TJsonSchemaValidationTest.RegisterTestsFromDraft(const pDraft, pFileFilter: string;
  const pDraftVersion: TDraftVersion);
var
  lRootPath: string;
  lDraftPath: string;
  lMainSuite: ITestSuite;
begin
  lRootPath := GetSchemasTestsRootPath;
  lDraftPath := TPath.Combine(lRootPath, ResolveDraftFolderName(pDraft));

  if not TDirectory.Exists(lDraftPath) then
  begin
    Exit;
  end;

  lMainSuite := TTestSuite.Create(ResolveDraftFolderName(pDraft));
  RegisterTestsInFolder(lMainSuite, lDraftPath, pDraftVersion, pFileFilter);
  RegisterTest(lMainSuite);
end;

class procedure TJsonSchemaValidationTest.RegisterTestsFromDraft(const pDraft: string;
  const pDraftVersion: TDraftVersion);
begin
  RegisterTestsFromDraft(pDraft, '', pDraftVersion);
end;

class procedure TJsonSchemaValidationTest.RegisterTestsFromFile(const pFileFilter: string;
  const pDraftVersion: TDraftVersion);
begin
  RegisterTestsFromDraft('draft6', pFileFilter, TDraftVersion.dvDraft6);
  RegisterTestsFromDraft('draft7', pFileFilter, TDraftVersion.dvDraft7);
  RegisterTestsFromDraft('draft2019-09', pFileFilter, TDraftVersion.dvDraft2019_09);
  RegisterTestsFromDraft('draft2020-12', pFileFilter, TDraftVersion.dvDraft2020_12);
end;

class procedure TJsonSchemaValidationTest.RegisterDefaultDrafts;
begin
  RegisterTestsFromDraft('draft6', TDraftVersion.dvDraft6);
  RegisterTestsFromDraft('draft7', TDraftVersion.dvDraft7);
  RegisterTestsFromDraft('draft2019-09', TDraftVersion.dvDraft2019_09);
  // RegisterTestsFromDraft('draft2020-12', TDraftVersion.dvDraft2020_12);
end;

initialization
  TJsonSchemaValidationTest.RegisterDefaultDrafts;

end.
