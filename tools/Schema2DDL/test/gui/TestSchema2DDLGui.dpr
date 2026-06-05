program TestSchema2DDLGui;

(*
--------------------------------------------------------------------------------
GUI test runner for Schema2DDL.
--------------------------------------------------------------------------------
*)

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  DUnitTestRunner,
  Schema2DDL.Config in '..\..\src\Schema2DDL.Config.pas',
  Schema2DDL.Dialects in '..\..\src\Schema2DDL.Dialects.pas',
  Schema2DDL.Engine in '..\..\src\Schema2DDL.Engine.pas',
  Schema2DDL.Runner in '..\..\src\Schema2DDL.Runner.pas',
  TestSchema2DDL in '..\src\TestSchema2DDL.pas';

begin
  DUnitTestRunner.RunRegisteredTests;
end.
