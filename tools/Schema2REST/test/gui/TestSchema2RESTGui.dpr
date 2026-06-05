program TestSchema2RESTGui;

(*
--------------------------------------------------------------------------------
GUI test runner for Schema2REST.
--------------------------------------------------------------------------------
*)

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  DUnitTestRunner,
  Schema2REST.Config in '..\..\src\Schema2REST.Config.pas',
  Schema2REST.Templates in '..\..\src\Schema2REST.Templates.pas',
  Schema2REST.Engine in '..\..\src\Schema2REST.Engine.pas',
  Schema2REST.Runner in '..\..\src\Schema2REST.Runner.pas',
  TestSchema2REST in '..\src\TestSchema2REST.pas';

begin
  DUnitTestRunner.RunRegisteredTests;
end.
