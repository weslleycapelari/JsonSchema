program SchemaMigratorVCL;

(*
--------------------------------------------------------------------------------
VCL Desktop GUI Program for migrating legacy JSON Schema files.
--------------------------------------------------------------------------------
*)

uses
  Vcl.Forms,
  Vcl.XPMan, // Modern VCL native styling and themes (Windows 11)
  SchemaMigrator.Main in 'src\SchemaMigrator.Main.pas' {frmMain},
  SchemaMigrator.Engine in 'src\SchemaMigrator.Engine.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
