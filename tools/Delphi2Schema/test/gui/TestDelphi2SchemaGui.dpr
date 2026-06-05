program TestDelphi2SchemaGui;

(*
--------------------------------------------------------------------------------
GUI test runner for Delphi2Schema integration and unit tests.
--------------------------------------------------------------------------------
*)

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  DUnitTestRunner,
  Delphi2Schema.Config in '..\..\src\Delphi2Schema.Config.pas',
  Delphi2Schema.Attributes in '..\..\src\Delphi2Schema.Attributes.pas',
  Delphi2Schema.Engine in '..\..\src\Delphi2Schema.Engine.pas',
  Delphi2Schema.Samples in '..\..\src\Delphi2Schema.Samples.pas',
  TestDelphi2Schema in '..\src\TestDelphi2Schema.pas';

begin
  DUnitTestRunner.RunRegisteredTests;
end.
