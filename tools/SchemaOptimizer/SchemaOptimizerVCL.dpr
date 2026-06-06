program SchemaOptimizerVCL;

(*
--------------------------------------------------------------------------------
VCL Desktop GUI Program for optimizing and simplifying JSON Schema files.
--------------------------------------------------------------------------------
*)

uses
  Vcl.Forms,
  Vcl.XPMan, // Modern VCL native styling and themes
  SchemaOptimizer.Main in 'src\SchemaOptimizer.Main.pas' {frmMain},
  SchemaOptimizer.Engine in 'src\SchemaOptimizer.Engine.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
