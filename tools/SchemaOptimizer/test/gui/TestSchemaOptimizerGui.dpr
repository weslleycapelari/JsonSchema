program TestSchemaOptimizerGui;

(*
--------------------------------------------------------------------------------
GUI test runner for SchemaOptimizer.
--------------------------------------------------------------------------------
*)

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  DUnitTestRunner,
  SchemaOptimizer.Config in '..\..\src\SchemaOptimizer.Config.pas',
  SchemaOptimizer.Engine in '..\..\src\SchemaOptimizer.Engine.pas',
  SchemaOptimizer.Runner in '..\..\src\SchemaOptimizer.Runner.pas',
  TestSchemaOptimizer in '..\src\TestSchemaOptimizer.pas';

begin
  DUnitTestRunner.RunRegisteredTests;
end.
