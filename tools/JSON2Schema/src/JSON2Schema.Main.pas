unit JSON2Schema.Main;

(*
--------------------------------------------------------------------------------
VCL Main form for the JSON2Schema GUI application.
--------------------------------------------------------------------------------
*)

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Clipbrd, System.JSON,
  System.IOUtils, JSON2Schema.Engine;

type
  TfrmMain = class(TForm)
    pnlLeft: TPanel;
    lblDraft: TLabel;
    cboDraft: TComboBox;
    chkRequired: TCheckBox;
    chkInferFormats: TCheckBox;
    lblInputJSON: TLabel;
    mmoInputJSON: TMemo;
    pnlRight: TPanel;
    lblOutputSchema: TLabel;
    mmoOutputSchema: TMemo;
    pnlButtons: TPanel;
    btnGenerate: TButton;
    btnCopy: TButton;
    btnExport: TButton;
    pnlStatus: TPanel;
    lblStatus: TLabel;
    dlgSave: TSaveDialog;
    splMain: TSplitter;
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
  cboDraft.Items.Clear;
  cboDraft.Items.Add('http://json-schema.org/draft-07/schema#');
  cboDraft.Items.Add('https://json-schema.org/draft/2019-09/schema');
  cboDraft.Items.Add('https://json-schema.org/draft/2020-12/schema');
  cboDraft.ItemIndex := 0; // Default Draft 7

  chkRequired.Checked := False;
  chkInferFormats.Checked := True;
  lblStatus.Caption := 'Ready';
  lblStatus.Font.Color := clGreen;

  // Set default raw JSON
  mmoInputJSON.Lines.Clear;
  mmoInputJSON.Lines.Add('{');
  mmoInputJSON.Lines.Add('  "id": 101,');
  mmoInputJSON.Lines.Add('  "name": "Acme Corporation",');
  mmoInputJSON.Lines.Add('  "email": "contact@acme.com",');
  mmoInputJSON.Lines.Add('  "active": true,');
  mmoInputJSON.Lines.Add('  "tags": ["software", "saas"],');
  mmoInputJSON.Lines.Add('  "created_at": "2026-06-05T15:00:00Z"');
  mmoInputJSON.Lines.Add('}');
end;

procedure TfrmMain.btnGenerateClick(Sender: TObject);
var
  lJSONValue: TJSONValue;
  lGenerator: TJSON2SchemaGenerator;
  lOptions: TJSON2SchemaOptions;
  lSchemaObj: TJSONObject;
begin
  mmoOutputSchema.Clear;
  lblStatus.Caption := 'Generating Schema...';
  lblStatus.Font.Color := $000288D1;
  lblStatus.Update;

  if Trim(mmoInputJSON.Text) = '' then
  begin
    lblStatus.Caption := 'Error: Input JSON is empty.';
    lblStatus.Font.Color := clRed;
    Exit;
  end;

  lJSONValue := TJSONObject.ParseJSONValue(mmoInputJSON.Text);
  if not Assigned(lJSONValue) then
  begin
    lblStatus.Caption := 'Error: Invalid input JSON.';
    lblStatus.Font.Color := clRed;
    Exit;
  end;

  try
    lGenerator := TJSON2SchemaGenerator.Create;
    try
      lOptions.Draft := cboDraft.Text;
      lOptions.InferFormats := chkInferFormats.Checked;
      lOptions.MakeRequired := chkRequired.Checked;

      lGenerator.Options := lOptions;
      lSchemaObj := lGenerator.GenerateSchema(lJSONValue);

      if Assigned(lSchemaObj) then
      begin
        try
          mmoOutputSchema.Text := lSchemaObj.Format(2);
          lblStatus.Caption := 'JSON Schema generated successfully.';
          lblStatus.Font.Color := clGreen;
        // Exception handler for parsing/formatting
        except
          on E: Exception do
          begin
            lblStatus.Caption := 'Error formatting schema: ' + E.Message;
            lblStatus.Font.Color := clRed;
          end;
        end;
        lSchemaObj.Free;
      end
      else
      begin
        lblStatus.Caption := 'Error: Generation failed.';
        lblStatus.Font.Color := clRed;
      end;
    finally
      lGenerator.Free;
    end;
  finally
    lJSONValue.Free;
  end;
end;

procedure TfrmMain.btnCopyClick(Sender: TObject);
begin
  if Trim(mmoOutputSchema.Text) <> '' then
  begin
    Clipboard.SetTextBuf(PChar(mmoOutputSchema.Text));
    lblStatus.Caption := 'Schema copied to clipboard.';
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
  if Trim(mmoOutputSchema.Text) = '' then
  begin
    lblStatus.Caption := 'Error: Generate JSON Schema first.';
    lblStatus.Font.Color := clRed;
    Exit;
  end;

  dlgSave.Title := 'Export JSON Schema';
  dlgSave.Filter := 'JSON Schema Files (*.json)|*.json|All Files (*.*)|*.*';
  dlgSave.DefaultExt := 'json';

  if dlgSave.Execute then
  begin
    try
      TFile.WriteAllText(dlgSave.FileName, mmoOutputSchema.Text, TEncoding.UTF8);
      lblStatus.Caption := 'JSON Schema exported successfully to: ' + ExtractFileName(dlgSave.FileName);
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
