unit SchemaMigrator.Main;

(*
--------------------------------------------------------------------------------
VCL Main form for the SchemaMigrator GUI application.
--------------------------------------------------------------------------------
*)

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Clipbrd, System.JSON,
  System.IOUtils, SchemaMigrator.Engine;

type
  TfrmMain = class(TForm)
    pnlLeft: TPanel;
    lblSchemaInput: TLabel;
    btnLoadFile: TButton;
    mmoSchemaInput: TMemo;
    chkIndent: TCheckBox;
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
    splMain: TSplitter;
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
  lblStatus.Caption := 'Ready';
  lblStatus.Font.Color := clGreen;
  chkIndent.Checked := True;
end;

procedure TfrmMain.btnLoadFileClick(Sender: TObject);
begin
  dlgOpen.Filter := 'JSON Schema Files (*.json)|*.json|All Files (*.*)|*.*';
  if dlgOpen.Execute then
  begin
    try
      mmoSchemaInput.Lines.LoadFromFile(dlgOpen.FileName, TEncoding.UTF8);
      lblStatus.Caption := 'File loaded: ' + ExtractFileName(dlgOpen.FileName);
      lblStatus.Font.Color := clGreen;
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
  lSchemaJson: TJSONValue;
  lMigrator: TSchemaMigrator;
  lOutputText: string;
  lTempObj: TJSONObject;
begin
  mmoMigratedOutput.Clear;
  lblStatus.Caption := 'Migrating...';
  lblStatus.Font.Color := $000288D1;
  lblStatus.Update;

  if Trim(mmoSchemaInput.Text) = '' then
  begin
    lblStatus.Caption := 'Error: Input schema is empty.';
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
