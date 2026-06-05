unit Schema2REST.Config;

(*
--------------------------------------------------------------------------------
Command-line Configuration and Parser for Schema2REST CLI.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils, System.Classes;

type
  /// <summary>Options configuration for Schema2REST CLI generator.</summary>
  TSchema2RESTConfig = record
    SchemaPath: string;
    Framework: string;
    OutputPath: string;
    EntityName: string;
    ShowHelp: Boolean;
  end;

/// <summary>Parses command line arguments into a config record.</summary>
function ParseCommandLine: TSchema2RESTConfig;

implementation

function ParseCommandLine: TSchema2RESTConfig;
var
  lI: Integer;
  lArg: string;
begin
  // Default values
  Result.SchemaPath := '';
  Result.Framework := 'Horse';
  Result.OutputPath := '';
  Result.EntityName := '';
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
    else if (SameText(lArg, '-s') or SameText(lArg, '--schema')) and (lI < ParamCount) then
    begin
      Result.SchemaPath := ParamStr(lI + 1);
      Inc(lI, 2);
    end
    else if (SameText(lArg, '-f') or SameText(lArg, '--framework')) and (lI < ParamCount) then
    begin
      Result.Framework := ParamStr(lI + 1);
      Inc(lI, 2);
    end
    else if (SameText(lArg, '-o') or SameText(lArg, '--output')) and (lI < ParamCount) then
    begin
      Result.OutputPath := ParamStr(lI + 1);
      Inc(lI, 2);
    end
    else if (SameText(lArg, '-e') or SameText(lArg, '--entity')) and (lI < ParamCount) then
    begin
      Result.EntityName := ParamStr(lI + 1);
      Inc(lI, 2);
    end
    else
    begin
      if Result.SchemaPath = '' then
        Result.SchemaPath := lArg;
      Inc(lI);
    end;
  end;
end;

end.
