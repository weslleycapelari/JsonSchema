program SchemaLinterCLI;

(*
--------------------------------------------------------------------------------
Command-Line Interface (CLI) program for analyzing JSON Schema quality
and security.
--------------------------------------------------------------------------------
*)

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  SchemaLinter.Config in 'src\SchemaLinter.Config.pas',
  SchemaLinter.Engine in 'src\SchemaLinter.Engine.pas',
  SchemaLinter.Runner in 'src\SchemaLinter.Runner.pas';

{$R *.res}

begin
  try
    Halt(RunSchemaLinter);
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, 'Fatal error: ' + E.Message);
      Halt(2);
    end;
  end;
end.
