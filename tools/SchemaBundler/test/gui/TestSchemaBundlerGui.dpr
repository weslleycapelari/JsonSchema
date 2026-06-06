program TestSchemaBundlerGui;

(*
--------------------------------------------------------------------------------
GUI test runner for SchemaBundler.
--------------------------------------------------------------------------------
*)

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  DUnitTestRunner,
  SchemaBundler.Config in '..\..\src\SchemaBundler.Config.pas',
  SchemaBundler.Engine in '..\..\src\SchemaBundler.Engine.pas',
  SchemaBundler.Runner in '..\..\src\SchemaBundler.Runner.pas',
  TestSchemaBundler in '..\src\TestSchemaBundler.pas';

begin
  DUnitTestRunner.RunRegisteredTests;
end.
