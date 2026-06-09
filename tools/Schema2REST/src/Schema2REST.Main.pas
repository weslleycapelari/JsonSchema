unit Schema2REST.Main;

(*
--------------------------------------------------------------------------------
VCL Main form for the Schema2REST GUI application.
--------------------------------------------------------------------------------
*)

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Clipbrd, System.JSON,
  System.IOUtils, Schema2REST.Engine;

type
  TfrmMain = class(TForm)
    pnlLeft: TPanel;
    lblFramework: TLabel;
    cboFramework: TComboBox;
    lblEntityName: TLabel;
    edtEntityName: TEdit;
    lblSchemaInput: TLabel;
    mmoSchemaInput: TMemo;
    pnlRight: TPanel;
    lblPascalOutput: TLabel;
    mmoPascalOutput: TMemo;
    pnlButtons: TPanel;
    btnGenerate: TButton;
    btnCopy: TButton;
    btnExport: TButton;
    pnlStatus: TPanel;
    lblStatus: TLabel;
    dlgSave: TSaveDialog;
    splMain: TSplitter;
    pnlBrandBar: TPanel;
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

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  cboFramework.Items.Clear;
  cboFramework.Items.Add('Horse');
  cboFramework.Items.Add('DMVC');
  cboFramework.ItemIndex := 0; // Horse default

  edtEntityName.Text := 'Customer';
  lblStatus.Caption := 'Ready';
  lblStatus.Font.Color := clGreen;

  // Insert default schema
  mmoSchemaInput.Lines.Clear;
  mmoSchemaInput.Lines.Add('{');
  mmoSchemaInput.Lines.Add('  "$schema": "http://json-schema.org/draft-07/schema#",');
  mmoSchemaInput.Lines.Add('  "title": "Customer",');
  mmoSchemaInput.Lines.Add('  "type": "object",');
  mmoSchemaInput.Lines.Add('  "properties": {');
  mmoSchemaInput.Lines.Add('    "id": { "type": "integer" },');
  mmoSchemaInput.Lines.Add('    "name": { "type": "string" },');
  mmoSchemaInput.Lines.Add('    "email": { "type": "string", "format": "email" }');
  mmoSchemaInput.Lines.Add('  },');
  mmoSchemaInput.Lines.Add('  "required": ["id", "name"]');
  mmoSchemaInput.Lines.Add('}');
end;

procedure TfrmMain.btnGenerateClick(Sender: TObject);
var
  lSchemaJson: TJSONObject;
  lGenerator: TSchema2RESTGenerator;
  lFramework: TRESTFramework;
  lPascal: string;
begin
  mmoPascalOutput.Clear;
  lblStatus.Caption := 'Generating...';
  lblStatus.Font.Color := $000288D1;
  lblStatus.Update;

  if Trim(mmoSchemaInput.Text) = '' then
  begin
    lblStatus.Caption := 'Error: Input JSON Schema is empty.';
    lblStatus.Font.Color := clRed;
    Exit;
  end;

  if Trim(edtEntityName.Text) = '' then
  begin
    lblStatus.Caption := 'Error: Entity name cannot be empty.';
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
      lFramework := rfHorse;
      if SameText(cboFramework.Text, 'DMVC') then
        lFramework := rfDMVC;

      lGenerator := TSchema2RESTGenerator.Create;
      try
        lGenerator.Framework := lFramework;
        lPascal := lGenerator.GenerateRESTCode(lSchemaJson, edtEntityName.Text);
        mmoPascalOutput.Text := lPascal;

        lblStatus.Caption := 'Delphi REST unit code generated successfully.';
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
  if Trim(mmoPascalOutput.Text) <> '' then
  begin
    Clipboard.SetTextBuf(PChar(mmoPascalOutput.Text));
    lblStatus.Caption := 'Generated Delphi REST unit copied to clipboard.';
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
  if Trim(mmoPascalOutput.Text) = '' then
  begin
    lblStatus.Caption := 'Error: Generate REST code first before exporting.';
    lblStatus.Font.Color := clRed;
    Exit;
  end;

  dlgSave.Title := 'Export Delphi REST Unit';
  dlgSave.Filter := 'Delphi Source Files (*.pas)|*.pas|All Files (*.*)|*.*';
  dlgSave.DefaultExt := 'pas';

  if dlgSave.Execute then
  begin
    try
      TFile.WriteAllText(dlgSave.FileName, mmoPascalOutput.Text, TEncoding.UTF8);
      lblStatus.Caption := 'Delphi REST unit exported successfully to: ' + ExtractFileName(dlgSave.FileName);
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
