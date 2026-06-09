unit Delphi2Schema.Main;

(*
--------------------------------------------------------------------------------
VCL Main form for the Delphi2Schema GUI application.
--------------------------------------------------------------------------------
*)

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, System.Rtti, System.JSON,
  Delphi2Schema.Engine, Delphi2Schema.Samples, System.TypInfo;

type
  TfrmMain = class(TForm)
    pnlTop: TPanel;
    lblBpl: TLabel;
    edtBplPath: TEdit;
    btnBrowseBpl: TButton;
    lblClass: TLabel;
    cboClass: TComboBox;
    chkScanFields: TCheckBox;
    chkScanProperties: TCheckBox;
    chkUseEnumNames: TCheckBox;
    btnGenerate: TButton;
    mmoSchema: TMemo;
    pnlStatus: TPanel;
    lblStatus: TLabel;
    dlgOpen: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnBrowseBplClick(Sender: TObject);
    procedure btnGenerateClick(Sender: TObject);
  private
    FRttiContext: TRttiContext;
    FPackageHandle: HMODULE;
    procedure LoadBplPackage(const pPath: string);
    procedure RefreshClassList;
    function FindRttiType(const pName: string): TRttiType;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FRttiContext := TRttiContext.Create;
  FPackageHandle := 0;
  chkScanFields.Checked := False;
  chkScanProperties.Checked := True;
  chkUseEnumNames.Checked := True;
  lblStatus.Caption := 'Ready';
  lblStatus.Font.Color := clGreen;
  RefreshClassList;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if FPackageHandle <> 0 then
    FreeLibrary(FPackageHandle);
  FRttiContext.Free;
end;

procedure TfrmMain.LoadBplPackage(const pPath: string);
begin
  if FPackageHandle <> 0 then
  begin
    FreeLibrary(FPackageHandle);
    FPackageHandle := 0;
  end;

  try
    FPackageHandle := SafeLoadLibrary(pPath);
    if FPackageHandle = 0 then
    begin
      lblStatus.Caption := 'Error: Could not load package: ' + ExtractFileName(pPath);
      lblStatus.Font.Color := clRed;
      Exit;
    end;

    lblStatus.Caption := 'Package loaded successfully: ' + ExtractFileName(pPath);
    lblStatus.Font.Color := clGreen;
    RefreshClassList;
  except
    on E: Exception do
    begin
      lblStatus.Caption := 'Error loading package: ' + E.Message;
      lblStatus.Font.Color := clRed;
    end;
  end;
end;

procedure TfrmMain.btnBrowseBplClick(Sender: TObject);
begin
  dlgOpen.Title := 'Load Delphi Runtime Package (.bpl)';
  dlgOpen.Filter := 'Delphi Packages (*.bpl)|*.bpl|All Files (*.*)|*.*';
  if dlgOpen.Execute then
  begin
    edtBplPath.Text := dlgOpen.FileName;
    LoadBplPackage(dlgOpen.FileName);
  end;
end;

procedure TfrmMain.RefreshClassList;
var
  lType: TRttiType;
begin
  cboClass.Items.BeginUpdate;
  try
    cboClass.Items.Clear;

    // Add built-in samples
    cboClass.Items.Add('TSampleUser');
    cboClass.Items.Add('TSampleAddress');

    // Add dynamic types loaded from BPL
    for lType in FRttiContext.GetTypes do
    begin
      if (lType.TypeKind = tkClass) and
         (not lType.QualifiedName.StartsWith('System.')) and
         (not lType.QualifiedName.StartsWith('Vcl.')) and
         (not lType.QualifiedName.StartsWith('Winapi.')) and
         (not lType.QualifiedName.StartsWith('Data.')) and
         (not lType.QualifiedName.StartsWith('DesignIntf')) and
         (cboClass.Items.IndexOf(lType.Name) = -1) and
         (cboClass.Items.IndexOf(lType.QualifiedName) = -1) then
      begin
        cboClass.Items.Add(lType.QualifiedName);
      end;
    end;

    if cboClass.Items.Count > 0 then
      cboClass.ItemIndex := 0;
  finally
    cboClass.Items.EndUpdate;
  end;
end;

function TfrmMain.FindRttiType(const pName: string): TRttiType;
var
  lType: TRttiType;
begin
  Result := FRttiContext.FindType(pName);
  if Assigned(Result) then
    Exit;

  for lType in FRttiContext.GetTypes do
  begin
    if SameText(lType.Name, pName) or SameText(lType.QualifiedName, pName) then
    begin
      Result := lType;
      Exit;
    end;
  end;
end;

procedure TfrmMain.btnGenerateClick(Sender: TObject);
var
  lType: TRttiType;
  lGenerator: TDelphi2SchemaGenerator;
  lSchemaJson: TJSONObject;
begin
  mmoSchema.Clear;
  lblStatus.Caption := 'Generating...';
  lblStatus.Font.Color := $000288D1;
  lblStatus.Update;

  if cboClass.Text = '' then
  begin
    lblStatus.Caption := 'Error: No class selected to scan.';
    lblStatus.Font.Color := clRed;
    Exit;
  end;

  lType := FindRttiType(cboClass.Text);
  if not Assigned(lType) then
  begin
    lblStatus.Caption := 'Error: Class type not found: ' + cboClass.Text;
    lblStatus.Font.Color := clRed;
    Exit;
  end;

  lGenerator := TDelphi2SchemaGenerator.Create;
  try
    lGenerator.ScanFields := chkScanFields.Checked;
    lGenerator.ScanProperties := chkScanProperties.Checked;
    lGenerator.UseEnumNames := chkUseEnumNames.Checked;

    try
      lSchemaJson := lGenerator.GenerateSchema(lType.Handle);
      try
        mmoSchema.Text := lSchemaJson.Format(2);
        lblStatus.Caption := 'JSON Schema generated successfully.';
        lblStatus.Font.Color := clGreen;
      finally
        lSchemaJson.Free;
      end;
    except
      on E: Exception do
      begin
        lblStatus.Caption := 'Generation failed: ' + E.Message;
        lblStatus.Font.Color := clRed;
      end;
    end;
  finally
    lGenerator.Free;
  end;
end;

end.
