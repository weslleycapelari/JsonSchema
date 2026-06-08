unit SchemaValidator.Runner;

(*
--------------------------------------------------------------------------------
Orchestrates CLI execution, argument parsing, file reading, and validation.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  System.SysUtils,
  System.Classes,
  SchemaValidator.Config,
  SchemaValidator.Formatters,
  SchemaValidator.Utils,
  JsonSchema.Core.Interfaces,
  JsonSchema.Validator;

/// <summary>Displays the CLI usage manual on stderr.</summary>
procedure PrintUsage;

/// <summary>Runs the schema validator CLI workflow.</summary>
/// <returns>Exit code: 0 for valid, 1 for invalid/errors.</returns>
function RunSchemaValidator: Integer;

implementation

procedure PrintUsage;
begin
  Writeln(ErrOutput, 'SchemaValidator - JSON Schema CLI Validation Utility');
  Writeln(ErrOutput);
  Writeln(ErrOutput, 'Usage:');
  Writeln(ErrOutput, '  SchemaValidator -i <schema_path> [-j <instance_path>] [options]');
  Writeln(ErrOutput, '  SchemaValidator <schema_path> [<instance_path>] [options]');
  Writeln(ErrOutput);
  Writeln(ErrOutput, 'Options:');
  Writeln(ErrOutput, '  -i, --input, -s, --schema   Path to the JSON Schema file (Required).');
  Writeln(ErrOutput, '  -j, --json, --instance      Path to the JSON Instance file (Optional. Reads from stdin if omitted).');
  Writeln(ErrOutput, '  -o, --output <path>         Path to write the output report instead of stdout (Optional).');
  Writeln(ErrOutput, '  -d, --draft <version>       Force schema draft version (6, 7, 2019-09, 2020-12).');
  Writeln(ErrOutput, '                              Defaults to auto-detection from $schema, or 2020-12.');
  Writeln(ErrOutput, '  -l, --locale <locale>       Locale for translated error messages (en, pt). Default: en.');
  Writeln(ErrOutput, '  -f, --format <format>       Output report format (text, json, junit). Default: text.');
  Writeln(ErrOutput, '  --no-format                 Disable schema format validation checks.');
  Writeln(ErrOutput, '  --quiet                     Modo silencioso. Suprime saídas informativas.');
  Writeln(ErrOutput, '  -h, --help                  Display this help manual.');
  Writeln(ErrOutput);
end;

procedure OutputResult(const pContent: string; const pOutputPath: string);
var
  lFileStream: TFileStream;
  lWriter: TStreamWriter;
begin
  if pOutputPath.IsEmpty then
  begin
    Write(pContent);
  end else
  begin
    lFileStream := TFileStream.Create(pOutputPath, fmCreate);
    try
      lWriter := TStreamWriter.Create(lFileStream, TEncoding.UTF8);
      try
        lWriter.Write(pContent);
      finally
        lWriter.Free;
      end;
    finally
      lFileStream.Free;
    end;
  end;
end;

function RunSchemaValidator: Integer;
var
  lConfig: TConfig;
  lSchemaStr, lInstanceStr: string;
  lSchemaVal, lInstanceVal: TJSONValue;
  lValidator: TJsonSchemaValidator;
  lResult: IValidationResult;
  lDraft: TDraftVersion;
  lInstanceName: string;
  lOutputText: string;
begin
  Result := 1; // Default to error exit code (1 is used for any failure: validation, missing params, file not found)
  lConfig := ParseArguments;

  if lConfig.ShowHelp or lConfig.SchemaPath.IsEmpty then
  begin
    PrintUsage;
    if lConfig.SchemaPath.IsEmpty and not lConfig.ShowHelp then
      Writeln(ErrOutput, 'Error: Missing required option: -i/--input or -s/--schema');
    Exit;
  end;

  // --- STEP 1: Load Schema ---
  if not FileExists(lConfig.SchemaPath) then
  begin
    Writeln(ErrOutput, Format('Error: Schema file not found: %s', [lConfig.SchemaPath]));
    Exit;
  end;

  try
    lSchemaStr := ReadFileContent(lConfig.SchemaPath);
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, Format('Error reading schema file: %s', [E.Message]));
      Exit;
    end;
  end;

  lSchemaVal := TJSONObject.ParseJSONValue(lSchemaStr);
  if not Assigned(lSchemaVal) then
  begin
    Writeln(ErrOutput, 'Error: Schema is not valid JSON.');
    Exit;
  end;

  // --- STEP 2: Load Instance ---
  if not lConfig.InstancePath.IsEmpty then
  begin
    if not FileExists(lConfig.InstancePath) then
    begin
      lSchemaVal.Free;
      Writeln(ErrOutput, Format('Error: Instance file not found: %s', [lConfig.InstancePath]));
      Exit;
    end;

    try
      lInstanceStr := ReadFileContent(lConfig.InstancePath);
      lInstanceName := ExtractFileName(lConfig.InstancePath);
    except
      on E: Exception do
      begin
        lSchemaVal.Free;
        Writeln(ErrOutput, Format('Error reading instance file: %s', [E.Message]));
        Exit;
      end;
    end;
  end else
  begin
    lInstanceStr := ReadStdinContent;
    lInstanceName := 'stdin';
  end;

  lInstanceVal := TJSONObject.ParseJSONValue(lInstanceStr);
  if not Assigned(lInstanceVal) then
  begin
    lSchemaVal.Free;
    Writeln(ErrOutput, 'Error: Instance is not valid JSON.');
    Exit;
  end;

  // --- STEP 3: Execute Validation ---
  lValidator := TJsonSchemaValidator.Create(lConfig.Locale);
  try
    lValidator.EnforceFormats := lConfig.EnforceFormats;

    if lConfig.ForceDraft then
      lDraft := lConfig.DraftVersion
    else
      lDraft := AutoDetectDraft(lSchemaVal);

    try
      lResult := lValidator.Validate(lSchemaVal, lInstanceVal, lDraft);
    except
      on E: Exception do
      begin
        Writeln(ErrOutput, Format('Runtime Validation Error: %s', [E.Message]));
        Exit;
      end;
    end;

    // --- STEP 4: Format Output ---
    lOutputText := '';
    if lResult.IsValid then
    begin
      if lConfig.OutputFormat = ofJUnit then
        lOutputText := FormatErrorsJUnit(lResult, lInstanceName)
      else if (lConfig.OutputFormat = ofText) and (not lConfig.Quiet) then
        lOutputText := 'Validation succeeded.' + sLineBreak;
      Result := 0;
    end else
    begin
      case lConfig.OutputFormat of
        ofText: lOutputText := FormatErrorsText(lResult);
        ofJson: lOutputText := FormatErrorsJson(lResult);
        ofJUnit: lOutputText := FormatErrorsJUnit(lResult, lInstanceName);
      end;
      Result := 1;
    end;

    if not lOutputText.IsEmpty then
    begin
      try
        OutputResult(lOutputText, lConfig.OutputPath);
      except
        on E: Exception do
        begin
          Writeln(ErrOutput, Format('Error writing output report: %s', [E.Message]));
          Result := 1;
        end;
      end;
    end;
  finally
    lValidator.Free;
    lSchemaVal.Free;
    lInstanceVal.Free;
  end;
end;

end.
