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
  System.IOUtils,
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
  Writeln(ErrOutput, '  Delphi2SchemaCLI -i <type_name> [-b <bpl_path>] [-o <output_path>] [options]');
  Writeln(ErrOutput);
  Writeln(ErrOutput, 'Options:');
  Writeln(ErrOutput, '  -i, --input, -t, --type  Name of the Delphi class or record to scan (Required).');
  Writeln(ErrOutput, '  -b, --bpl                Path to a compiled Delphi package (.bpl) to load dynamically.');
  Writeln(ErrOutput, '  -o, --output             Path to output the generated JSON Schema file (Stdout if omitted).');
  Writeln(ErrOutput, '  -f, --fields             Scan only member fields (default: scans properties).');
  Writeln(ErrOutput, '  -p, --properties         Scan member properties (default behavior).');
  Writeln(ErrOutput, '  --minify                 Minify output JSON schema instead of prettifying.');
  Writeln(ErrOutput, '  -q, --quiet              Suppress informational output.');
  Writeln(ErrOutput, '  --no-enum-names          Represent enum items as integer indexes instead of names.');
  Writeln(ErrOutput, '  -h, --help               Display this help manual.');
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
  lOutputText: string;
begin
  Result := 1; // Default to error
  lConfig := ParseArguments;

  if lConfig.ShowHelp or lConfig.TypeName.IsEmpty then
  begin
    PrintUsage;
    if lConfig.TypeName.IsEmpty and not lConfig.ShowHelp then
      Writeln(ErrOutput, 'Error: Missing required option: -t/--type');
    Exit(0);
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
          if lConfig.Minify then
            lOutputText := lSchemaJson.ToJSON
          else
            lOutputText := lSchemaJson.Format(2);

          if not lConfig.OutputPath.IsEmpty then
          begin
            try
              TFile.WriteAllText(lConfig.OutputPath, lOutputText, TEncoding.UTF8);
              if not lConfig.Quiet then
                Writeln(ErrOutput, 'JSON Schema generated successfully.');
            except
              on E: Exception do
              begin
                Writeln(ErrOutput, 'Error writing output file: ' + E.Message);
                Exit;
              end;
            end;
          end else
          begin
            Writeln(lOutputText);
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
