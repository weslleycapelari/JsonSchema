program TestSchema2DocGui;

(*
--------------------------------------------------------------------------------
GUI test runner for Schema2Doc.
--------------------------------------------------------------------------------
*)

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  DUnitTestRunner,
  Schema2Doc.Config in '..\..\src\Schema2Doc.Config.pas',
  Schema2Doc.Engine in '..\..\src\Schema2Doc.Engine.pas',
  Schema2Doc.Runner in '..\..\src\Schema2Doc.Runner.pas',
  TestSchema2Doc in '..\src\TestSchema2Doc.pas';

begin
  DUnitTestRunner.RunRegisteredTests;
end.
