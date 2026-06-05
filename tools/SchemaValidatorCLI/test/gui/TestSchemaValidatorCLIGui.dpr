program TestSchemaValidatorCLIGui;

(*
--------------------------------------------------------------------------------
GUI test runner for SchemaValidatorCLI integration and unit tests.
--------------------------------------------------------------------------------
*)

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  DUnitTestRunner,
  SchemaValidatorCLI.Config in '..\..\src\SchemaValidatorCLI.Config.pas',
  SchemaValidatorCLI.Utils in '..\..\src\SchemaValidatorCLI.Utils.pas',
  SchemaValidatorCLI.Formatters in '..\..\src\SchemaValidatorCLI.Formatters.pas',
  SchemaValidatorCLI.Runner in '..\..\src\SchemaValidatorCLI.Runner.pas',
  TestSchemaValidatorCLI in '..\src\TestSchemaValidatorCLI.pas';

// {$R *.RES}

begin
  DUnitTestRunner.RunRegisteredTests;
end.
