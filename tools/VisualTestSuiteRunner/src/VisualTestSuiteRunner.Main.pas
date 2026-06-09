unit VisualTestSuiteRunner.Main;

(*
--------------------------------------------------------------------------------
VCL Main form for the VisualTestSuiteRunner GUI application.
--------------------------------------------------------------------------------
*)

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.FileCtrl,
  System.JSON, System.IOUtils, VisualTestSuiteRunner.Engine;

type
  TfrmMain = class(TForm)
    pnlTop: TPanel;
    lblSuiteDir: TLabel;
    edtSuiteDir: TEdit;
    btnBrowse: TButton;
    lblDraft: TLabel;
    cmbDraft: TComboBox;
    btnRun: TButton;
    pnlStatus: TPanel;
    pbProgress: TProgressBar;
    lblSummary: TLabel;
    lblCompliance: TLabel;
    pnlMain: TPanel;
    pnlLeft: TPanel;
    tvTestTree: TTreeView;
    splMain: TSplitter;
    pnlRight: TPanel;
    lblInspection: TLabel;
    mmoSchema: TMemo;
    lblSchema: TLabel;
    mmoData: TMemo;
    lblData: TLabel;
    lblResultTitle: TLabel;
    lblResultDetail: TLabel;
    mmoErrors: TMemo;
    lblErrors: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnBrowseClick(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure tvTestTreeChange(Sender: TObject; Node: TTreeNode);
  private
    FRunner: TTestSuiteRunner;
    procedure PopulateTree;
    procedure UpdateInspection(pNode: TTreeNode);
    procedure ClearInspection;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  cmbDraft.Items.Clear;
  cmbDraft.Items.Add('2020-12');
  cmbDraft.Items.Add('2019-09');
  cmbDraft.Items.Add('draft7');
  cmbDraft.Items.Add('draft6');
  cmbDraft.ItemIndex := 0;

  ClearInspection;
  lblSummary.Caption := 'Ready to run test suite';
  lblSummary.Font.Color := clGreen;
  lblCompliance.Caption := 'Compliance: 0.0%';
  lblCompliance.Font.Color := clWindowText;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if Assigned(FRunner) then
    FreeAndNil(FRunner);
end;

procedure TfrmMain.btnBrowseClick(Sender: TObject);
var
  lDir: string;
begin
  lDir := edtSuiteDir.Text;
  if SelectDirectory('Select JSON Schema Test Suite Folder', '', lDir) then
  begin
    edtSuiteDir.Text := lDir;
  end;
end;

procedure TfrmMain.btnRunClick(Sender: TObject);
begin
  if edtSuiteDir.Text = '' then
  begin
    lblSummary.Caption := 'Error: Select directory.';
    lblSummary.Font.Color := clRed;
    ShowMessage('Please select the test suite directory first.');
    Exit;
  end;

  if not TDirectory.Exists(edtSuiteDir.Text) then
  begin
    lblSummary.Caption := 'Error: Invalid directory.';
    lblSummary.Font.Color := clRed;
    ShowMessage('Selected directory does not exist.');
    Exit;
  end;

  lblSummary.Caption := 'Running validations...';
  lblSummary.Font.Color := $000288D1;
  lblSummary.Update;

  if Assigned(FRunner) then
    FreeAndNil(FRunner);

  try
    FRunner := TTestSuiteRunner.Create(cmbDraft.Text);
    FRunner.RunTestSuite(edtSuiteDir.Text);
    PopulateTree;
  except
    on E: Exception do
    begin
      ShowMessage('Error running test suite: ' + E.Message);
      lblSummary.Caption := 'Run failed';
      lblSummary.Font.Color := clRed;
    end;
  end;
end;

procedure TfrmMain.PopulateTree;
var
  lRootNode: TTreeNode;
  lFileNode: TTreeNode;
  lGroupNode: TTreeNode;
  lCaseNode: TTreeNode;
  lFileRes: TTestFileResult;
  lGroupRes: TTestGroupResult;
  lCaseRes: TTestCaseResult;
  lI: Integer;
  lTotalTests: Integer;
  lTotalPassed: Integer;
  lCompliance: Double;
  lFileCompliance: Double;
begin
  tvTestTree.Items.BeginUpdate;
  try
    tvTestTree.Items.Clear;

    lTotalTests := 0;
    lTotalPassed := 0;

    lRootNode := tvTestTree.Items.Add(nil, 'Draft ' + cmbDraft.Text);
    lRootNode.Data := nil;

    for lFileRes in FRunner.SuiteResults do
    begin
      lTotalTests := lTotalTests + lFileRes.TotalTests;
      lTotalPassed := lTotalPassed + lFileRes.PassCount;

      lFileCompliance := 0.0;
      if lFileRes.TotalTests > 0 then
        lFileCompliance := (lFileRes.PassCount / lFileRes.TotalTests) * 100.0;

      lFileNode := tvTestTree.Items.AddChild(lRootNode, Format('%s (%d/%d - %.1f%%)', [
        lFileRes.FileName, lFileRes.PassCount, lFileRes.TotalTests, lFileCompliance
      ]));
      lFileNode.Data := lFileRes;

      for lGroupRes in lFileRes.Groups do
      begin
        lGroupNode := tvTestTree.Items.AddChild(lFileNode, lGroupRes.Description);
        lGroupNode.Data := lGroupRes;

        for lI := 0 to lGroupRes.Cases.Count - 1 do
        begin
          lCaseRes := lGroupRes.Cases[lI];
          if lCaseRes.Passed then
            lCaseNode := tvTestTree.Items.AddChild(lGroupNode, '[PASS] ' + lCaseRes.Description)
          else
            lCaseNode := tvTestTree.Items.AddChild(lGroupNode, '[FAIL] ' + lCaseRes.Description);
          
          lCaseNode.Data := nil; // Accessed by index relative to parent Group
        end;
      end;
    end;

    lRootNode.Expand(False);

    // Summary calculation
    lCompliance := 0.0;
    if lTotalTests > 0 then
      lCompliance := (lTotalPassed / lTotalTests) * 100.0;

    lblSummary.Caption := Format('Total: %d | Passed: %d | Failed: %d', [
      lTotalTests, lTotalPassed, lTotalTests - lTotalPassed
    ]);
    lblSummary.Font.Color := clGreen;

    lblCompliance.Caption := Format('Compliance: %.2f%%', [lCompliance]);
    if lCompliance >= 95.0 then
      lblCompliance.Font.Color := clGreen
    else if lCompliance >= 80.0 then
      lblCompliance.Font.Color := $000288D1 // Dark Orange/Yellow
    else
      lblCompliance.Font.Color := clRed;

    pbProgress.Max := lTotalTests;
    pbProgress.Position := lTotalPassed;

  finally
    tvTestTree.Items.EndUpdate;
  end;
end;

procedure TfrmMain.tvTestTreeChange(Sender: TObject; Node: TTreeNode);
begin
  if Assigned(Node) then
    UpdateInspection(Node)
  else
    ClearInspection;
end;

procedure TfrmMain.UpdateInspection(pNode: TTreeNode);
var
  lFile: TTestFileResult;
  lGroup: TTestGroupResult;
  lCase: TTestCaseResult;
  lFileCompliance: Double;
begin
  ClearInspection;

  if pNode.Level = 0 then
  begin
    lblInspection.Caption := 'Inspection: Root Draft ' + cmbDraft.Text;
    mmoSchema.Text := 'Run details:' + sLineBreak + lblSummary.Caption;
  end
  else if pNode.Level = 1 then
  begin
    lFile := TTestFileResult(pNode.Data);
    lFileCompliance := 0.0;
    if lFile.TotalTests > 0 then
      lFileCompliance := (lFile.PassCount / lFile.TotalTests) * 100.0;

    lblInspection.Caption := 'Inspection: Test File ' + lFile.FileName;
    mmoSchema.Text := Format('File: %s' + sLineBreak +
      'Passed: %d/%d' + sLineBreak +
      'Compliance: %.1f%%', [
        lFile.FileName, lFile.PassCount, lFile.TotalTests, lFileCompliance
      ]);
  end
  else if pNode.Level = 2 then
  begin
    lGroup := TTestGroupResult(pNode.Data);
    lblInspection.Caption := 'Inspection: Test Group';
    lblSchema.Visible := True;
    mmoSchema.Visible := True;
    
    mmoSchema.Text := lGroup.SchemaJSON;
    mmoData.Text := Format('Group Description: %s' + sLineBreak +
      'This group contains %d test cases.', [lGroup.Description, lGroup.Cases.Count]);
  end
  else if pNode.Level = 3 then
  begin
    lGroup := TTestGroupResult(pNode.Parent.Data);
    lCase := lGroup.Cases[pNode.Index];

    lblInspection.Caption := 'Inspection: Test Case';
    lblSchema.Visible := True;
    mmoSchema.Visible := True;
    lblData.Visible := True;
    mmoData.Visible := True;
    lblResultTitle.Visible := True;
    lblResultDetail.Visible := True;

    mmoSchema.Text := lGroup.SchemaJSON;
    mmoData.Text := lCase.DataJSON;

    lblResultTitle.Caption := 'Validation Result:';
    if lCase.Passed then
    begin
      lblResultDetail.Caption := 'PASSED';
      lblResultDetail.Font.Color := clGreen;
    end
    else
    begin
      lblResultDetail.Caption := 'FAILED';
      lblResultDetail.Font.Color := clRed;
      
      lblErrors.Visible := True;
      mmoErrors.Visible := True;
      mmoErrors.Text := Format('Case description: %s' + sLineBreak +
        'Expected Valid: %s' + sLineBreak +
        'Actual Valid: %s' + sLineBreak +
        'Errors encountered: %s', [
          lCase.Description,
          BoolToStr(lCase.ExpectedValid, True),
          BoolToStr(lCase.ActualValid, True),
          lCase.ErrorMessage
        ]);
    end;
  end;
end;

procedure TfrmMain.ClearInspection;
begin
  lblInspection.Caption := 'Inspection Details';
  
  lblSchema.Visible := False;
  mmoSchema.Visible := False;
  mmoSchema.Clear;
  
  lblData.Visible := False;
  mmoData.Visible := False;
  mmoData.Clear;
  
  lblResultTitle.Visible := False;
  lblResultDetail.Visible := False;
  lblResultDetail.Caption := '';
  
  lblErrors.Visible := False;
  mmoErrors.Visible := False;
  mmoErrors.Clear;
end;

end.
