program Schema2Delphi;

uses
  Vcl.Forms,
  Schema2Delphi.Main in 'Schema2Delphi.Main.pas' {frmMain},
  Schema2Delphi.Lote in 'Schema2Delphi.Lote.pas' {frmLote},
  Schema2Delphi.Visitor in 'Schema2Delphi.Visitor.pas',
  Schema2Delphi.Utils in 'Schema2Delphi.Utils.pas',
  JsonSchema.Common.Utils in '..\..\src\JsonSchema.Common.Utils.pas',
  JsonSchema in '..\..\src\JsonSchema.pas',
  JsonSchema.Registry.Base in '..\..\src\JsonSchema.Registry.Base.pas',
  JsonSchema.Registry.Resource in '..\..\src\JsonSchema.Registry.Resource.pas',
  JsonSchema.Registry.Types in '..\..\src\JsonSchema.Registry.Types.pas',
  JsonSchema.Registry.Uri.Builder in '..\..\src\JsonSchema.Registry.Uri.Builder.pas',
  JsonSchema.Registry.Uri.ParseResult in '..\..\src\JsonSchema.Registry.Uri.ParseResult.pas',
  JsonSchema.Registry.Uri in '..\..\src\JsonSchema.Registry.Uri.pas',
  JsonSchema.Registry.Uri.Validator in '..\..\src\JsonSchema.Registry.Uri.Validator.pas',
  JsonSchema.Registry.Utils in '..\..\src\JsonSchema.Registry.Utils.pas',
  JsonSchema.Translate.enUS in '..\..\src\JsonSchema.Translate.enUS.pas',
  JsonSchema.Translate.Interfaces in '..\..\src\JsonSchema.Translate.Interfaces.pas',
  JsonSchema.Translate.ptBR in '..\..\src\JsonSchema.Translate.ptBR.pas',
  JsonSchema.Translate.Types in '..\..\src\JsonSchema.Translate.Types.pas',
  JsonSchema.Translate.Utils in '..\..\src\JsonSchema.Translate.Utils.pas',
  JsonSchema.Validation.Base in '..\..\src\JsonSchema.Validation.Base.pas',
  JsonSchema.Validation.Draft6 in '..\..\src\JsonSchema.Validation.Draft6.pas',
  JsonSchema.Validation.Draft7 in '..\..\src\JsonSchema.Validation.Draft7.pas',
  JsonSchema.Validation.Draft2019_09 in '..\..\src\JsonSchema.Validation.Draft2019_09.pas',
  JsonSchema.Validation.Draft2020_12 in '..\..\src\JsonSchema.Validation.Draft2020_12.pas',
  JsonSchema.Validation.Interfaces in '..\..\src\JsonSchema.Validation.Interfaces.pas',
  JsonSchema.Validation.Types in '..\..\src\JsonSchema.Validation.Types.pas',
  JsonSchema.Visitors.Base in '..\..\src\JsonSchema.Visitors.Base.pas',
  JsonSchema.Visitors.Interfaces in '..\..\src\JsonSchema.Visitors.Interfaces.pas',
  JsonSchema.Visitors.Types in '..\..\src\JsonSchema.Visitors.Types.pas',
  JsonSchema.Walker in '..\..\src\JsonSchema.Walker.pas',
  JsonSchema.Walker.Types in '..\..\src\JsonSchema.Walker.Types.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmLote, frmLote);
  Application.Run;
end.
