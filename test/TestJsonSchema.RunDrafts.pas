unit TestJsonSchema.RunDrafts;

interface

uses
  TestFramework,
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  System.JSON,
  System.Generics.Collections,
  JsonSchema;

type
  { TJsonSchemaValidationTest
    Esta classe representa um ÚNICO caso de teste de validação.
    Ela é instanciada para cada objeto dentro do array "tests" nos seus arquivos JSON.
    Recebe o schema, os dados, a descrição e o resultado esperado em seu construtor. }
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

    class procedure RegisterTestsFromDraft(const ADraft: string; const ADraftVersion: TDraftVersion = TDraftVersion.dvUnknown);
    class procedure RegisterTestesInFolder(var ASuite: ITestSuite; const APath: string; const ADraftVersion: TDraftVersion);
  published
    procedure Run;
  end;

implementation

{ TJsonSchemaValidationTest }

destructor TJsonSchemaValidationTest.Destroy;
begin
  // Liberamos as cópias dos objetos JSON que criamos
  FSchema.Free;
  FData.Free;
  inherited;
end;

function TJsonSchemaValidationTest.DraftVersion(const AValue: TDraftVersion): TJsonSchemaValidationTest;
begin
  Result := Self;
  FDraftVersion := AValue;
end;

function TJsonSchemaValidationTest.GetErrors(const AErrors: TArray<IError>): string;
var
  LError: IError;
begin
  for LError in AErrors do
    Result := Result + LError.ErrorMessage + #13;
end;

procedure TJsonSchemaValidationTest.Run;
var
  LResult: IValidationResult;
  LMessage: string;
begin
  LResult := TJsonSchema.Validate(FSchema, FData, FDraftVersion);

  // Criamos uma mensagem de erro detalhada para facilitar o debug
  if LResult.IsValid <> FExpectedValid then
  begin
    LMessage := Format('Falha no teste: "%s". [Esperado: %s, Recebido: %s]. Erros: %s',
      [FDescription, BoolToStr(FExpectedValid), BoolToStr(LResult.IsValid), GetErrors(LResult.Errors)]);
  end
  else
  begin
    LMessage := FDescription;
  end;

  // A função Check faz a asserção. Se o primeiro parâmetro for False, o teste falha.
  Check(LResult.IsValid = FExpectedValid, LMessage);
end;

function TJsonSchemaValidationTest.Description(const AValue: string): TJsonSchemaValidationTest;
begin
  Result := Self;
  FDescription := AValue;
end;

function TJsonSchemaValidationTest.Schema(const AValue: string): TJsonSchemaValidationTest;
begin
  Result := Self;
  FSchema := TJSONObject.ParseJSONValue(AValue);
end;

function TJsonSchemaValidationTest.Data(const AValue: string): TJsonSchemaValidationTest;
begin
  Result := Self;
  FData := TJSONObject.ParseJSONValue(AValue);
end;

function TJsonSchemaValidationTest.ExpectedValid(const AValue: Boolean): TJsonSchemaValidationTest;
begin
  Result := Self;
  FExpectedValid := AValue;
end;

function TJsonSchemaValidationTest.FormatErrors(const AValue: Boolean): TJsonSchemaValidationTest;
begin
  Result := Self;
  FFormatErrors := AValue;
end;

function TJsonSchemaValidationTest.Name(const AValue: string): TJsonSchemaValidationTest;
begin
  Result := Self;
  Self.FTestName := AValue;
end;

class procedure TJsonSchemaValidationTest.RegisterTestesInFolder(var ASuite: ITestSuite; const APath: string;
  const ADraftVersion: TDraftVersion);
var
  LFileSuite: ITestSuite;
  LTestSuite: ITestSuite;
  LFilePath: string;
  LJsonContent: string;
  LJsonRootArray: TJSONArray;
  LSetIndex, LTestIndex: Integer;
  LSetObj: TJSONObject;
  LTestTitle: string;
  LTestArray: TJSONArray;
  LTestObj: TJSONObject;
  LSchema: TJSONValue;
  LData: TJSONValue;
  LDescription: string;
  LValid: Boolean;
