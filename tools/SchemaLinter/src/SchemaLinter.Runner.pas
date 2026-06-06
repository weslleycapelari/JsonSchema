unit SchemaLinter.Runner;

(*
--------------------------------------------------------------------------------
SchemaLinter CLI Runner orchestrator.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.JSON,
  SchemaLinter.Config, SchemaLinter.Engine;

/// <summary>Orchestrates static analysis validation of JSON Schema via CLI.</summary>
function RunSchemaLinter: Integer;

implementation

procedure ShowHelpMessage;
begin
  Writeln('SchemaLinter - JSON Schema Static Quality & Security Analyzer');
  Writeln('Analyzes JSON Schema files for logical conflicts, ReDoS patterns, and documentation gaps.');
  Writeln;
  Writeln('Usage:');
  Writeln('  SchemaLinterCLI.exe -s <schema_path> [-o <output_path>] [-m <min_severity>]');
  Writeln;
  Writeln('Options:');
  Writeln('  -s, --schema         Path to the input JSON Schema file (required)');
  Writeln('  -o, --output         Path to save the generated report (Markdown, JSON or text)');
  Writeln('  -m, --min-severity   Minimum severity level to report: info, warning, error (default: info)');
  Writeln('  -h, --help           Display this help documentation');
  Writeln;
end;

function SeverityToString(pSeverity: TSeverity): string;
begin
  case pSeverity of
    TSeverity.Info: Result := 'Info';
    TSeverity.Warning: Result := 'Warning';
    TSeverity.Error: Result := 'Error';
  else
    Result := 'Unknown';
  end;
end;

function GenerateMarkdownReport(const pFindings: TArray<TLintFinding>; const pSchemaPath: string): string;
var
  lSb: TStringBuilder;
  lFinding: TLintFinding;
begin
  lSb := TStringBuilder.Create;
  try
    lSb.AppendLine('# SchemaLinter Analysis Report');
    lSb.AppendLine;
    lSb.AppendLine(Format('- **Target Schema**: `%s`', [ExtractFileName(pSchemaPath)]));
    lSb.AppendLine(Format('- **Total Findings**: %d', [Length(pFindings)]));
    lSb.AppendLine(Format('- **Analysis Date**: %s', [DateTimeToStr(Now)]));
    lSb.AppendLine;
    lSb.AppendLine('| Severity | Rule ID | Path | Message |');
    lSb.AppendLine('| :--- | :--- | :--- | :--- |');

    for lFinding in pFindings do
    begin
      lSb.AppendLine(Format('| **%s** | `%s` | `%s` | %s |', [
        SeverityToString(lFinding.Severity),
        lFinding.RuleId,
        lFinding.Path,
        lFinding.Message
      ]));
    end;

    Result := lSb.ToString;
  finally
    lSb.Free;
  end;
end;

function GenerateJSONReport(const pFindings: TArray<TLintFinding>): string;
var
  lArray: TJSONArray;
  lObj: TJSONObject;
  lFinding: TLintFinding;
begin
  lArray := TJSONArray.Create;
  try
    for lFinding in pFindings do
    begin
      lObj := TJSONObject.Create;
      lObj.AddPair('ruleId', lFinding.RuleId);
      lObj.AddPair('severity', SeverityToString(lFinding.Severity));
      lObj.AddPair('path', lFinding.Path);
      lObj.AddPair('message', lFinding.Message);
      lArray.AddElement(lObj);
    end;
    Result := lArray.ToJSON;
  finally
    lArray.Free;
  end;
end;

function RunSchemaLinter: Integer;
var
  lConfig: TSchemaLinterConfig;
  lSchemaJson: string;
  lJSONVal: TJSONValue;
  lSchemaObj: TJSONObject;
  lLinter: TSchemaLinter;
  lFindings: TArray<TLintFinding>;
  lFinding: TLintFinding;
  lOutputText: string;
  lHasErrors: Boolean;
  lLine: string;
begin
  lConfig := ParseCommandLine;

  if lConfig.ShowHelp or (lConfig.SchemaPath = '') then
  begin
    ShowHelpMessage;
    Exit(0);
  end;

  if not FileExists(lConfig.SchemaPath) then
  begin
    Writeln(ErrOutput, 'Error: Schema file does not exist at: ' + lConfig.SchemaPath);
    Exit(1);
  end;

  try
    lSchemaJson := TFile.ReadAllText(lConfig.SchemaPath, TEncoding.UTF8);
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, 'Error reading schema file: ' + E.Message);
      Exit(1);
    end;
  end;

  lJSONVal := TJSONObject.ParseJSONValue(lSchemaJson);
  if not Assigned(lJSONVal) or not (lJSONVal is TJSONObject) then
  begin
    if Assigned(lJSONVal) then
      lJSONVal.Free;
    Writeln(ErrOutput, 'Error: Input file is not a valid JSON Object.');
    Exit(1);
  end;

  lSchemaObj := TJSONObject(lJSONVal);
  lLinter := TSchemaLinter.Create;
  try
    lLinter.MinSeverity := lConfig.MinSeverity;
    lFindings := lLinter.Analyze(lSchemaObj);

    lHasErrors := False;
    if Length(lFindings) > 0 then
    begin
      Writeln(Format('Analysis completed. Found %d issues:', [Length(lFindings)]));
      Writeln;
      for lFinding in lFindings do
      begin
        lLine := Format('[%s] %s at %s: %s', [
          Uppercase(SeverityToString(lFinding.Severity)),
          lFinding.RuleId,
          lFinding.Path,
          lFinding.Message
        ]);
        Writeln(lLine);
        if lFinding.Severity = TSeverity.Error then
          lHasErrors := True;
      end;
    end else
    begin
      Writeln('Analysis completed. No issues found.');
    end;

    // Handle output reporting
    if lConfig.OutputPath <> '' then
    begin
      if SameText(ExtractFileExt(lConfig.OutputPath), '.md') or SameText(ExtractFileExt(lConfig.OutputPath), '.markdown') then
        lOutputText := GenerateMarkdownReport(lFindings, lConfig.SchemaPath)
      else if SameText(ExtractFileExt(lConfig.OutputPath), '.json') then
        lOutputText := GenerateJSONReport(lFindings)
      else
      begin
        lOutputText := '';
        for lFinding in lFindings do
        begin
          lOutputText := lOutputText + Format('[%s] %s at %s: %s', [
            Uppercase(SeverityToString(lFinding.Severity)),
            lFinding.RuleId,
            lFinding.Path,
            lFinding.Message
          ]) + sLineBreak;
        end;
      end;

      try
        TFile.WriteAllText(lConfig.OutputPath, lOutputText, TEncoding.UTF8);
      except
        on E: Exception do
        begin
          Writeln(ErrOutput, 'Error writing report: ' + E.Message);
          Exit(1);
        end;
      end;
    end;

    if lHasErrors then
      Result := 1
    else
      Result := 0;

  finally
    lLinter.Free;
    lSchemaObj.Free;
  end;
end;

end.
