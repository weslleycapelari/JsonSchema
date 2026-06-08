program Schema2RESTCLI;

(*
--------------------------------------------------------------------------------
Command-Line Interface (CLI) program for generating Horse or DMVC validated
REST Router/Controller Delphi units from JSON Schema definitions.
--------------------------------------------------------------------------------
*)

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Schema2REST.Config in 'src\Schema2REST.Config.pas',
  Schema2REST.Templates in 'src\Schema2REST.Templates.pas',
  Schema2REST.Engine in 'src\Schema2REST.Engine.pas',
  Schema2REST.Runner in 'src\Schema2REST.Runner.pas';

{$R *.res}

begin
  try
    Halt(RunSchema2REST);
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, 'Fatal error: ' + E.Message);
      Halt(2);
    end;
  end;
end.
