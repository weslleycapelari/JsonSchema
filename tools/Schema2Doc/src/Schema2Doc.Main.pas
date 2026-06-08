unit Schema2Doc.Main;



(*

--------------------------------------------------------------------------------

VCL Main form for the Schema2Doc GUI application.

--------------------------------------------------------------------------------

*)



interface



uses

  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,

  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Clipbrd, System.JSON,

  System.IOUtils, Vcl.ComCtrls, Vcl.OleCtrls, SHDocVw, Schema2Doc.Engine;



type

  TfrmMain = class(TForm)

    pnlLeft: TPanel;

    lblFormat: TLabel;

    cboFormat: TComboBox;

    lblTitle: TLabel;

    edtTitle: TEdit;

    lblSchemaInput: TLabel;

    mmoSchemaInput: TMemo;

    pnlRight: TPanel;

    lblDocOutput: TLabel;

    pnlButtons: TPanel;

    btnGenerate: TButton;

    btnCopy: TButton;

    btnExport: TButton;

    pnlStatus: TPanel;

    lblStatus: TLabel;

    dlgSave: TSaveDialog;

    splSplitter: TSplitter;

    pnlBrandBar: TPanel;

    pgcOutput: TPageControl;

    tsCode: TTabSheet;

    mmoDocOutput: TMemo;

    tsPreview: TTabSheet;

    wbPreview: TWebBrowser;

    procedure FormCreate(Sender: TObject);

    procedure btnGenerateClick(Sender: TObject);

    procedure btnCopyClick(Sender: TObject);

    procedure btnExportClick(Sender: TObject);

    procedure cboFormatChange(Sender: TObject);

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

  cboFormat.Items.Clear;

  cboFormat.Items.Add('Markdown');

  cboFormat.Items.Add('HTML');

  cboFormat.ItemIndex := 0; // Markdown default



  edtTitle.Text := '';

  lblStatus.Caption := 'Ready';

  lblStatus.Font.Color := $00CC6600;



  // Set visualizer default tab state

  tsPreview.TabVisible := False;

  pgcOutput.ActivePage := tsCode;



  // Set default schema

  mmoSchemaInput.Lines.Clear;

  mmoSchemaInput.Lines.Add('{');

  mmoSchemaInput.Lines.Add('  "title": "User Profile",');

  mmoSchemaInput.Lines.Add('  "description": "User profile schema with nested configuration.",');

  mmoSchemaInput.Lines.Add('  "type": "object",');

  mmoSchemaInput.Lines.Add('  "properties": {');

  mmoSchemaInput.Lines.Add('    "id": { "type": "integer", "description": "Unique identifier for the user." },');

  mmoSchemaInput.Lines.Add('    "username": { "type": "string", "description": "User login name." },');

  mmoSchemaInput.Lines.Add('    "email": { "type": "string", "format": "email", "description": "User email address." },');

  mmoSchemaInput.Lines.Add('    "settings": {');

  mmoSchemaInput.Lines.Add('      "type": "object",');

  mmoSchemaInput.Lines.Add('      "description": "Nested configuration settings.",');

  mmoSchemaInput.Lines.Add('      "properties": {');

  mmoSchemaInput.Lines.Add('        "theme": { "type": "string", "default": "dark", "description": "Visual theme color." },');

  mmoSchemaInput.Lines.Add('        "notifications": { "type": "boolean", "default": true, "description": "Enable email alerts." }');

  mmoSchemaInput.Lines.Add('      }');

  mmoSchemaInput.Lines.Add('    }');

  mmoSchemaInput.Lines.Add('  },');

  mmoSchemaInput.Lines.Add('  "required": ["id", "username", "email"]');

  mmoSchemaInput.Lines.Add('}');

end;



procedure TfrmMain.cboFormatChange(Sender: TObject);

begin

  tsPreview.TabVisible := (cboFormat.ItemIndex = 1);

  if cboFormat.ItemIndex = 0 then

    pgcOutput.ActivePage := tsCode;

end;



procedure TfrmMain.btnGenerateClick(Sender: TObject);

var

  lSchemaJson: TJSONValue;

  lGenerator: TSchema2DocGenerator;

  lOptions: TSchema2DocOptions;

  lDocText: string;

  lTempFile: string;

begin

  mmoDocOutput.Clear;

  lblStatus.Caption := 'Generating documentation...';

  lblStatus.Font.Color := $00CC6600;



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

    lGenerator := TSchema2DocGenerator.Create;

    try

      lOptions.TitleOverride := edtTitle.Text;

      lOptions.Format := dfMarkdown;

      if cboFormat.ItemIndex = 1 then

        lOptions.Format := dfHTML;



      lGenerator.Options := lOptions;

      lDocText := lGenerator.GenerateDoc(lSchemaJson as TJSONObject);

      mmoDocOutput.Text := lDocText;



      // Update WebBrowser preview if HTML is selected

      if cboFormat.ItemIndex = 1 then

      begin

        try

          lTempFile := TPath.Combine(TPath.GetTempPath, 'schema2doc_preview.html');

          TFile.WriteAllText(lTempFile, lDocText, TEncoding.UTF8);

          wbPreview.Navigate(lTempFile);

          pgcOutput.ActivePage := tsPreview; // Switch to Preview tab dynamically

        except

          on E: Exception do

            lblStatus.Caption := 'Preview Error: ' + E.Message;

        end;

      end

      else

      begin

        pgcOutput.ActivePage := tsCode;

      end;



      lblStatus.Caption := 'Documentation generated successfully.';

      lblStatus.Font.Color := clGreen;

    finally

      lGenerator.Free;

    end;

  finally

    lSchemaJson.Free;

  end;

end;



procedure TfrmMain.btnCopyClick(Sender: TObject);

begin

  if Trim(mmoDocOutput.Text) <> '' then

  begin

    Clipboard.SetTextBuf(PChar(mmoDocOutput.Text));

    lblStatus.Caption := 'Documentation copied to clipboard.';

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

  if Trim(mmoDocOutput.Text) = '' then

  begin

    lblStatus.Caption := 'Error: Generate documentation first.';

    lblStatus.Font.Color := clRed;

    Exit;

  end;



  dlgSave.Title := 'Export Documentation';

  if cboFormat.ItemIndex = 0 then

  begin

    dlgSave.Filter := 'Markdown Files (*.md)|*.md|All Files (*.*)|*.*';

    dlgSave.DefaultExt := 'md';

  end

  else

  begin

    dlgSave.Filter := 'HTML Files (*.html;*.htm)|*.html;*.htm|All Files (*.*)|*.*';

    dlgSave.DefaultExt := 'html';

  end;



  if dlgSave.Execute then

  begin

    try

      TFile.WriteAllText(dlgSave.FileName, mmoDocOutput.Text, TEncoding.UTF8);

      lblStatus.Caption := 'Documentation exported successfully to: ' + ExtractFileName(dlgSave.FileName);

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

