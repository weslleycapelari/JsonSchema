program TestSchemaValidatorGui;

(*
--------------------------------------------------------------------------------
GUI test runner for SchemaValidator integration and unit tests.
--------------------------------------------------------------------------------
*)

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  DUnitTestRunner,
  SchemaValidator.Config in '..\..\src\SchemaValidator.Config.pas',
  SchemaValidator.Utils in '..\..\src\SchemaValidator.Utils.pas',
  SchemaValidator.Formatters in '..\..\src\SchemaValidator.Formatters.pas',
  SchemaValidator.Runner in '..\..\src\SchemaValidator.Runner.pas',
  TestSchemaValidator in '..\src\TestSchemaValidator.pas';

// {$R *.RES}

begin
  DUnitTestRunner.RunRegisteredTests;
end.
