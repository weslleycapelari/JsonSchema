program TestSchemaMockGenGui;

(*
--------------------------------------------------------------------------------
GUI test runner for SchemaMockGen integration and unit tests.
--------------------------------------------------------------------------------
*)

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  DUnitTestRunner,
  SchemaMockGen.Config in '..\..\src\SchemaMockGen.Config.pas',
  SchemaMockGen.Utils in '..\..\src\SchemaMockGen.Utils.pas',
  SchemaMockGen.Generator in '..\..\src\SchemaMockGen.Generator.pas',
  SchemaMockGen.Runner in '..\..\src\SchemaMockGen.Runner.pas',
  TestSchemaMockGen in '..\src\TestSchemaMockGen.pas';

// {$R *.RES}

begin
  DUnitTestRunner.RunRegisteredTests;
end.
