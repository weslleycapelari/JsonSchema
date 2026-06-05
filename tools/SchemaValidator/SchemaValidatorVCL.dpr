program SchemaValidatorVCL;

(*
--------------------------------------------------------------------------------
VCL Desktop Application for validating JSON instance files against JSON schemas.
--------------------------------------------------------------------------------
*)

uses
  Vcl.Forms,
  Vcl.XPMan,
  SchemaValidator.Main in 'src\SchemaValidator.Main.pas' {frmMain},
  SchemaValidator.Config in 'src\SchemaValidator.Config.pas',
  SchemaValidator.Formatters in 'src\SchemaValidator.Formatters.pas',
  SchemaValidator.Runner in 'src\SchemaValidator.Runner.pas',
  SchemaValidator.Utils in 'src\SchemaValidator.Utils.pas';

// {$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
