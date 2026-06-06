program VisualTestSuiteRunnerVCL;

(*
--------------------------------------------------------------------------------
VCL Desktop GUI Program for running JSON Schema Test Suite suites.
--------------------------------------------------------------------------------
*)

uses
  Vcl.Forms,
  Vcl.XPMan, // Modern VCL native styling and themes
  VisualTestSuiteRunner.Main in 'src\VisualTestSuiteRunner.Main.pas' {frmMain},
  VisualTestSuiteRunner.Engine in 'src\VisualTestSuiteRunner.Engine.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
