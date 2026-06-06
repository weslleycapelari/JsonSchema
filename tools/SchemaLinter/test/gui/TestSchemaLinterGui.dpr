program TestSchemaLinterGui;

(*
--------------------------------------------------------------------------------
GUI test runner for SchemaLinter.
--------------------------------------------------------------------------------
*)

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  DUnitTestRunner,
  SchemaLinter.Config in '..\..\src\SchemaLinter.Config.pas',
  SchemaLinter.Engine in '..\..\src\SchemaLinter.Engine.pas',
  SchemaLinter.Runner in '..\..\src\SchemaLinter.Runner.pas',
  TestSchemaLinter in '..\src\TestSchemaLinter.pas';

begin
  DUnitTestRunner.RunRegisteredTests;
end.
