unit SchemaLinter.Main;

(*
--------------------------------------------------------------------------------
VCL Main form for the SchemaLinter GUI application.
--------------------------------------------------------------------------------
*)

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Clipbrd,
  System.JSON, System.IOUtils, SchemaLinter.Engine;

type
  TfrmMain = class(TForm)
    pnlLeft: TPanel;
    lblMinSeverity: TLabel;
    cboMinSeverity: TComboBox;
    lblSchemaInput: TLabel;
    mmoSchemaInput: TMemo;
    pnlRight: TPanel;
    lblFindings: TLabel;
    lvwFindings: TListView;
    pnlButtons: TPanel;
    btnAnalyze: TButton;
    btnCopy: TButton;
    btnExport: TButton;
    pnlStatus: TPanel;
    lblStatus: TLabel;
    dlgSave: TSaveDialog;
    splMain: TSplitter;
    procedure FormCreate(Sender: TObject);
    procedure btnAnalyzeClick(Sender: TObject);
    procedure btnCopyClick(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
  private
    function SeverityToString(pSeverity: TSeverity): string;
    function GetMarkdownReport: string;
    function GetJSONReport: string;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  cboMinSeverity.Items.Clear;
  cboMinSeverity.Items.Add('Info');
  cboMinSeverity.Items.Add('Warning');
  cboMinSeverity.Items.Add('Error');
  cboMinSeverity.ItemIndex := 0; // Info default

  lblStatus.Caption := 'Ready';
  lblStatus.Font.Color := clGreen;

  // Set default schema with some conflicts to demonstrate
  mmoSchemaInput.Lines.Clear;
  mmoSchemaInput.Lines.Add('{');
  mmoSchemaInput.Lines.Add('  "title": "",'); // missing root title
  mmoSchemaInput.Lines.Add('  "type": "object",');
  mmoSchemaInput.Lines.Add('  "properties": {');
  mmoSchemaInput.Lines.Add('    "age": {');
  mmoSchemaInput.Lines.Add('      "type": "integer",');
  mmoSchemaInput.Lines.Add('      "minimum": 100,');
  mmoSchemaInput.Lines.Add('      "maximum": 50'); // limit conflict
  mmoSchemaInput.Lines.Add('    },');
  mmoSchemaInput.Lines.Add('    "email": {');
  mmoSchemaInput.Lines.Add('      "type": "string"'); // missing description
  mmoSchemaInput.Lines.Add('    },');
  mmoSchemaInput.Lines.Add('    "pattern_unsafe": {');
  mmoSchemaInput.Lines.Add('      "type": "string",');
  mmoSchemaInput.Lines.Add('      "pattern": "^(a+)+$"'); // ReDoS
  mmoSchemaInput.Lines.Add('    }');
  mmoSchemaInput.Lines.Add('  },');
  mmoSchemaInput.Lines.Add('  "required": ["age", "username"]'); // username missing
  mmoSchemaInput.Lines.Add('}');
end;

procedure TfrmMain.btnAnalyzeClick(Sender: TObject);
var
  lSchemaJson: TJSONValue;
  lLinter: TSchemaLinter;
  lFindings: TArray<TLintFinding>;
  lFinding: TLintFinding;
  lItem: TListItem;
  lHasErrors: Boolean;
begin
  lvwFindings.Items.Clear;
  lblStatus.Caption := 'Analyzing schema...';
  lblStatus.Font.Color := $000288D1;
  lblStatus.Update;

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
    lLinter := TSchemaLinter.Create;
    try
      lLinter.MinSeverity := TSeverity(cboMinSeverity.ItemIndex);
      lFindings := lLinter.Analyze(lSchemaJson as TJSONObject);

      lHasErrors := False;
      for lFinding in lFindings do
      begin
        lItem := lvwFindings.Items.Add;
        lItem.Caption := SeverityToString(lFinding.Severity);
        lItem.SubItems.Add(lFinding.RuleId);
        lItem.SubItems.Add(lFinding.Path);
        lItem.SubItems.Add(lFinding.Message);
        if lFinding.Severity = TSeverity.Error then
          lHasErrors := True;
      end;

      if Length(lFindings) = 0 then
      begin
        lblStatus.Caption := 'Analysis completed. No issues found!';
        lblStatus.Font.Color := clGreen;
      end else
      begin
        lblStatus.Caption := Format('Analysis completed. Found %d issue(s).', [Length(lFindings)]);
        if lHasErrors then
          lblStatus.Font.Color := clRed
        else
          lblStatus.Font.Color := clGreen;
      end;
    finally
      lLinter.Free;
    end;
  finally
    lSchemaJson.Free;
  end;
end;

procedure TfrmMain.btnCopyClick(Sender: TObject);
var
  lReport: string;
begin
  if lvwFindings.Items.Count = 0 then
  begin
    lblStatus.Caption := 'Nothing to copy. Run analysis first.';
    lblStatus.Font.Color := clRed;
    Exit;
  end;

  lReport := GetMarkdownReport;
  Clipboard.SetTextBuf(PChar(lReport));
  lblStatus.Caption := 'Report copied to clipboard as Markdown.';
  lblStatus.Font.Color := clGreen;
end;

procedure TfrmMain.btnExportClick(Sender: TObject);
var
  lReportText: string;
begin
  if lvwFindings.Items.Count = 0 then
  begin
    lblStatus.Caption := 'Nothing to export. Run analysis first.';
    lblStatus.Font.Color := clRed;
    Exit;
  end;

  dlgSave.Filter := 'Markdown Report (*.md)|*.md|JSON Report (*.json)|*.json|Text Report (*.txt)|*.txt';
  dlgSave.DefaultExt := 'md';

  if dlgSave.Execute then
  begin
    if SameText(ExtractFileExt(dlgSave.FileName), '.json') then
      lReportText := GetJSONReport
    else if SameText(ExtractFileExt(dlgSave.FileName), '.md') or SameText(ExtractFileExt(dlgSave.FileName), '.markdown') then
      lReportText := GetMarkdownReport
    else
      lReportText := GetMarkdownReport; // fallback to markdown format

    try
      TFile.WriteAllText(dlgSave.FileName, lReportText, TEncoding.UTF8);
      lblStatus.Caption := 'Report exported successfully.';
      lblStatus.Font.Color := clGreen;
    except
      on E: Exception do
      begin
        lblStatus.Caption := 'Error exporting report: ' + E.Message;
        lblStatus.Font.Color := clRed;
      end;
    end;
  end;
end;

function TfrmMain.SeverityToString(pSeverity: TSeverity): string;
begin
  case pSeverity of
    TSeverity.Info: Result := 'Info';
    TSeverity.Warning: Result := 'Warning';
    TSeverity.Error: Result := 'Error';
  else
    Result := 'Unknown';
  end;
end;

function TfrmMain.GetMarkdownReport: string;
var
  lSb: TStringBuilder;
  lI: Integer;
begin
  lSb := TStringBuilder.Create;
  try
    lSb.AppendLine('# SchemaLinter Analysis Report');
    lSb.AppendLine;
    lSb.AppendLine(Format('- **Total Findings**: %d', [lvwFindings.Items.Count]));
    lSb.AppendLine(Format('- **Analysis Date**: %s', [DateTimeToStr(Now)]));
    lSb.AppendLine;
    lSb.AppendLine('| Severity | Rule ID | Path | Message |');
    lSb.AppendLine('| :--- | :--- | :--- | :--- |');

    for lI := 0 to lvwFindings.Items.Count - 1 do
    begin
      lSb.AppendLine(Format('| **%s** | `%s` | `%s` | %s |', [
        lvwFindings.Items[lI].Caption,
        lvwFindings.Items[lI].SubItems[0],
        lvwFindings.Items[lI].SubItems[1],
        lvwFindings.Items[lI].SubItems[2]
      ]));
    end;

    Result := lSb.ToString;
  finally
    lSb.Free;
  end;
end;

function TfrmMain.GetJSONReport: string;
var
  lArray: TJSONArray;
  lObj: TJSONObject;
  lI: Integer;
begin
  lArray := TJSONArray.Create;
  try
    for lI := 0 to lvwFindings.Items.Count - 1 do
    begin
      lObj := TJSONObject.Create;
      lObj.AddPair('severity', lvwFindings.Items[lI].Caption);
      lObj.AddPair('ruleId', lvwFindings.Items[lI].SubItems[0]);
      lObj.AddPair('path', lvwFindings.Items[lI].SubItems[1]);
      lObj.AddPair('message', lvwFindings.Items[lI].SubItems[2]);
      lArray.AddElement(lObj);
    end;
    Result := lArray.ToJSON;
  finally
    lArray.Free;
  end;
end;

end.
