program JSON2SchemaCLI;

(*
--------------------------------------------------------------------------------
Command-Line Interface (CLI) program for generating JSON Schema from JSON
instance documents.
--------------------------------------------------------------------------------
*)

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  JSON2Schema.Config in 'src\JSON2Schema.Config.pas',
  JSON2Schema.Engine in 'src\JSON2Schema.Engine.pas',
  JSON2Schema.Runner in 'src\JSON2Schema.Runner.pas';

{$R *.res}

begin
  try
    Halt(RunJSON2Schema);
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, 'Fatal error: ' + E.Message);
      Halt(2);
    end;
  end;
end.
