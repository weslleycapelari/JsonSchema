program Schema2DelphiVCL;

(*
--------------------------------------------------------------------------------
VCL Desktop Application for generating Delphi DTO units from JSON Schemas.
--------------------------------------------------------------------------------
*)

uses
  Vcl.Forms,
  Schema2Delphi.Main in 'src\Schema2Delphi.Main.pas' {frmMain},
  Schema2Delphi.Lote in 'src\Schema2Delphi.Lote.pas' {frmLote},
  Schema2Delphi.Common in 'src\Schema2Delphi.Common.pas',
  Schema2Delphi.Sanitizer in 'src\Schema2Delphi.Sanitizer.pas',
  Schema2Delphi.TypeMapper in 'src\Schema2Delphi.TypeMapper.pas',
  Schema2Delphi.AttributeProcessor in 'src\Schema2Delphi.AttributeProcessor.pas',
  Schema2Delphi.Visitor in 'src\Schema2Delphi.Visitor.pas',
  Schema2Delphi.Utils in 'src\Schema2Delphi.Utils.pas',
  Schema2Delphi.AST in 'src\Schema2Delphi.AST.pas';

// {$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmLote, frmLote);
  Application.Run;
end.
