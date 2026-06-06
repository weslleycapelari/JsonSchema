unit SchemaOptimizer.Main;

(*
--------------------------------------------------------------------------------
VCL Main form for the SchemaOptimizer GUI application.
--------------------------------------------------------------------------------
*)

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Clipbrd,
  System.JSON, System.IOUtils, SchemaOptimizer.Engine;

type
  TfrmMain = class(TForm)
    pnlLeft: TPanel;
    lblSchemaInput: TLabel;
    mmoSchemaInput: TMemo;
    chkRemoveUnused: TCheckBox;
    chkMergeAllOf: TCheckBox;
    chkPruneEmpty: TCheckBox;
    chkMinify: TCheckBox;
    btnLoadFile: TButton;
    pnlRight: TPanel;
    lblOutputSchema: TLabel;
    mmoOutputSchema: TMemo;
    pnlButtons: TPanel;
    btnOptimize: TButton;
    btnCopy: TButton;
    btnExport: TButton;
    pnlStatus: TPanel;
    lblStatus: TLabel;
    dlgSave: TSaveDialog;
    dlgOpen: TOpenDialog;
    splSplitter: TSplitter;
    procedure FormCreate(Sender: TObject);
    procedure btnLoadFileClick(Sender: TObject);
    procedure btnOptimizeClick(Sender: TObject);
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
  chkRemoveUnused.Checked := True;
  chkMergeAllOf.Checked := True;
  chkPruneEmpty.Checked := True;
  chkMinify.Checked := False;

  lblStatus.Caption := 'Ready';
  lblStatus.Font.Color := clWindowText;

  mmoSchemaInput.Lines.Clear;
  mmoOutputSchema.Lines.Clear;

  // Pre-load a demo schema that illustrates all optimization modes
  mmoSchemaInput.Lines.Add('{');
  mmoSchemaInput.Lines.Add('  "type": "object",');
  mmoSchemaInput.Lines.Add('  "properties": {');
  mmoSchemaInput.Lines.Add('    "name": { "$ref": "#/$defs/Used" }');
  mmoSchemaInput.Lines.Add('  },');
  mmoSchemaInput.Lines.Add('  "$defs": {');
  mmoSchemaInput.Lines.Add('    "Used": { "type": "string" },');
  mmoSchemaInput.Lines.Add('    "Unused": { "type": "integer" }');
  mmoSchemaInput.Lines.Add('  },');
  mmoSchemaInput.Lines.Add('  "allOf": [');
  mmoSchemaInput.Lines.Add('    {');
  mmoSchemaInput.Lines.Add('      "properties": {');
  mmoSchemaInput.Lines.Add('        "age": { "type": "integer" }');
  mmoSchemaInput.Lines.Add('      }');
  mmoSchemaInput.Lines.Add('    },');
  mmoSchemaInput.Lines.Add('    {}');
  mmoSchemaInput.Lines.Add('  ],');
  mmoSchemaInput.Lines.Add('  "required": ["name"]');
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
      mmoOutputSchema.Clear;
    except
      on E: Exception do
      begin
        lblStatus.Caption := 'Error loading file: ' + E.Message;
        lblStatus.Font.Color := clRed;
      end;
    end;
  end;
end;

procedure TfrmMain.btnOptimizeClick(Sender: TObject);
var
  lOptions: TOptimizerOptions;
  lOptimizer: TSchemaOptimizer;
  lSchemaJson: TJSONValue;
  lOutputText: string;
  lBytesSaved: Int64;
  lDefsRemoved: Integer;
begin
  mmoOutputSchema.Clear;
  lblStatus.Caption := 'Optimizing JSON schema...';
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
    lOptions.RemoveUnused := chkRemoveUnused.Checked;
    lOptions.MergeAllOf := chkMergeAllOf.Checked;
    lOptions.PruneEmpty := chkPruneEmpty.Checked;
    lOptions.Minify := chkMinify.Checked;

    lOptimizer := TSchemaOptimizer.Create(lOptions);
    try
      lOutputText := lOptimizer.Optimize(lSchemaJson as TJSONObject, lBytesSaved, lDefsRemoved);

      mmoOutputSchema.Text := lOutputText;
      lblStatus.Caption := Format('Optimization successful! Saved: %d bytes | Unused Defs Removed: %d', [lBytesSaved, lDefsRemoved]);
      lblStatus.Font.Color := clGreen;
    finally
      lOptimizer.Free;
    end;
  except
    on E: Exception do
    begin
      lblStatus.Caption := 'Error optimizing: ' + E.Message;
      lblStatus.Font.Color := clRed;
    end;
  end;
end;

procedure TfrmMain.btnCopyClick(Sender: TObject);
begin
  if Trim(mmoOutputSchema.Text) <> '' then
  begin
    Clipboard.SetTextBuf(PChar(mmoOutputSchema.Text));
    lblStatus.Caption := 'Optimized schema copied to clipboard.';
    lblStatus.Font.Color := clGreen;
  end
  else
  begin
    lblStatus.Caption := 'Nothing to copy. Run optimization first.';
    lblStatus.Font.Color := clRed;
  end;
end;

procedure TfrmMain.btnExportClick(Sender: TObject);
begin
  if Trim(mmoOutputSchema.Text) = '' then
  begin
    lblStatus.Caption := 'Nothing to export. Run optimization first.';
    lblStatus.Font.Color := clRed;
    Exit;
  end;

  dlgSave.Filter := 'JSON Files (*.json)|*.json|All Files (*.*)|*.*';
  dlgSave.DefaultExt := 'json';

  if dlgSave.Execute then
  begin
    try
      TFile.WriteAllText(dlgSave.FileName, mmoOutputSchema.Text, TEncoding.UTF8);
      lblStatus.Caption := 'Optimized schema exported successfully to ' + ExtractFileName(dlgSave.FileName);
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
