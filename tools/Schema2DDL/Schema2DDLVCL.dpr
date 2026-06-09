program Schema2DDLVCL;

(*
--------------------------------------------------------------------------------
VCL Desktop GUI Program for generating relational SQL DDL scripts from
JSON Schema definitions.
--------------------------------------------------------------------------------
*)

uses
  Vcl.Forms,
  Schema2DDL.Main in 'src\Schema2DDL.Main.pas' {frmMain},
  Schema2DDL.Dialects in 'src\Schema2DDL.Dialects.pas',
  Schema2DDL.Engine in 'src\Schema2DDL.Engine.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
