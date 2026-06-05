unit SchemaValidator.Utils;

(*
--------------------------------------------------------------------------------
Utility functions for file handling, stdin reading, and draft auto-detection.
--------------------------------------------------------------------------------
*)

interface

uses
  System.Classes,
  System.JSON,
  System.SysUtils,
  JsonSchema.Core.Interfaces;

/// <summary>Reads entire content from a UTF-8 text file.</summary>
/// <param name="pPath">Absolute or relative file path.</param>
/// <returns>File content string.</returns>
function ReadFileContent(const pPath: string): string;

/// <summary>Reads entire piped content from standard input (stdin).</summary>
/// <returns>Piped content string.</returns>
function ReadStdinContent: string;

/// <summary>Auto-detects JSON Schema draft version from $schema keyword.</summary>
/// <param name="pSchema">The schema JSON value.</param>
/// <returns>The detected TDraftVersion draft version.</returns>
function AutoDetectDraft(pSchema: TJSONValue): TDraftVersion;

implementation

function ReadFileContent(const pPath: string): string;
var
  lFile: TStringList;
begin
  lFile := TStringList.Create;
  try
    lFile.LoadFromFile(pPath, TEncoding.UTF8);
    Result := lFile.Text;
  finally
    lFile.Free;
  end;
end;

function ReadStdinContent: string;
var
  lLine: string;
  lBuilder: TStringBuilder;
begin
  lBuilder := TStringBuilder.Create;
  try
    while not Eof do
    begin
      Readln(lLine);
      lBuilder.AppendLine(lLine);
    end;
    Result := lBuilder.ToString;
  finally
    lBuilder.Free;
  end;
end;

function AutoDetectDraft(pSchema: TJSONValue): TDraftVersion;
var
  lSchemaObj: TJSONObject;
  lSchemaValue: TJSONValue;
  lSchemaStr: string;
begin
  Result := TDraftVersion.dvDraft2020_12; // Default fallback
  if pSchema is TJSONObject then
  begin
    lSchemaObj := TJSONObject(pSchema);
    if lSchemaObj.TryGetValue('$schema', lSchemaValue) and (lSchemaValue is TJSONString) then
    begin
      lSchemaStr := (lSchemaValue as TJSONString).Value;
      if lSchemaStr.Contains('draft-06') then
        Result := TDraftVersion.dvDraft6
      else if lSchemaStr.Contains('draft-07') then
        Result := TDraftVersion.dvDraft7
      else if lSchemaStr.Contains('2019-09') then
        Result := TDraftVersion.dvDraft2019_09
      else if lSchemaStr.Contains('2020-12') then
        Result := TDraftVersion.dvDraft2020_12;
    end;
  end;
end;

end.
