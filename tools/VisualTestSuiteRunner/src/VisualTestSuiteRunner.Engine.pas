unit VisualTestSuiteRunner.Engine;

(*
--------------------------------------------------------------------------------
VisualTestSuiteRunner engine. Loads local JSON Schema Test Suite files,
compiles schemas, executes cases, and collects statistical reports.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Generics.Collections, System.IOUtils,
  JsonSchema.Core.Interfaces, JsonSchema.Validator, JsonSchema.Localization.Enums;

type
  /// <summary>Result container for a single JSON Schema test case.</summary>
  TTestCaseResult = record
    Description: string;
    DataJSON: string;
    ExpectedValid: Boolean;
    ActualValid: Boolean;
    Passed: Boolean;
    ErrorMessage: string;
  end;

  /// <summary>Result container for a group of tests sharing the same schema.</summary>
  TTestGroupResult = class
  private
    FDescription: string;
    FSchemaJSON: string;
    FCases: TList<TTestCaseResult>;
  public
    constructor Create(const pDescription: string; const pSchemaJSON: string);
    destructor Destroy; override;
    
    property Description: string read FDescription;
    property SchemaJSON: string read FSchemaJSON;
    property Cases: TList<TTestCaseResult> read FCases;
  end;

  /// <summary>Result container representing a single JSON test file containing groups.</summary>
  TTestFileResult = class
  private
    FFileName: string;
    FGroups: TObjectList<TTestGroupResult>;
    FTotalTests: Integer;
    FPassCount: Integer;
  public
    constructor Create(const pFileName: string);
    destructor Destroy; override;
    
    property FileName: string read FFileName;
    property Groups: TObjectList<TTestGroupResult> read FGroups;
    property TotalTests: Integer read FTotalTests write FTotalTests;
    property PassCount: Integer read FPassCount write FPassCount;
  end;

  /// <summary>Orchestrator class for running JSON Schema Test Suite suites.</summary>
  TTestSuiteRunner = class
  private
    FDraftVersionStr: string;
    FDraft: TDraftVersion;
    FSuiteResults: TObjectList<TTestFileResult>;
    
    procedure RunFile(const pFilePath: string; pFileResult: TTestFileResult);
    function ParseDraftVersion(const pDraftStr: string): TDraftVersion;
  public
    constructor Create(const pDraftVersion: string);
    destructor Destroy; override;

    /// <summary>Scans the directory for json test files and runs them.</summary>
    procedure RunTestSuite(const pDirectoryPath: string);
    
    property SuiteResults: TObjectList<TTestFileResult> read FSuiteResults;
    property Draft: TDraftVersion read FDraft;
    property DraftVersionStr: string read FDraftVersionStr;
  end;

implementation

{ TTestGroupResult }

constructor TTestGroupResult.Create(const pDescription: string; const pSchemaJSON: string);
begin
  inherited Create;
  FDescription := pDescription;
  FSchemaJSON := pSchemaJSON;
  FCases := TList<TTestCaseResult>.Create;
end;

destructor TTestGroupResult.Destroy;
begin
  FCases.Free;
  inherited Destroy;
end;

{ TTestFileResult }

constructor TTestFileResult.Create(const pFileName: string);
begin
  inherited Create;
  FFileName := pFileName;
  FGroups := TObjectList<TTestGroupResult>.Create(True);
  FTotalTests := 0;
  FPassCount := 0;
end;

destructor TTestFileResult.Destroy;
begin
  FGroups.Free;
  inherited Destroy;
end;

{ TTestSuiteRunner }

constructor TTestSuiteRunner.Create(const pDraftVersion: string);
begin
  inherited Create;
  FDraftVersionStr := pDraftVersion;
  FDraft := ParseDraftVersion(pDraftVersion);
  FSuiteResults := TObjectList<TTestFileResult>.Create(True);
end;

destructor TTestSuiteRunner.Destroy;
begin
  FSuiteResults.Free;
  inherited Destroy;
end;

function TTestSuiteRunner.ParseDraftVersion(const pDraftStr: string): TDraftVersion;
var
  lNormalized: string;
begin
  lNormalized := LowerCase(pDraftStr);
  if (lNormalized = '2020-12') or (lNormalized = 'draft2020-12') or (lNormalized = 'dv2020_12') or (lNormalized = '2020_12') then
    Result := TDraftVersion.dvDraft2020_12
  else if (lNormalized = '2019-09') or (lNormalized = 'draft2019-09') or (lNormalized = 'dv2019_09') or (lNormalized = '2019_09') then
    Result := TDraftVersion.dvDraft2019_09
  else if (lNormalized = '7') or (lNormalized = 'draft7') or (lNormalized = 'dv7') or (lNormalized = 'draft-07') then
    Result := TDraftVersion.dvDraft7
  else if (lNormalized = '6') or (lNormalized = 'draft6') or (lNormalized = 'dv6') or (lNormalized = 'draft-06') then
    Result := TDraftVersion.dvDraft6
  else
    Result := TDraftVersion.dvDraft2020_12; // default
end;

procedure TTestSuiteRunner.RunFile(const pFilePath: string; pFileResult: TTestFileResult);
var
  lContent: string;
  lJSONVal: TJSONValue;
  lGroupsArr: TJSONArray;
  lI, lJ: Integer;
  lGroupVal: TJSONValue;
  lGroupObj: TJSONObject;
  lGroupDesc: string;
  lSchemaVal: TJSONValue;
  lTestsArr: TJSONArray;
  lTestVal: TJSONValue;
  lTestObj: TJSONObject;
  lTestDesc: string;
  lDataVal: TJSONValue;
  lExpected: Boolean;
  lValidator: TJsonSchemaValidator;
  lResult: IValidationResult;
  lGroupResult: TTestGroupResult;
  lCaseResult: TTestCaseResult;
  lPassed: Boolean;
  lErr: IValidationError;
  lErrMsgs: string;
begin
  try
    lContent := TFile.ReadAllText(pFilePath, TEncoding.UTF8);
  except
    on E: Exception do
      Exit;
  end;

  lJSONVal := TJSONObject.ParseJSONValue(lContent);
  if not Assigned(lJSONVal) or not (lJSONVal is TJSONArray) then
  begin
    if Assigned(lJSONVal) then
      lJSONVal.Free;
    Exit;
  end;

  lGroupsArr := TJSONArray(lJSONVal);
  try
    for lI := 0 to lGroupsArr.Count - 1 do
    begin
      lGroupVal := lGroupsArr.Items[lI];
      if lGroupVal is TJSONObject then
      begin
        lGroupObj := TJSONObject(lGroupVal);
        lGroupDesc := '';
        if Assigned(lGroupObj.Values['description']) then
          lGroupDesc := lGroupObj.Values['description'].Value;

        lSchemaVal := lGroupObj.Values['schema'];
        lTestsArr := nil;
        if Assigned(lGroupObj.Values['tests']) and (lGroupObj.Values['tests'] is TJSONArray) then
          lTestsArr := lGroupObj.Values['tests'] as TJSONArray;

        if Assigned(lSchemaVal) and Assigned(lTestsArr) then
        begin
          lGroupResult := TTestGroupResult.Create(lGroupDesc, lSchemaVal.Format(2));
          pFileResult.Groups.Add(lGroupResult);

          for lJ := 0 to lTestsArr.Count - 1 do
          begin
            lTestVal := lTestsArr.Items[lJ];
            if lTestVal is TJSONObject then
            begin
              lTestObj := TJSONObject(lTestVal);
              lTestDesc := '';
              if Assigned(lTestObj.Values['description']) then
                lTestDesc := lTestObj.Values['description'].Value;

              lDataVal := lTestObj.Values['data'];
              lExpected := lTestObj.Values['valid'] is TJSONTrue;

              if Assigned(lDataVal) then
              begin
                lValidator := TJsonSchemaValidator.Create(TLocale.EnUS);
                try
                  lValidator.EnforceFormats := True;
                  lPassed := False;
                  lErrMsgs := '';
                  lResult := nil;
                  try
                    lResult := lValidator.Validate(lSchemaVal, lDataVal, FDraft);
                    if lResult.IsValid = lExpected then
                    begin
                      lPassed := True;
                    end
                    else
                    begin
                      if not lResult.IsValid then
                      begin
                        for lErr in lResult.Errors do
                        begin
                          if lErrMsgs <> '' then
                            lErrMsgs := lErrMsgs + '; ';
                          lErrMsgs := lErrMsgs + lErr.Keyword + ': ' + lErr.Message;
                        end;
                      end
                      else
                      begin
                        lErrMsgs := 'Schema validated data successfully but validation was expected to FAIL.';
                      end;
                    end;
                  except
                    on E: Exception do
                    begin
                      lPassed := (lExpected = False);
                      lErrMsgs := 'Validator crashed: ' + E.Message;
                    end;
                  end;

                  lCaseResult.Description := lTestDesc;
                  lCaseResult.DataJSON := lDataVal.Format(2);
                  lCaseResult.ExpectedValid := lExpected;
                  
                  if Assigned(lResult) then
                    lCaseResult.ActualValid := lResult.IsValid
                  else
                    lCaseResult.ActualValid := False;

                  lCaseResult.Passed := lPassed;
                  lCaseResult.ErrorMessage := lErrMsgs;

                  lGroupResult.Cases.Add(lCaseResult);
                  pFileResult.TotalTests := pFileResult.TotalTests + 1;
                  if lPassed then
                    pFileResult.PassCount := pFileResult.PassCount + 1;
                finally
                  lValidator.Free;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
  finally
    lGroupsArr.Free;
  end;
end;

procedure TTestSuiteRunner.RunTestSuite(const pDirectoryPath: string);
var
  lFiles: TArray<string>;
  lFilePath: string;
  lFileResult: TTestFileResult;
begin
  FSuiteResults.Clear;
  if not DirectoryExists(pDirectoryPath) then
    Exit;

  lFiles := TDirectory.GetFiles(pDirectoryPath, '*.json', TSearchOption.soTopDirectoryOnly);
  for lFilePath in lFiles do
  begin
    lFileResult := TTestFileResult.Create(ExtractFileName(lFilePath));
    try
      RunFile(lFilePath, lFileResult);
      // Only add to results if the file actually contained test groups/cases
      if lFileResult.TotalTests > 0 then
      begin
        FSuiteResults.Add(lFileResult);
      end
      else
      begin
        lFileResult.Free;
      end;
    except
      lFileResult.Free;
    end;
  end;
end;

end.
