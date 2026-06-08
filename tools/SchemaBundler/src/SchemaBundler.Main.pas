unit SchemaBundler.Main;

(*
--------------------------------------------------------------------------------
VCL Main form for the SchemaBundler GUI application.
--------------------------------------------------------------------------------
*)

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Clipbrd,
  System.JSON, System.IOUtils, SchemaBundler.Engine;

type
  TfrmMain = class(TForm)
    pnlLeft: TPanel;
    lblSchemaInput: TLabel;
    mmoSchemaInput: TMemo;
    chkLegacy: TCheckBox;
    chkIndent: TCheckBox;
    btnSelectFile: TButton;
    edtFilePath: TEdit;
    lblFilePath: TLabel;
    pnlRight: TPanel;
    lblBundledOutput: TLabel;
    mmoBundledOutput: TMemo;
    pnlButtons: TPanel;
    btnGenerate: TButton;
    btnCopy: TButton;
    btnExport: TButton;
    pnlStatus: TPanel;
    lblStatus: TLabel;
    dlgSave: TSaveDialog;
    dlgOpen: TOpenDialog;
    splSplitter: TSplitter;
    pnlBrandBar: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure btnSelectFileClick(Sender: TObject);
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
  chkLegacy.Checked := False;
  chkIndent.Checked := True;
  edtFilePath.Text := '';

  lblStatus.Caption := 'Ready. Select a root schema file from disk to start.';
  lblStatus.Font.Color := $00CC6600;

  mmoSchemaInput.Lines.Clear;
  mmoBundledOutput.Lines.Clear;
end;

procedure TfrmMain.btnSelectFileClick(Sender: TObject);
begin
  dlgOpen.Filter := 'JSON Schema Files (*.json)|*.json|All Files (*.*)|*.*';

  if dlgOpen.Execute then
  begin
    edtFilePath.Text := dlgOpen.FileName;
    try
      mmoSchemaInput.Text := TFile.ReadAllText(dlgOpen.FileName, TEncoding.UTF8);
      lblStatus.Caption := 'Loaded file: ' + ExtractFileName(dlgOpen.FileName);
      lblStatus.Font.Color := clGreen;
      mmoBundledOutput.Clear;
    except
      on E: Exception do
      begin
        lblStatus.Caption := 'Error reading file: ' + E.Message;
        lblStatus.Font.Color := clRed;
      end;
    end;
  end;
end;

procedure TfrmMain.btnGenerateClick(Sender: TObject);
var
  lBundler: TSchemaBundler;
  lOptions: TSchemaBundlerOptions;
  lBundledText: string;
begin
  mmoBundledOutput.Clear;
  lblStatus.Caption := 'Consolidating schema...';
  lblStatus.Font.Color := $00CC6600;

  if edtFilePath.Text = '' then
  begin
    lblStatus.Caption := 'Error: You must select a root schema file from disk to resolve relative paths.';
    lblStatus.Font.Color := clRed;
    Exit;
  end;

  if not FileExists(edtFilePath.Text) then
  begin
    lblStatus.Caption := 'Error: Selected file no longer exists.';
    lblStatus.Font.Color := clRed;
    Exit;
  end;

  try
    // Save any edits made in the memo back to the file temporarily
    // so we bundle the active edits
    try
      TFile.WriteAllText(edtFilePath.Text, mmoSchemaInput.Text, TEncoding.UTF8);
    except
      on E: Exception do
      begin
        lblStatus.Caption := 'Error saving temporary edits: ' + E.Message;
        lblStatus.Font.Color := clRed;
        Exit;
      end;
    end;

    lBundler := TSchemaBundler.Create;
    try
      lOptions.UseLegacyDefinitions := chkLegacy.Checked;
      lOptions.IndentOutput := chkIndent.Checked;
      lBundler.Options := lOptions;

      lBundledText := lBundler.Bundle(edtFilePath.Text);
      mmoBundledOutput.Text := lBundledText;

      lblStatus.Caption := 'Schema bundled successfully.';
      lblStatus.Font.Color := clGreen;
    finally
      lBundler.Free;
    end;
  except
    on E: Exception do
    begin
      lblStatus.Caption := 'Error bundling: ' + E.Message;
      lblStatus.Font.Color := clRed;
    end;
  end;
end;

procedure TfrmMain.btnCopyClick(Sender: TObject);
begin
  if Trim(mmoBundledOutput.Text) <> '' then
  begin
    Clipboard.SetTextBuf(PChar(mmoBundledOutput.Text));
    lblStatus.Caption := 'Bundled schema copied to clipboard.';
    lblStatus.Font.Color := clGreen;
  end else
  begin
    lblStatus.Caption := 'Nothing to copy. Run bundling first.';
    lblStatus.Font.Color := clRed;
  end;
end;

procedure TfrmMain.btnExportClick(Sender: TObject);
begin
  if Trim(mmoBundledOutput.Text) = '' then
  begin
    lblStatus.Caption := 'Nothing to export. Run bundling first.';
    lblStatus.Font.Color := clRed;
    Exit;
  end;

  dlgSave.Filter := 'JSON Files (*.json)|*.json|All Files (*.*)|*.*';
  dlgSave.DefaultExt := 'json';

  if dlgSave.Execute then
  begin
    try
      TFile.WriteAllText(dlgSave.FileName, mmoBundledOutput.Text, TEncoding.UTF8);
      lblStatus.Caption := 'Bundled schema exported successfully to ' + ExtractFileName(dlgSave.FileName);
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

