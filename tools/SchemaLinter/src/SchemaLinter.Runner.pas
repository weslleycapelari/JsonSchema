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
  Writeln(ErrOutput, 'SchemaLinter - JSON Schema Static Quality & Security Analyzer');
  Writeln(ErrOutput, 'Analyzes JSON Schema files for logical conflicts, ReDoS patterns, and documentation gaps.');
  Writeln(ErrOutput);
  Writeln(ErrOutput, 'Usage:');
  Writeln(ErrOutput, '  SchemaLinterCLI.exe -i <schema_path> [-o <output_path>] [options]');
  Writeln(ErrOutput);
  Writeln(ErrOutput, 'Options:');
  Writeln(ErrOutput, '  -i, --input, -s, --schema  Path to the input JSON Schema file (required)');
  Writeln(ErrOutput, '  -o, --output               Path to save the generated report (Markdown, JSON or text)');
  Writeln(ErrOutput, '  -m, --min-severity         Minimum severity level to report: info, warning, error (default: info)');
  Writeln(ErrOutput, '  -q, --quiet                Suppress informational output');
  Writeln(ErrOutput, '  -h, --help                 Display this help documentation');
  Writeln(ErrOutput);
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
  Result := 1; // Default to error
  lConfig := ParseCommandLine;

  if lConfig.ShowHelp or (lConfig.SchemaPath = '') then
  begin
    ShowHelpMessage;
    Exit(0);
  end;

  if not FileExists(lConfig.SchemaPath) then
  begin
    Writeln(ErrOutput, 'Error: Schema file does not exist at: ' + lConfig.SchemaPath);
    Exit;
  end;

  try
    lSchemaJson := TFile.ReadAllText(lConfig.SchemaPath, TEncoding.UTF8);
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, 'Error reading schema file: ' + E.Message);
      Exit;
    end;
  end;

  lJSONVal := TJSONObject.ParseJSONValue(lSchemaJson);
  if not Assigned(lJSONVal) or not (lJSONVal is TJSONObject) then
  begin
    if Assigned(lJSONVal) then
      lJSONVal.Free;
    Writeln(ErrOutput, 'Error: Input file is not a valid JSON Object.');
    Exit;
  end;

  lSchemaObj := TJSONObject(lJSONVal);
  lLinter := TSchemaLinter.Create;
  try
    lLinter.MinSeverity := lConfig.MinSeverity;
    lFindings := lLinter.Analyze(lSchemaObj);

    lHasErrors := False;
    if Length(lFindings) > 0 then
    begin
      if not lConfig.Quiet then
      begin
        Writeln(Format('Analysis completed. Found %d issues:', [Length(lFindings)]));
        Writeln;
      end;

      for lFinding in lFindings do
      begin
        lLine := Format('[%s] %s at %s: %s', [
          Uppercase(SeverityToString(lFinding.Severity)),
          lFinding.RuleId,
          lFinding.Path,
          lFinding.Message
        ]);
        if not lConfig.Quiet then
          Writeln(lLine);
        if lFinding.Severity = TSeverity.Error then
          lHasErrors := True;
      end;
    end else
    begin
      if not lConfig.Quiet then
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
        if not lConfig.Quiet then
          Writeln(ErrOutput, 'Report generated successfully.');
      except
        on E: Exception do
        begin
          Writeln(ErrOutput, 'Error writing report: ' + E.Message);
          Exit;
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
