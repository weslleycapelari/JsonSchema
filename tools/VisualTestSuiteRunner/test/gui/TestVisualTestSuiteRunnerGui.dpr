program TestVisualTestSuiteRunnerGui;

(*
--------------------------------------------------------------------------------
GUI test runner for VisualTestSuiteRunner.
--------------------------------------------------------------------------------
*)

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  DUnitTestRunner,
  VisualTestSuiteRunner.Config in '..\..\src\VisualTestSuiteRunner.Config.pas',
  VisualTestSuiteRunner.Engine in '..\..\src\VisualTestSuiteRunner.Engine.pas',
  VisualTestSuiteRunner.Runner in '..\..\src\VisualTestSuiteRunner.Runner.pas',
  TestVisualTestSuiteRunner in '..\src\TestVisualTestSuiteRunner.pas';

begin
  DUnitTestRunner.RunRegisteredTests;
end.
