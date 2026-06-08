unit SchemaValidator.Formatters;

(*
--------------------------------------------------------------------------------
Provides error formatting for text, JSON, and JUnit XML outputs.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  System.SysUtils,
  System.Classes,
  JsonSchema.Core.Interfaces;

/// <summary>Formats validation errors in plain text format.</summary>
/// <param name="pResult">The validation result containing errors.</param>
function FormatErrorsText(pResult: IValidationResult): string;

/// <summary>Formats validation errors in structured JSON format.</summary>
/// <param name="pResult">The validation result containing errors.</param>
function FormatErrorsJson(pResult: IValidationResult): string;

/// <summary>Formats validation errors in JUnit XML testsuite format.</summary>
/// <param name="pResult">The validation result containing errors.</param>
/// <param name="pInstanceName">The name/file of the instance validated.</param>
function FormatErrorsJUnit(pResult: IValidationResult; const pInstanceName: string): string;

implementation

function FormatErrorsText(pResult: IValidationResult): string;
var
  lError: IValidationError;
  lSb: TStringBuilder;
begin
  lSb := TStringBuilder.Create;
  try
    lSb.AppendLine(Format('Validation failed! %d error(s) found:', [Length(pResult.Errors)]));
    for lError in pResult.Errors do
    begin
      lSb.AppendLine(Format('[Keyword: %s] %s (Resolution: %s)', [lError.Keyword, lError.Message, lError.Resolution]));
    end;
    Result := lSb.ToString;
  finally
    lSb.Free;
  end;
end;

function FormatErrorsJson(pResult: IValidationResult): string;
var
  lArray: TJSONArray;
  lObj: TJSONObject;
  lError: IValidationError;
begin
  lArray := TJSONArray.Create;
  try
    for lError in pResult.Errors do
    begin
      lObj := TJSONObject.Create;
      lObj.AddPair('keyword', lError.Keyword);
      lObj.AddPair('instancePath', '');
      lObj.AddPair('schemaPath', '');
      lObj.AddPair('message', lError.Message);
      lObj.AddPair('resolution', lError.Resolution);
      lArray.AddElement(lObj);
    end;
    Result := lArray.ToJSON;
  finally
    lArray.Free;
  end;
end;

function FormatErrorsJUnit(pResult: IValidationResult; const pInstanceName: string): string;
var
  lError: IValidationError;
  lFailureMsg: TStringBuilder;
  lSb: TStringBuilder;
begin
  lSb := TStringBuilder.Create;
  try
    lSb.AppendLine('<?xml version="1.0" encoding="UTF-8"?>');
    if pResult.IsValid then
    begin
      lSb.AppendLine('<testsuite name="JSON Schema Validation" tests="1" failures="0" errors="0" time="0.00">');
      lSb.AppendLine(Format('  <testcase name="Validate %s" classname="SchemaValidatorCLI" time="0.00"/>', [pInstanceName]));
      lSb.AppendLine('</testsuite>');
    end else
    begin
      lSb.AppendLine('<testsuite name="JSON Schema Validation" tests="1" failures="1" errors="0" time="0.00">');
      lSb.AppendLine(Format('  <testcase name="Validate %s" classname="SchemaValidatorCLI" time="0.00">', [pInstanceName]));
      lFailureMsg := TStringBuilder.Create;
      try
        lFailureMsg.AppendLine(Format('Validation failed. %d error(s) found:', [Length(pResult.Errors)]));
        for lError in pResult.Errors do
        begin
          lFailureMsg.AppendLine(Format('  - [Keyword: %s] %s', [lError.Keyword, lError.Message]));
        end;
        lSb.AppendLine(Format('    <failure message="Validation failed. %d error(s) found."><![CDATA[%s]]></failure>', [Length(pResult.Errors), lFailureMsg.ToString]));
      finally
        lFailureMsg.Free;
      end;
      lSb.AppendLine('  </testcase>');
      lSb.AppendLine('</testsuite>');
    end;
    Result := lSb.ToString;
  finally
    lSb.Free;
  end;
end;

end.
