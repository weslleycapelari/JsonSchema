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

/// <summary>Outputs validation errors in plain text format.</summary>
/// <param name="pResult">The validation result containing errors.</param>
procedure PrintErrorsText(pResult: IValidationResult);

/// <summary>Outputs validation errors in structured JSON format.</summary>
/// <param name="pResult">The validation result containing errors.</param>
procedure PrintErrorsJson(pResult: IValidationResult);

/// <summary>Outputs validation errors in JUnit XML testsuite format.</summary>
/// <param name="pResult">The validation result containing errors.</param>
/// <param name="pInstanceName">The name/file of the instance validated.</param>
procedure PrintErrorsJUnit(pResult: IValidationResult; const pInstanceName: string);

implementation

procedure PrintErrorsText(pResult: IValidationResult);
var
  lError: IValidationError;
begin
  Writeln(Format('Validation failed! %d error(s) found:', [Length(pResult.Errors)]));
  for lError in pResult.Errors do
  begin
    Writeln(Format('[Keyword: %s] %s (Resolution: %s)', [lError.Keyword, lError.Message, lError.Resolution]));
  end;
end;

procedure PrintErrorsJson(pResult: IValidationResult);
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
    Writeln(lArray.ToJSON);
  finally
    lArray.Free;
  end;
end;

procedure PrintErrorsJUnit(pResult: IValidationResult; const pInstanceName: string);
var
  lError: IValidationError;
  lFailureMsg: TStringBuilder;
begin
  Writeln('<?xml version="1.0" encoding="UTF-8"?>');
  if pResult.IsValid then
  begin
    Writeln('<testsuite name="JSON Schema Validation" tests="1" failures="0" errors="0" time="0.00">');
    Writeln(Format('  <testcase name="Validate %s" classname="SchemaValidatorCLI" time="0.00"/>', [pInstanceName]));
    Writeln('</testsuite>');
  end else
  begin
    Writeln(Format('<testsuite name="JSON Schema Validation" tests="1" failures="1" errors="0" time="0.00">', []));
    Writeln(Format('  <testcase name="Validate %s" classname="SchemaValidatorCLI" time="0.00">', [pInstanceName]));
    lFailureMsg := TStringBuilder.Create;
    try
      lFailureMsg.AppendLine(Format('Validation failed. %d error(s) found:', [Length(pResult.Errors)]));
      for lError in pResult.Errors do
      begin
        lFailureMsg.AppendLine(Format('  - [Keyword: %s] %s', [lError.Keyword, lError.Message]));
      end;
      Writeln(Format('    <failure message="Validation failed. %d error(s) found."><![CDATA[%s]]></failure>', [Length(pResult.Errors), lFailureMsg.ToString]));
    finally
      lFailureMsg.Free;
    end;
    Writeln('  </testcase>');
    Writeln('</testsuite>');
  end;
end;

end.
