program JSON2SchemaVCL;

(*
--------------------------------------------------------------------------------
VCL Desktop GUI Program for generating JSON Schema definitions from JSON
instance documents.
--------------------------------------------------------------------------------
*)

uses
  Vcl.Forms,
  JSON2Schema.Main in 'src\JSON2Schema.Main.pas' {frmMain},
  JSON2Schema.Engine in 'src\JSON2Schema.Engine.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
