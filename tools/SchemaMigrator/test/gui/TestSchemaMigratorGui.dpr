program TestSchemaMigratorGui;

(*
--------------------------------------------------------------------------------
GUI test runner for SchemaMigrator.
--------------------------------------------------------------------------------
*)

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  DUnitTestRunner,
  SchemaMigrator.Config in '..\..\src\SchemaMigrator.Config.pas',
  SchemaMigrator.Engine in '..\..\src\SchemaMigrator.Engine.pas',
  SchemaMigrator.Runner in '..\..\src\SchemaMigrator.Runner.pas',
  TestSchemaMigrator in '..\src\TestSchemaMigrator.pas';

begin
  DUnitTestRunner.RunRegisteredTests;
end.
