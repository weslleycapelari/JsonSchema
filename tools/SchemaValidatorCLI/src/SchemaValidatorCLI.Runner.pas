unit SchemaValidatorCLI.Runner;

(*
--------------------------------------------------------------------------------
Orchestrates CLI execution, argument parsing, file reading, and validation.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  System.SysUtils,
  SchemaValidatorCLI.Config,
  SchemaValidatorCLI.Formatters,
  SchemaValidatorCLI.Utils,
  JsonSchema.Core.Interfaces,
  JsonSchema.Validator;

/// <summary>Displays the CLI usage manual on stderr.</summary>
procedure PrintUsage;

/// <summary>Runs the schema validator CLI workflow.</summary>
/// <returns>Exit code: 0 for valid, 1 for invalid, 2 for parsing/runtime errors.</returns>
function RunSchemaValidatorCLI: Integer;

implementation

procedure PrintUsage;
begin
  Writeln(ErrOutput, 'SchemaValidatorCLI - JSON Schema CLI Validation Utility');
  Writeln(ErrOutput);
  Writeln(ErrOutput, 'Usage:');
  Writeln(ErrOutput, '  SchemaValidatorCLI -s <schema_path> [-i <instance_path>] [options]');
  Writeln(ErrOutput);
  Writeln(ErrOutput, 'Options:');
  Writeln(ErrOutput, '  -s, --schema      Path to the JSON Schema file (Required).');
  Writeln(ErrOutput, '  -i, --instance    Path to the JSON Instance file (Optional. Reads from stdin if omitted).');
  Writeln(ErrOutput, '  -d, --draft       Force schema draft version (6, 7, 2019-09, 2020-12).');
  Writeln(ErrOutput, '                    Defaults to auto-detection from $schema, or 2020-12.');
  Writeln(ErrOutput, '  -l, --locale      Locale for translated error messages (en, pt). Default: en.');
  Writeln(ErrOutput, '  -f, --format      Output report format (text, json, junit). Default: text.');
  Writeln(ErrOutput, '  --no-format       Disable schema format validation checks.');
  Writeln(ErrOutput, '  -h, --help        Display this help manual.');
  Writeln(ErrOutput);
end;

function RunSchemaValidatorCLI: Integer;
var
  lConfig: TConfig;
  lSchemaStr, lInstanceStr: string;
  lSchemaVal, lInstanceVal: TJSONValue;
  lValidator: TJsonSchemaValidator;
  lResult: IValidationResult;
  lDraft: TDraftVersion;
  lInstanceName: string;
begin
  Result := 2; // Default to error exit code until validation completes
  lConfig := ParseArguments;

  if lConfig.ShowHelp or lConfig.SchemaPath.IsEmpty then
  begin
    PrintUsage;
    if lConfig.SchemaPath.IsEmpty and not lConfig.ShowHelp then
      Writeln(ErrOutput, 'Error: Missing required option: -s/--schema');
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
    if lResult.IsValid then
    begin
      if lConfig.OutputFormat = ofJUnit then
        PrintErrorsJUnit(lResult, lInstanceName)
      else if lConfig.OutputFormat = ofText then
        Writeln('Validation succeeded.');
      Result := 0;
    end else
    begin
      case lConfig.OutputFormat of
        ofText: PrintErrorsText(lResult);
        ofJson: PrintErrorsJson(lResult);
        ofJUnit: PrintErrorsJUnit(lResult, lInstanceName);
      end;
      Result := 1;
    end;
  finally
    lValidator.Free;
    lSchemaVal.Free;
    lInstanceVal.Free;
  end;
end;

end.
