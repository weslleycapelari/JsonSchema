program TestJSON2SchemaGui;

(*
--------------------------------------------------------------------------------
GUI test runner for JSON2Schema.
--------------------------------------------------------------------------------
*)

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  DUnitTestRunner,
  JSON2Schema.Config in '..\..\src\JSON2Schema.Config.pas',
  JSON2Schema.Engine in '..\..\src\JSON2Schema.Engine.pas',
  JSON2Schema.Runner in '..\..\src\JSON2Schema.Runner.pas',
  TestJSON2Schema in '..\src\TestJSON2Schema.pas';

begin
  DUnitTestRunner.RunRegisteredTests;
end.
