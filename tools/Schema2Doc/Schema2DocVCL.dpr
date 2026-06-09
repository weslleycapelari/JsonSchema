program Schema2DocVCL;

(*
--------------------------------------------------------------------------------
VCL Desktop GUI Program for generating Markdown or HTML documentation from
JSON Schema definitions.
--------------------------------------------------------------------------------
*)

uses
  Vcl.Forms,
  Schema2Doc.Main in 'src\Schema2Doc.Main.pas' {frmMain},
  Schema2Doc.Engine in 'src\Schema2Doc.Engine.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
