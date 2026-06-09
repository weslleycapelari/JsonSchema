program SchemaLinterVCL;

(*
--------------------------------------------------------------------------------
VCL Desktop GUI Program for static JSON Schema quality and security analysis.
--------------------------------------------------------------------------------
*)

uses
  Vcl.Forms,
  SchemaLinter.Main in 'src\SchemaLinter.Main.pas' {frmMain},
  SchemaLinter.Engine in 'src\SchemaLinter.Engine.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
