unit SchemaMigrator.Main;

(*
--------------------------------------------------------------------------------
VCL Main form for the SchemaMigrator GUI application.
--------------------------------------------------------------------------------
*)

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Clipbrd,
  System.JSON, System.IOUtils, SchemaMigrator.Engine;

type
  TfrmMain = class(TForm)
    pnlLeft: TPanel;
    lblSchemaInput: TLabel;
    mmoSchemaInput: TMemo;
    chkIndent: TCheckBox;
    btnLoadFile: TButton;
    pnlRight: TPanel;
    lblMigratedOutput: TLabel;
    mmoMigratedOutput: TMemo;
    pnlButtons: TPanel;
    btnMigrate: TButton;
    btnCopy: TButton;
    btnExport: TButton;
    pnlStatus: TPanel;
    lblStatus: TLabel;
    dlgSave: TSaveDialog;
    dlgOpen: TOpenDialog;
    splSplitter: TSplitter;
    procedure FormCreate(Sender: TObject);
    procedure btnLoadFileClick(Sender: TObject);
    procedure btnMigrateClick(Sender: TObject);
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
  chkIndent.Checked := True;
  lblStatus.Caption := 'Ready';
  lblStatus.Font.Color := clWindowText;

  mmoSchemaInput.Lines.Clear;
  mmoMigratedOutput.Lines.Clear;

  // Pre-load a small Draft 4 schema for demo
  mmoSchemaInput.Lines.Add('{');
  mmoSchemaInput.Lines.Add('  "$schema": "http://json-schema.org/draft-04/schema#",');
  mmoSchemaInput.Lines.Add('  "id": "http://example.com/legacy.json",');
  mmoSchemaInput.Lines.Add('  "title": "Legacy Schema",');
  mmoSchemaInput.Lines.Add('  "type": "object",');
  mmoSchemaInput.Lines.Add('  "definitions": {');
  mmoSchemaInput.Lines.Add('    "userId": { "type": "integer" }');
  mmoSchemaInput.Lines.Add('  },');
  mmoSchemaInput.Lines.Add('  "properties": {');
  mmoSchemaInput.Lines.Add('    "user_id": { "$ref": "#/definitions/userId" }');
  mmoSchemaInput.Lines.Add('  },');
  mmoSchemaInput.Lines.Add('  "dependencies": {');
  mmoSchemaInput.Lines.Add('    "user_id": ["session_token"]');
  mmoSchemaInput.Lines.Add('  }');
  mmoSchemaInput.Lines.Add('}');
end;

procedure TfrmMain.btnLoadFileClick(Sender: TObject);
begin
  dlgOpen.Filter := 'JSON Schema Files (*.json)|*.json|All Files (*.*)|*.*';
  if dlgOpen.Execute then
  begin
    try
      mmoSchemaInput.Text := TFile.ReadAllText(dlgOpen.FileName, TEncoding.UTF8);
      lblStatus.Caption := 'Loaded: ' + ExtractFileName(dlgOpen.FileName);
      lblStatus.Font.Color := clGreen;
      mmoMigratedOutput.Clear;
    except
      on E: Exception do
      begin
        lblStatus.Caption := 'Error loading file: ' + E.Message;
        lblStatus.Font.Color := clRed;
      end;
    end;
  end;
end;

procedure TfrmMain.btnMigrateClick(Sender: TObject);
var
  lMigrator: TSchemaMigrator;
  lSchemaJson: TJSONValue;
  lOutputText: string;
  lTempObj: TJSONObject;
begin
  mmoMigratedOutput.Clear;
  lblStatus.Caption := 'Migrating schema to Draft 2020-12...';
  lblStatus.Font.Color := clWindowText;

  if Trim(mmoSchemaInput.Text) = '' then
  begin
    lblStatus.Caption := 'Error: Input JSON Schema is empty.';
    lblStatus.Font.Color := clRed;
    Exit;
  end;

  lSchemaJson := TJSONObject.ParseJSONValue(mmoSchemaInput.Text);
  if not Assigned(lSchemaJson) or not (lSchemaJson is TJSONObject) then
  begin
    if Assigned(lSchemaJson) then
      lSchemaJson.Free;
    lblStatus.Caption := 'Error: Input is not a valid JSON Object.';
    lblStatus.Font.Color := clRed;
    Exit;
  end;

  try
    lMigrator := TSchemaMigrator.Create;
    try
      lOutputText := lMigrator.Migrate(lSchemaJson as TJSONObject);

      if not chkIndent.Checked then
      begin
        lTempObj := TJSONObject.ParseJSONValue(lOutputText) as TJSONObject;
        try
          lOutputText := lTempObj.ToJSON;
        finally
          lTempObj.Free;
        end;
      end;

      mmoMigratedOutput.Text := lOutputText;
      lblStatus.Caption := 'Schema migrated successfully to Draft 2020-12.';
      lblStatus.Font.Color := clGreen;
    finally
      lMigrator.Free;
    end;
  except
    on E: Exception do
    begin
      lblStatus.Caption := 'Error migrating: ' + E.Message;
      lblStatus.Font.Color := clRed;
    end;
  end;
end;

procedure TfrmMain.btnCopyClick(Sender: TObject);
begin
  if Trim(mmoMigratedOutput.Text) <> '' then
  begin
    Clipboard.SetTextBuf(PChar(mmoMigratedOutput.Text));
    lblStatus.Caption := 'Migrated schema copied to clipboard.';
    lblStatus.Font.Color := clGreen;
  end
  else
  begin
    lblStatus.Caption := 'Nothing to copy. Run migration first.';
    lblStatus.Font.Color := clRed;
  end;
end;

procedure TfrmMain.btnExportClick(Sender: TObject);
begin
  if Trim(mmoMigratedOutput.Text) = '' then
  begin
    lblStatus.Caption := 'Nothing to export. Run migration first.';
    lblStatus.Font.Color := clRed;
    Exit;
  end;

  dlgSave.Filter := 'JSON Files (*.json)|*.json|All Files (*.*)|*.*';
  dlgSave.DefaultExt := 'json';

  if dlgSave.Execute then
  begin
    try
      TFile.WriteAllText(dlgSave.FileName, mmoMigratedOutput.Text, TEncoding.UTF8);
      lblStatus.Caption := 'Migrated schema exported successfully to ' + ExtractFileName(dlgSave.FileName);
      lblStatus.Font.Color := clGreen;
    except
      on E: Exception do
      begin
        lblStatus.Caption := 'Error exporting schema: ' + E.Message;
        lblStatus.Font.Color := clRed;
      end;
    end;
  end;
end;

end.