begin
  // 1. Busca recursivamente todos os arquivos .json
  for LFilePath in TDirectory.GetFiles(APath, '*.json', TSearchOption.soTopDirectoryOnly) do
  begin
    // 2. Cria um Sub-Suite para cada arquivo encontrado
    LFileSuite := TTestSuite.Create(LFilePath.Replace(APath + '\', '').Replace('.json', ''));
    ASuite.AddSuite(LFileSuite);

    LJsonContent := TFile.ReadAllText(LFilePath);
    // Usamos um try-finally para garantir que o objeto JSON parseado seja liberado
    LJsonRootArray := TJSONObject.ParseJSONValue(LJsonContent) as TJSONArray;
    try
      // 3. Itera sobre os conjuntos de teste no arquivo
      for LSetIndex := 0 to LJsonRootArray.Count - 1 do
      begin
        LSetObj := LJsonRootArray.Items[LSetIndex] as TJSONObject;

        if not LSetObj.TryGetValue<TJSONValue>('schema', LSchema) then
          Continue; // Ou lance uma exceção, se preferir

        if not LSetObj.TryGetValue<TJSONArray>('tests', LTestArray) then
          Continue;

        if not LSetObj.TryGetValue<string>('description', LTestTitle) then
          Continue;

        LTestSuite := TTestSuite.Create(LTestTitle);

        // 4. Itera sobre cada teste individual dentro do conjunto
        for LTestIndex := 0 to LTestArray.Count - 1 do
        begin
          LTestObj := LTestArray.Items[LTestIndex] as TJSONObject;

          if (not LTestObj.TryGetValue<TJSONValue>('data', LData)) or
             (not LTestObj.TryGetValue<string>('description', LDescription)) or
             (not LTestObj.TryGetValue<Boolean>('valid', LValid)) then
            Continue;

          // 5. Instancia a classe de teste com os dados e adiciona ao suite do arquivo
          LTestSuite.AddTest(TJsonSchemaValidationTest.Create('Run')
            .Description(LDescription)
            .Schema(LSchema.ToJSON)
            .Data(LData.ToJSON)
            .ExpectedValid(LValid)
            .Name(LDescription)
            .FormatErrors(TPath.GetDirectoryName(LFilePath).ToLower.EndsWith('format'))
            .DraftVersion(ADraftVersion));
        end;

        LFileSuite.AddSuite(LTestSuite);
      end;
    finally
      LJsonRootArray.Free;
    end;
  end;

//  for LFilePath in TDirectory.GetDirectories(APath, '*', TSearchOption.soTopDirectoryOnly) do
//  begin
//    LFileSuite := TTestSuite.Create(LFilePath.Replace(APath + '\', ''));
//    RegisterTestesInFolder(LFileSuite, LFilePath, ADraftVersion);
//    ASuite.AddSuite(LFileSuite);
//  end;
end;

class procedure TJsonSchemaValidationTest.RegisterTestsFromDraft(const ADraft: string; const ADraftVersion: TDraftVersion);
var
  LRootPath: string;
  LDraftPath: string;
  LMainSuite: ITestSuite;
begin
  LRootPath := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..', 'schemas/tests'));
  LDraftPath := TPath.Combine(LRootPath, ADraft);

  if not TDirectory.Exists(LDraftPath) then
    raise Exception.CreateFmt('O caminho do draft não existe: %s', [LDraftPath]);

  // 1. Cria um Suite principal para organizar todos os testes deste draft
  LMainSuite := TTestSuite.Create(ADraft);

  // 2. Busca recursivamente todos os arquivos .json
  RegisterTestesInFolder(LMainSuite, LDraftPath, ADraftVersion);

  // Registra o Suite principal, que contém todos os outros, no DUnit
  RegisterTest(LMainSuite);
end;

initialization
//  TJsonSchemaValidationTest.RegisterTestsFromDraft('draft3');
//  TJsonSchemaValidationTest.RegisterTestsFromDraft('draft4');
  TJsonSchemaValidationTest.RegisterTestsFromDraft('draft6', TDraftVersion.dvDraft6);
  TJsonSchemaValidationTest.RegisterTestsFromDraft('draft7', TDraftVersion.dvDraft7);
  TJsonSchemaValidationTest.RegisterTestsFromDraft('draft2019-09', TDraftVersion.dvDraft2019_09);
  TJsonSchemaValidationTest.RegisterTestsFromDraft('draft2020-12', TDraftVersion.dvDraft2020_12);
//  TJsonSchemaValidationTest.RegisterTestsFromDraft('draft-next');

end.
