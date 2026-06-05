unit SchemaValidator.Main;

(*
--------------------------------------------------------------------------------
VCL Main form for the SchemaValidator GUI application.
--------------------------------------------------------------------------------
*)

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  System.JSON, JsonSchema.Core.Interfaces, JsonSchema.Validator, JsonSchema.Localization.Enums,
  SchemaValidator.Utils;

type
  TfrmMain = class(TForm)
    pnlTop: TPanel;
    lblDraft: TLabel;
    cboDraft: TComboBox;
    lblLocale: TLabel;
    cboLocale: TComboBox;
    chkEnforceFormats: TCheckBox;
    btnValidate: TButton;
    pnlClient: TPanel;
    pnlSchema: TPanel;
    lblSchema: TLabel;
    mmoSchema: TMemo;
    splMain: TSplitter;
    pnlInstance: TPanel;
    lblInstance: TLabel;
    mmoInstance: TMemo;
    pnlBottom: TPanel;
    lblStatus: TLabel;
    lstErrors: TListView;
    pnlSchemaActions: TPanel;
    btnLoadSchema: TButton;
    pnlInstanceActions: TPanel;
    btnLoadInstance: TButton;
    dlgOpen: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure btnValidateClick(Sender: TObject);
    procedure btnLoadSchemaClick(Sender: TObject);
    procedure btnLoadInstanceClick(Sender: TObject);
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
  cboDraft.Items.Add('Auto-detect');
  cboDraft.Items.Add('Draft 6');
  cboDraft.Items.Add('Draft 7');
  cboDraft.Items.Add('Draft 2019-09');
  cboDraft.Items.Add('Draft 2020-12');
  cboDraft.ItemIndex := 0;

  cboLocale.Items.Clear;
  cboLocale.Items.Add('English (en)');
  cboLocale.Items.Add('Portuguese (pt)');
  cboLocale.ItemIndex := 0;

  chkEnforceFormats.Checked := True;
  lblStatus.Caption := 'Ready';
  lblStatus.Font.Color := clWindowText;
end;

procedure TfrmMain.btnLoadSchemaClick(Sender: TObject);
begin
  dlgOpen.Title := 'Load JSON Schema';
  dlgOpen.Filter := 'JSON Files (*.json)|*.json|All Files (*.*)|*.*';
  if dlgOpen.Execute then
  begin
    try
      mmoSchema.Lines.LoadFromFile(dlgOpen.FileName, TEncoding.UTF8);
      lblStatus.Caption := 'Schema loaded successfully.';
      lblStatus.Font.Color := clGreen;
    except
      on E: Exception do
      begin
        lblStatus.Caption := 'Error loading schema: ' + E.Message;
        lblStatus.Font.Color := clRed;
      end;
    end;
  end;
end;

procedure TfrmMain.btnLoadInstanceClick(Sender: TObject);
begin
  dlgOpen.Title := 'Load JSON Instance';
  dlgOpen.Filter := 'JSON Files (*.json)|*.json|All Files (*.*)|*.*';
  if dlgOpen.Execute then
  begin
    try
      mmoInstance.Lines.LoadFromFile(dlgOpen.FileName, TEncoding.UTF8);
      lblStatus.Caption := 'Instance loaded successfully.';
      lblStatus.Font.Color := clGreen;
    except
      on E: Exception do
      begin
        lblStatus.Caption := 'Error loading instance: ' + E.Message;
        lblStatus.Font.Color := clRed;
      end;
    end;
  end;
end;

procedure TfrmMain.btnValidateClick(Sender: TObject);
var
  lSchemaVal: TJSONValue;
  lInstanceVal: TJSONValue;
  lValidator: TJsonSchemaValidator;
  lResult: IValidationResult;
  lDraft: TDraftVersion;
  lLocale: TLocale;
  lError: IValidationError;
  lItem: TListItem;
begin
  lstErrors.Items.Clear;
  lblStatus.Caption := 'Validating...';
  lblStatus.Font.Color := clWindowText;

  if Trim(mmoSchema.Text) = '' then
  begin
    lblStatus.Caption := 'Validation failed: Schema is empty.';
    lblStatus.Font.Color := clRed;
    Exit;
  end;

  if Trim(mmoInstance.Text) = '' then
  begin
    lblStatus.Caption := 'Validation failed: Instance is empty.';
    lblStatus.Font.Color := clRed;
    Exit;
  end;

  // 1. Parse JSON Schema
  try
    lSchemaVal := TJSONObject.ParseJSONValue(mmoSchema.Text, True);
  except
    on E: Exception do
    begin
      lblStatus.Caption := 'Schema parsing error: ' + E.Message;
      lblStatus.Font.Color := clRed;
      Exit;
    end;
  end;

  if not Assigned(lSchemaVal) then
  begin
    lblStatus.Caption := 'Schema is not valid JSON.';
    lblStatus.Font.Color := clRed;
    Exit;
  end;

  // 2. Parse JSON Instance
  try
    lInstanceVal := TJSONObject.ParseJSONValue(mmoInstance.Text, True);
  except
    on E: Exception do
    begin
      lSchemaVal.Free;
      lblStatus.Caption := 'Instance parsing error: ' + E.Message;
      lblStatus.Font.Color := clRed;
      Exit;
    end;
  end;

  if not Assigned(lInstanceVal) then
  begin
    lSchemaVal.Free;
    lblStatus.Caption := 'Instance is not valid JSON.';
    lblStatus.Font.Color := clRed;
    Exit;
  end;

  // 3. Setup Validator Options
  if cboLocale.ItemIndex = 1 then
    lLocale := TLocale.PtBR
  else
    lLocale := TLocale.EnUS;

  case cboDraft.ItemIndex of
    1: lDraft := TDraftVersion.dvDraft6;
    2: lDraft := TDraftVersion.dvDraft7;
    3: lDraft := TDraftVersion.dvDraft2019_09;
    4: lDraft := TDraftVersion.dvDraft2020_12;
  else
    lDraft := AutoDetectDraft(lSchemaVal);
  end;

  lValidator := TJsonSchemaValidator.Create(lLocale);
  try
    lValidator.EnforceFormats := chkEnforceFormats.Checked;

    try
      lResult := lValidator.Validate(lSchemaVal, lInstanceVal, lDraft);
    except
      on E: Exception do
      begin
        lblStatus.Caption := 'Runtime Error: ' + E.Message;
        lblStatus.Font.Color := clRed;
        Exit;
      end;
    end;

    if lResult.IsValid then
    begin
      lblStatus.Caption := 'JSON Instance is VALID!';
      lblStatus.Font.Color := clGreen;
    end else
    begin
      lblStatus.Caption := Format('JSON Instance is INVALID! (%d error(s) found)', [Length(lResult.Errors)]);
      lblStatus.Font.Color := clRed;

      lstErrors.Items.BeginUpdate;
      try
        for lError in lResult.Errors do
        begin
          lItem := lstErrors.Items.Add;
          lItem.Caption := lError.Keyword;
          lItem.SubItems.Add(lError.Message);
          lItem.SubItems.Add(lError.Resolution);
        end;
      finally
        lstErrors.Items.EndUpdate;
      end;
    end;
  finally
    lValidator.Free;
    lSchemaVal.Free;
    lInstanceVal.Free;
  end;
end;

end.
