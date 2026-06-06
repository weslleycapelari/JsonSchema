program VisualTestSuiteRunnerCLI;

{$APPTYPE CONSOLE}

(*
--------------------------------------------------------------------------------
VisualTestSuiteRunner CLI Console Entry Point.
--------------------------------------------------------------------------------
*)

uses
  System.SysUtils,
  VisualTestSuiteRunner.Config in 'src\VisualTestSuiteRunner.Config.pas',
  VisualTestSuiteRunner.Engine in 'src\VisualTestSuiteRunner.Engine.pas',
  VisualTestSuiteRunner.Runner in 'src\VisualTestSuiteRunner.Runner.pas';

var
  lExitCode: Integer;
begin
  try
    lExitCode := RunTestSuiteRunner;
    ExitCode := lExitCode;
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, 'Fatal CLI Error: ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
