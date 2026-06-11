program SchemaMockGenCLI;

(*
--------------------------------------------------------------------------------
Command-Line Interface (CLI) utility for generating mock JSON instances
from JSON Schemas using the constraint-driven generator engine.
--------------------------------------------------------------------------------
*)

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  SchemaMockGen.Config in 'src\SchemaMockGen.Config.pas',
  SchemaMockGen.Utils in 'src\SchemaMockGen.Utils.pas',
  SchemaMockGen.Generator in 'src\SchemaMockGen.Generator.pas',
  SchemaMockGen.Runner in 'src\SchemaMockGen.Runner.pas';

{$R *.res}

begin
  try
    Halt(RunSchemaMockGen);
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, 'Fatal error: ' + E.Message);
      Halt(2);
    end;
  end;
end.
