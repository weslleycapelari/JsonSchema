program Delphi2SchemaVCL;

(*
--------------------------------------------------------------------------------
VCL Graphical User Interface (GUI) utility for exporting JSON Schema files from
compiled Delphi types using RTTI reflection.
--------------------------------------------------------------------------------
*)

uses
  Vcl.Forms,
  Delphi2Schema.Main in 'src\Delphi2Schema.Main.pas' {frmMain},
  Delphi2Schema.Attributes in 'src\Delphi2Schema.Attributes.pas',
  Delphi2Schema.Engine in 'src\Delphi2Schema.Engine.pas',
  Delphi2Schema.Samples in 'src\Delphi2Schema.Samples.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
