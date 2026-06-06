unit VisualTestSuiteRunner.Runner;

(*
--------------------------------------------------------------------------------
VisualTestSuiteRunner CLI Runner orchestrator.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.JSON,
  VisualTestSuiteRunner.Config, VisualTestSuiteRunner.Engine;

/// <summary>Orchestrates test suite execution via CLI.</summary>
function RunTestSuiteRunner: Integer;

implementation

procedure ShowHelpMessage;
begin
  Writeln('VisualTestSuiteRunner - JSON Schema Test Suite Compliance Runner');
  Writeln('Executes official JSON Schema Test Suite files and displays compliance reports.');
  Writeln;
  Writeln('Usage:');
  Writeln('  VisualTestSuiteRunnerCLI.exe -i <suite_dir> [-d <draft>] [-o <output_json>] [--quiet]');
  Writeln;
  Writeln('Options:');
  Writeln('  -i, --input     Path to the directory containing official JSON test cases (required)');
  Writeln('  -d, --draft     Draft specification version to run (default: 2020-12)');
  Writeln('  -o, --output    Path to export the final JSON compliance report');
  Writeln('  --quiet         Suppress individual test file stdout logging');
  Writeln('  -h, --help      Display this help documentation');
  Writeln;
end;

function RunTestSuiteRunner: Integer;
var
  lConfig: TTestSuiteRunnerConfig;
  lRunner: TTestSuiteRunner;
  lTotalTests: Integer;
  lTotalPassed: Integer;
  lTotalFailed: Integer;
  lCompliance: Double;
  lFileRes: TTestFileResult;
  lFileCompliance: Double;
  lReportObj: TJSONObject;
  lFilesArr: TJSONArray;
  lFileObj: TJSONObject;
  lOutputText: string;
begin
  lConfig := ParseCommandLine;

  if lConfig.ShowHelp or (lConfig.InputPath = '') then
  begin
    ShowHelpMessage;
    Exit(0);
  end;

  if not DirectoryExists(lConfig.InputPath) then
  begin
    Writeln(ErrOutput, 'Error: Test suite input directory does not exist at: ' + lConfig.InputPath);
    Exit(1);
  end;

  lRunner := TTestSuiteRunner.Create(lConfig.DraftVersion);
  try
    if not lConfig.Quiet then
      Writeln(Format('Running test suite for Draft %s...', [lConfig.DraftVersion]));

    lRunner.RunTestSuite(lConfig.InputPath);

    lTotalTests := 0;
    lTotalPassed := 0;

    for lFileRes in lRunner.SuiteResults do
    begin
      lTotalTests := lTotalTests + lFileRes.TotalTests;
      lTotalPassed := lTotalPassed + lFileRes.PassCount;

      if not lConfig.Quiet then
      begin
        lFileCompliance := 0.0;
        if lFileRes.TotalTests > 0 then
          lFileCompliance := (lFileRes.PassCount / lFileRes.TotalTests) * 100.0;

        Writeln(Format('  %-30s: %d/%d passed (%5.1f%% compliance)', [
          lFileRes.FileName,
          lFileRes.PassCount,
          lFileRes.TotalTests,
          lFileCompliance
        ]));
      end;
    end;

    lTotalFailed := lTotalTests - lTotalPassed;
    lCompliance := 0.0;
    if lTotalTests > 0 then
      lCompliance := (lTotalPassed / lTotalTests) * 100.0;

    Writeln;
    Writeln('================================================================================');
    Writeln('TEST SUITE RESUME');
    Writeln('================================================================================');
    Writeln(Format('Total Tests Run : %d', [lTotalTests]));
    Writeln(Format('Passed          : %d', [lTotalPassed]));
    Writeln(Format('Failed          : %d', [lTotalFailed]));
    Writeln(Format('Compliance Rate : %5.2f%%', [lCompliance]));
    Writeln('================================================================================');

    // 1. Export compliance report if path is set
    if lConfig.OutputPath <> '' then
    begin
      lReportObj := TJSONObject.Create;
      try
        lReportObj.AddPair('draft', lConfig.DraftVersion);
        lReportObj.AddPair('totalTests', TJSONNumber.Create(lTotalTests));
        lReportObj.AddPair('passed', TJSONNumber.Create(lTotalPassed));
        lReportObj.AddPair('failed', TJSONNumber.Create(lTotalFailed));
        lReportObj.AddPair('complianceRate', TJSONNumber.Create(lCompliance));

        lFilesArr := TJSONArray.Create;
        for lFileRes in lRunner.SuiteResults do
        begin
          lFileObj := TJSONObject.Create;
          lFileObj.AddPair('name', lFileRes.FileName);
          lFileObj.AddPair('totalTests', TJSONNumber.Create(lFileRes.TotalTests));
          lFileObj.AddPair('passed', TJSONNumber.Create(lFileRes.PassCount));
          lFileObj.AddPair('failed', TJSONNumber.Create(lFileRes.TotalTests - lFileRes.PassCount));
          
          lFileCompliance := 0.0;
          if lFileRes.TotalTests > 0 then
            lFileCompliance := (lFileRes.PassCount / lFileRes.TotalTests) * 100.0;
          lFileObj.AddPair('complianceRate', TJSONNumber.Create(lFileCompliance));
          
          lFilesArr.AddElement(lFileObj);
        end;
        lReportObj.AddPair('files', lFilesArr);

        lOutputText := lReportObj.Format(2);
        try
          TFile.WriteAllText(lConfig.OutputPath, lOutputText, TEncoding.UTF8);
        except
          on E: Exception do
            Writeln(ErrOutput, 'Error writing output file: ' + E.Message);
        end;
      finally
        lReportObj.Free;
      end;
    end;

    // Exit with code 0 if all tests passed, 1 otherwise
    if lTotalFailed = 0 then
      Result := 0
    else
      Result := 1;

  finally
    lRunner.Free;
  end;
end;

end.
