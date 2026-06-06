program SchemaMigratorCLI;

(*
--------------------------------------------------------------------------------
Command-Line Interface (CLI) program for migrating legacy JSON Schema files
to modern specifications.
--------------------------------------------------------------------------------
*)

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  SchemaMigrator.Config in 'src\SchemaMigrator.Config.pas',
  SchemaMigrator.Engine in 'src\SchemaMigrator.Engine.pas',
  SchemaMigrator.Runner in 'src\SchemaMigrator.Runner.pas';

begin
  try
    Halt(RunSchemaMigrator);
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, 'Fatal error: ' + E.Message);
      Halt(2);
    end;
  end;
end.
