program Schema2DDLCLI;

(*
--------------------------------------------------------------------------------
Command-Line Interface (CLI) program for generating relational SQL DDL scripts
from JSON Schema definitions.
--------------------------------------------------------------------------------
*)

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Schema2DDL.Config in 'src\Schema2DDL.Config.pas',
  Schema2DDL.Dialects in 'src\Schema2DDL.Dialects.pas',
  Schema2DDL.Engine in 'src\Schema2DDL.Engine.pas',
  Schema2DDL.Runner in 'src\Schema2DDL.Runner.pas';

{$R *.res}

begin
  try
    Halt(RunSchema2DDL);
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, 'Fatal error: ' + E.Message);
      Halt(2);
    end;
  end;
end.
