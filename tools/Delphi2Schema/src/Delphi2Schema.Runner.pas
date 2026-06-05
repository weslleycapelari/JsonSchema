unit Delphi2Schema.Runner;

(*
--------------------------------------------------------------------------------
Orchestrates CLI execution, argument parsing, package loading, and RTTI scanning.
--------------------------------------------------------------------------------
*)

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Rtti,
  System.JSON,
  System.Classes,
  System.TypInfo,
  Delphi2Schema.Config,
  Delphi2Schema.Engine,
  Delphi2Schema.Samples;

/// <summary>Displays the CLI usage manual on stderr.</summary>
procedure PrintUsage;

/// <summary>Runs the Delphi2Schema CLI workflow.</summary>
/// <returns>Exit code: 0 for success, 2 for error.</returns>
function RunDelphi2Schema: Integer;

implementation

procedure PrintUsage;
begin
  Writeln(ErrOutput, 'Delphi2Schema - JSON Schema Code-to-Schema Generation Utility');
  Writeln(ErrOutput);
  Writeln(ErrOutput, 'Usage:');
  Writeln(ErrOutput, '  Delphi2SchemaCLI -t <type_name> [-b <bpl_path>] [-o <output_path>] [options]');
  Writeln(ErrOutput);
  Writeln(ErrOutput, 'Options:');
  Writeln(ErrOutput, '  -t, --type        Name of the Delphi class or record to scan (Required).');
  Writeln(ErrOutput, '  -b, --bpl         Path to a compiled Delphi package (.bpl) to load dynamically.');
  Writeln(ErrOutput, '  -o, --output      Path to output the generated JSON Schema file (Stdout if omitted).');
  Writeln(ErrOutput, '  -f, --fields      Scan only member fields (default: scans properties).');
  Writeln(ErrOutput, '  -p, --properties  Scan member properties (default behavior).');
  Writeln(ErrOutput, '  --no-enum-names   Represent enum items as integer indexes instead of names.');
  Writeln(ErrOutput, '  -h, --help        Display this help manual.');
  Writeln(ErrOutput);
end;

function FindRttiType(const pName: string; var pContext: TRttiContext): TRttiType;
var
  lType: TRttiType;
begin
  // Try direct namespace lookup
  Result := pContext.FindType(pName);
  if Assigned(Result) then
    Exit;

  // Search by simple name or qualified name
  for lType in pContext.GetTypes do
  begin
    if SameText(lType.Name, pName) or SameText(lType.QualifiedName, pName) then
    begin
      Result := lType;
      Exit;
    end;
  end;
end;

function RunDelphi2Schema: Integer;
var
  lConfig: TConfig;
  lContext: TRttiContext;
  lType: TRttiType;
  lPackageHandle: HMODULE;
  lGenerator: TDelphi2SchemaGenerator;
  lSchemaJson: TJSONObject;
  lOutFile: TStringList;
begin
  Result := 2; // Default to error
  lConfig := ParseArguments;

  if lConfig.ShowHelp or lConfig.TypeName.IsEmpty then
  begin
    PrintUsage;
    if lConfig.TypeName.IsEmpty and not lConfig.ShowHelp then
      Writeln(ErrOutput, 'Error: Missing required option: -t/--type');
    Exit;
  end;

  lPackageHandle := 0;
  if not lConfig.BplPath.IsEmpty then
  begin
    if not FileExists(lConfig.BplPath) then
    begin
      Writeln(ErrOutput, 'Error: Package file not found: ' + lConfig.BplPath);
      Exit;
    end;

    try
      lPackageHandle := SafeLoadLibrary(lConfig.BplPath);
      if lPackageHandle = 0 then
      begin
        Writeln(ErrOutput, 'Error: Could not load package: ' + lConfig.BplPath);
        Exit;
      end;
    except
      on E: Exception do
      begin
        Writeln(ErrOutput, 'Error loading package: ' + E.Message);
        Exit;
      end;
    end;
  end;

  try
    lContext := TRttiContext.Create;
    try
      lType := FindRttiType(lConfig.TypeName, lContext);
      if not Assigned(lType) then
      begin
        Writeln(ErrOutput, 'Error: Type not found in RTTI context: ' + lConfig.TypeName);
        Exit;
      end;

      lGenerator := TDelphi2SchemaGenerator.Create;
      try
        lGenerator.ScanFields := lConfig.ScanFields;
        lGenerator.ScanProperties := lConfig.ScanProperties;
        lGenerator.UseEnumNames := lConfig.UseEnumNames;

        lSchemaJson := lGenerator.GenerateSchema(lType.Handle);
        try
          if not lConfig.OutputPath.IsEmpty then
          begin
            lOutFile := TStringList.Create;
            try
              lOutFile.Text := lSchemaJson.Format(2);
              lOutFile.SaveToFile(lConfig.OutputPath, TEncoding.UTF8);
            finally
              lOutFile.Free;
            end;
          end else
          begin
            Writeln(lSchemaJson.Format(2));
          end;
          Result := 0; // Success
        finally
          lSchemaJson.Free;
        end;
      finally
        lGenerator.Free;
      end;
    finally
      lContext.Free;
    end;
  finally
    if lPackageHandle <> 0 then
      FreeLibrary(lPackageHandle);
  end;
end;

end.
