program SchemaBundlerVCL;

(*
--------------------------------------------------------------------------------
VCL Desktop GUI Program for bundling split JSON Schema files.
--------------------------------------------------------------------------------
*)

uses
  Vcl.Forms,
  Vcl.XPMan, // Modern VCL native styling and themes (Windows 11)
  SchemaBundler.Main in 'src\SchemaBundler.Main.pas' {frmMain},
  SchemaBundler.Engine in 'src\SchemaBundler.Engine.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
