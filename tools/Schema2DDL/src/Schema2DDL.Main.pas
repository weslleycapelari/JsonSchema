unit Schema2DDL.Main;

(*
--------------------------------------------------------------------------------
VCL Main form for the Schema2DDL GUI application.
--------------------------------------------------------------------------------
*)

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Clipbrd, System.JSON,
  Schema2DDL.Engine, Schema2DDL.Dialects;

type
  TfrmMain = class(TForm)
    pnlBrandBar: TPanel;
    pnlLeft: TPanel;
    lblDialect: TLabel;
    cboDialect: TComboBox;
    chkGenerateDrop: TCheckBox;
    chkAutoIncPk: TCheckBox;
    chkQuote: TCheckBox;
    lblSchemaInput: TLabel;
    mmoSchemaInput: TMemo;
    pnlRight: TPanel;
    lblDdlOutput: TLabel;
    mmoDdlOutput: TMemo;
    pnlButtons: TPanel;
    btnGenerate: TButton;
    btnCopy: TButton;
    btnExport: TButton;
    pnlStatus: TPanel;
    lblStatus: TLabel;
    dlgSave: TSaveDialog;
    splSplitter: TSplitter;
    procedure FormCreate(Sender: TObject);
    procedure btnGenerateClick(Sender: TObject);
    procedure btnCopyClick(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

uses
  System.IOUtils;

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  cboDialect.Items.Clear;
  cboDialect.Items.Add('PostgreSQL');
  cboDialect.Items.Add('Firebird');
  cboDialect.Items.Add('SQLite');
  cboDialect.Items.Add('SQLServer');
  cboDialect.ItemIndex := 0; // PostgreSQL default

  chkGenerateDrop.Checked := False;
  chkAutoIncPk.Checked := True;
  chkQuote.Checked := False;

  lblStatus.Caption := 'Ready';
  lblStatus.Font.Color := $00CC6600; // Brand Classic Blue

  // Insert a simple default schema snippet for the user
  mmoSchemaInput.Lines.Clear;
  mmoSchemaInput.Lines.Add('{');
  mmoSchemaInput.Lines.Add('  "$schema": "http://json-schema.org/draft-07/schema#",');
  mmoSchemaInput.Lines.Add('  "title": "Customer",');
  mmoSchemaInput.Lines.Add('  "type": "object",');
  mmoSchemaInput.Lines.Add('  "properties": {');
  mmoSchemaInput.Lines.Add('    "id": { "type": "integer" },');
  mmoSchemaInput.Lines.Add('    "name": { "type": "string", "maxLength": 100 },');
  mmoSchemaInput.Lines.Add('    "email": { "type": "string", "format": "email" },');
  mmoSchemaInput.Lines.Add('    "active": { "type": "boolean", "default": true }');
  mmoSchemaInput.Lines.Add('  },');
  mmoSchemaInput.Lines.Add('  "required": ["id", "name"]');
  mmoSchemaInput.Lines.Add('}');
end;

procedure TfrmMain.btnGenerateClick(Sender: TObject);
var
  lSchemaJson: TJSONObject;
  lGenerator: TSchema2DDLGenerator;
  lDialect: ISQLDialect;
  lDdl: string;
begin
  mmoDdlOutput.Clear;
  lblStatus.Caption := 'Generating...';
  lblStatus.Font.Color := clWindowText;

  if Trim(mmoSchemaInput.Text) = '' then
  begin
    lblStatus.Caption := 'Error: Input JSON Schema is empty.';
    lblStatus.Font.Color := clRed;
    Exit;
  end;

  try
    lSchemaJson := TJSONObject.ParseJSONValue(mmoSchemaInput.Text) as TJSONObject;
    if not Assigned(lSchemaJson) then
    begin
      lblStatus.Caption := 'Error: Failed to parse text as a valid JSON Object.';
      lblStatus.Font.Color := clRed;
      Exit;
    end;

    try
      lDialect := TDialectFactory.CreateDialect(cboDialect.Text);
      lGenerator := TSchema2DDLGenerator.Create;
      try
        lGenerator.Dialect := lDialect;
        lGenerator.GenerateDropTable := chkGenerateDrop.Checked;
        lGenerator.AutoIncPk := chkAutoIncPk.Checked;
        lGenerator.QuoteIdentifiers := chkQuote.Checked;

        lDdl := lGenerator.GenerateDDL(lSchemaJson, '');
        mmoDdlOutput.Text := lDdl;

        lblStatus.Caption := 'SQL DDL script generated successfully.';
        lblStatus.Font.Color := clGreen;
      finally
        lGenerator.Free;
      end;
    finally
      lSchemaJson.Free;
    end;
  except
    on E: Exception do
    begin
      lblStatus.Caption := 'Error: ' + E.Message;
      lblStatus.Font.Color := clRed;
    end;
  end;
end;

procedure TfrmMain.btnCopyClick(Sender: TObject);
begin
  if Trim(mmoDdlOutput.Text) <> '' then
  begin
    Clipboard.SetTextBuf(PChar(mmoDdlOutput.Text));
    lblStatus.Caption := 'SQL DDL script copied to clipboard.';
    lblStatus.Font.Color := clGreen;
  end
  else
  begin
    lblStatus.Caption := 'Nothing to copy.';
    lblStatus.Font.Color := clRed;
  end;
end;

procedure TfrmMain.btnExportClick(Sender: TObject);
begin
  if Trim(mmoDdlOutput.Text) = '' then
  begin
    lblStatus.Caption := 'Error: Generate DDL first before exporting.';
    lblStatus.Font.Color := clRed;
    Exit;
  end;

  dlgSave.Title := 'Export SQL DDL Script';
  dlgSave.Filter := 'SQL Files (*.sql)|*.sql|All Files (*.*)|*.*';
  dlgSave.DefaultExt := 'sql';

  if dlgSave.Execute then
  begin
    try
      TFile.WriteAllText(dlgSave.FileName, mmoDdlOutput.Text, TEncoding.UTF8);
      lblStatus.Caption := 'SQL DDL script exported successfully to: ' + ExtractFileName(dlgSave.FileName);
      lblStatus.Font.Color := clGreen;
    except
      on E: Exception do
      begin
        lblStatus.Caption := 'Failed to export file: ' + E.Message;
        lblStatus.Font.Color := clRed;
      end;
    end;
  end;
end;

end.
