unit TestJsonSchema.Report.Writer;

(*
--------------------------------------------------------------------------------
Provides tests for the JSON Schema validation report file generation, path formatting, and export functionalities.
--------------------------------------------------------------------------------
*)


interface

uses
  System.Classes,
  System.Generics.Collections,
  System.IOUtils,
  System.SysUtils,
  TestJsonSchema.Types;

type
  TReportWriter = class
  strict private
    class function JsonEscape(const pValue: string): string;
    class function ResolveReportPath(const pReportPath: string): string;
  public
    { Retorna o caminho absoluto de onde o arquivo foi salvo }
    class function SaveFailureReport(const pFilePath: string;
      const pFailures: TList<TJsonSchemaFailure>): string;
  end;

implementation

uses
  TestJsonSchema.Utils.Paths;

class function TReportWriter.JsonEscape(const pValue: string): string;
begin
  Result := StringReplace(pValue, '\', '\\', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '\"', [rfReplaceAll]);
  Result := StringReplace(Result, #13#10, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '\n', [rfReplaceAll]);
end;

class function TReportWriter.ResolveReportPath(const pReportPath: string): string;
var
  lTrimmedPath: string;
  lRepoRootPath: string;
begin
  lTrimmedPath := Trim(pReportPath);

  // Clusula de guarda
  if lTrimmedPath = '' then
    Exit('');

  // Clusula de guarda
  if TPath.IsPathRooted(lTrimmedPath) then
    Exit(TPath.GetFullPath(lTrimmedPath));

  lRepoRootPath := TPath.GetFullPath(TPath.Combine(GetTestRootPath, '..'));
  Result := TPath.GetFullPath(TPath.Combine(lRepoRootPath, lTrimmedPath));
end;

class function TReportWriter.SaveFailureReport(const pFilePath: string;
  const pFailures: TList<TJsonSchemaFailure>): string;
var
  lLines: TStringList;
  lFailure: TJsonSchemaFailure;
  lIsJson: Boolean;
  lIndex: Integer;
  lDirectory: string;
begin
  Result := '';

  // Clusula de guarda validando a entrada
  if Trim(pFilePath) = '' then
    Exit;

  Result := ResolveReportPath(pFilePath);
  lDirectory := ExtractFilePath(Result);

  if (lDirectory <> '') and not TDirectory.Exists(lDirectory) then
    TDirectory.CreateDirectory(lDirectory);

  lIsJson := SameText(ExtractFileExt(Result), '.json');
  lLines := TStringList.Create;
  try
    if lIsJson then
    begin
      lLines.Add('[');
      for lIndex := 0 to pFailures.Count - 1 do
      begin
        lFailure := pFailures[lIndex];
        lLines.Add('  {');
        lLines.Add(Format('    "draft": "%s",', [JsonEscape(lFailure.DraftName)]));
        lLines.Add(Format('    "file": "%s",', [JsonEscape(lFailure.FilePath)]));
        lLines.Add(Format('    "test": "%s",', [JsonEscape(lFailure.TestDescription)]));
        lLines.Add(Format('    "schemaPath": "%s",', [JsonEscape(lFailure.SchemaPath)]));
        lLines.Add(Format('    "instancePath": "%s",', [JsonEscape(lFailure.InstancePath)]));
        lLines.Add(Format('    "error": "%s",', [JsonEscape(lFailure.ErrorMessage)]));
        lLines.Add(Format('    "expectedValid": %s,', [LowerCase(BoolToStr(lFailure.ExpectedValid, True))]));
        lLines.Add(Format('    "actualValid": %s', [LowerCase(BoolToStr(lFailure.ActualValid, True))]));

        // Uso de begin..end explcito para suportar o 'end else begin' nas normas
        if lIndex < pFailures.Count - 1 then
        begin
          lLines.Add('  },');
        end else
        begin
          lLines.Add('  }');
        end;
      end;
      lLines.Add(']');
    end else
    begin
      for lFailure in pFailures do
      begin
        lLines.Add('[FALHA]');
        lLines.Add('Draft=' + lFailure.DraftName);
        lLines.Add('Arquivo=' + lFailure.FilePath);
        lLines.Add('Teste=' + lFailure.TestDescription);
        lLines.Add('SchemaPath=' + lFailure.SchemaPath);
        lLines.Add('InstancePath=' + lFailure.InstancePath);
        lLines.Add('Erro=' + lFailure.ErrorMessage);
        lLines.Add('Esperado=' + BoolToStr(lFailure.ExpectedValid, True));
        lLines.Add('Obtido=' + BoolToStr(lFailure.ActualValid, True));
        lLines.Add('');
      end;
    end;

    lLines.SaveToFile(Result, TEncoding.UTF8);
  finally
    lLines.Free;
  end;
end;

end.
