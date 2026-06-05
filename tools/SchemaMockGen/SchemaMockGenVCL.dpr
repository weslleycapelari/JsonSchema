program SchemaMockGenVCL;

(*
--------------------------------------------------------------------------------
VCL Desktop Application for generating mock JSON instances from JSON Schemas.
--------------------------------------------------------------------------------
*)

uses
  Vcl.Forms,
  Vcl.XPMan,
  SchemaMockGenGUI.Main in 'src\SchemaMockGenGUI.Main.pas' {frmMain},
  SchemaMockGen.Generator in 'src\SchemaMockGen.Generator.pas',
  SchemaMockGen.Utils in 'src\SchemaMockGen.Utils.pas';

// {$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
