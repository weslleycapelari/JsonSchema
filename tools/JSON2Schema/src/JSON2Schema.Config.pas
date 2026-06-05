unit JSON2Schema.Config;

(*
--------------------------------------------------------------------------------
Command-line Configuration and Parser for JSON2Schema CLI.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils, System.Classes;

type
  /// <summary>Options configuration for JSON2Schema CLI converter.</summary>
  TJSON2SchemaConfig = record
    InputPath: string;
    OutputPath: string;
    Draft: string;
    MakeRequired: Boolean;
    InferFormats: Boolean;
    ShowHelp: Boolean;
  end;

/// <summary>Parses command line arguments into a config record.</summary>
function ParseCommandLine: TJSON2SchemaConfig;

implementation

function ParseCommandLine: TJSON2SchemaConfig;
var
  lI: Integer;
  lArg: string;
begin
  // Set default values
  Result.InputPath := '';
  Result.OutputPath := '';
  Result.Draft := 'http://json-schema.org/draft-07/schema#';
  Result.MakeRequired := False;
  Result.InferFormats := True;
  Result.ShowHelp := False;

  lI := 1;
  while lI <= ParamCount do
  begin
    lArg := ParamStr(lI);

    if SameText(lArg, '-h') or SameText(lArg, '--help') then
    begin
      Result.ShowHelp := True;
      Inc(lI);
    end
    else if (SameText(lArg, '-i') or SameText(lArg, '--input')) and (lI < ParamCount) then
    begin
      Result.InputPath := ParamStr(lI + 1);
      Inc(lI, 2);
    end
    else if (SameText(lArg, '-o') or SameText(lArg, '--output')) and (lI < ParamCount) then
    begin
      Result.OutputPath := ParamStr(lI + 1);
      Inc(lI, 2);
    end
    else if (SameText(lArg, '-d') or SameText(lArg, '--draft')) and (lI < ParamCount) then
    begin
      Result.Draft := ParamStr(lI + 1);
      Inc(lI, 2);
    end
    else if SameText(lArg, '--required') then
    begin
      Result.MakeRequired := True;
      Inc(lI);
    end
    else if SameText(lArg, '--no-format') then
    begin
      Result.InferFormats := False;
      Inc(lI);
    end
    else
    begin
      if Result.InputPath = '' then
        Result.InputPath := lArg;
      Inc(lI);
    end;
  end;
end;

end.
