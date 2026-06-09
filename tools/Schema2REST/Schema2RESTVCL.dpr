program Schema2RESTVCL;

(*
--------------------------------------------------------------------------------
VCL Desktop GUI Program for generating Horse or DMVC validated REST
endpoints from JSON Schema definitions.
--------------------------------------------------------------------------------
*)

uses
  Vcl.Forms,
  Schema2REST.Main in 'src\Schema2REST.Main.pas' {frmMain},
  Schema2REST.Templates in 'src\Schema2REST.Templates.pas',
  Schema2REST.Engine in 'src\Schema2REST.Engine.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
