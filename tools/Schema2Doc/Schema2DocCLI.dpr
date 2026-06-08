program Schema2DocCLI;

(*
--------------------------------------------------------------------------------
Command-Line Interface (CLI) program for generating Markdown or HTML documentation
from JSON Schema definitions.
--------------------------------------------------------------------------------
*)

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Schema2Doc.Config in 'src\Schema2Doc.Config.pas',
  Schema2Doc.Engine in 'src\Schema2Doc.Engine.pas',
  Schema2Doc.Runner in 'src\Schema2Doc.Runner.pas';

{$R *.res}

begin
  try
    Halt(RunSchema2Doc);
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, 'Fatal error: ' + E.Message);
      Halt(2);
    end;
  end;
end.
