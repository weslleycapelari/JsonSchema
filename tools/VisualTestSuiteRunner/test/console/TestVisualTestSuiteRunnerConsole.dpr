program TestVisualTestSuiteRunnerConsole;

(*
--------------------------------------------------------------------------------
Console test runner for VisualTestSuiteRunner.
--------------------------------------------------------------------------------
*)

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  TestFramework,
  TextTestRunner,
  VisualTestSuiteRunner.Config in '..\..\src\VisualTestSuiteRunner.Config.pas',
  VisualTestSuiteRunner.Engine in '..\..\src\VisualTestSuiteRunner.Engine.pas',
  VisualTestSuiteRunner.Runner in '..\..\src\VisualTestSuiteRunner.Runner.pas',
  TestVisualTestSuiteRunner in '..\src\TestVisualTestSuiteRunner.pas';

begin
  try
    Writeln('Running VisualTestSuiteRunner Console Tests...');
    Writeln;
    with TextTestRunner.RunRegisteredTests do
      Free;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
