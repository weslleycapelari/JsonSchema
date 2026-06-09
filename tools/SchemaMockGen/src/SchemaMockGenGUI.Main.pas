unit SchemaMockGenGUI.Main;

(*
--------------------------------------------------------------------------------
Main Form unit for SchemaMockGenGUI VCL Application.
--------------------------------------------------------------------------------
*)

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.JSON,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  SchemaMockGen.Generator,
  SchemaMockGen.Utils;

type
  TfrmMain = class(TForm)
    pnlTop: TPanel;
    lblSchema: TLabel;
    edtSchemaPath: TEdit;
    btnBrowseSchema: TButton;
    lblSeed: TLabel;
    edtSeed: TEdit;
    btnRandomSeed: TButton;
    lblCount: TLabel;
    edtCount: TEdit;
    btnGenerate: TButton;
    btnSave: TButton;
    mmoOutput: TMemo;
    pnlStatus: TPanel;
    lblStatus: TLabel;
    dlgOpenSchema: TOpenDialog;
    dlgSaveOutput: TSaveDialog;
    procedure btnBrowseSchemaClick(Sender: TObject);
    procedure btnRandomSeedClick(Sender: TObject);
    procedure btnGenerateClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
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
  edtSeed.Text := '-1';
  edtCount.Text := '1';
  mmoOutput.Clear;
  lblStatus.Caption := 'Ready';
  lblStatus.Font.Color := clGreen;
  lblStatus.Update;
  end;

  procedure TfrmMain.btnBrowseSchemaClick(Sender: TObject);
  begin
  if dlgOpenSchema.Execute then
    edtSchemaPath.Text := dlgOpenSchema.FileName;
  end;

  procedure TfrmMain.btnRandomSeedClick(Sender: TObject);
  begin
  Randomize;
  edtSeed.Text := IntToStr(Random(2147483647));
  end;

  procedure TfrmMain.btnGenerateClick(Sender: TObject);
  var
  lSchemaPath: string;
  lSchemaStr, lOutputStr: string;
  lSchemaVal: TJSONValue;
  lGenerator: TSchemaMockGenerator;
  lSeed: Int64;
  lCount: Integer;
  lResultVal: TJSONValue;
  lResultArray: TJSONArray;
  lI: Integer;
  begin
  lblStatus.Caption := 'Generating...';
  lblStatus.Font.Color := $000288D1;
  lblStatus.Update;
  lSchemaPath := edtSchemaPath.Text;
  if (lSchemaPath = '') or not FileExists(lSchemaPath) then
  begin
    lblStatus.Caption := 'Error: Invalid schema file.';
    lblStatus.Font.Color := clRed;
    ShowMessage('Please select a valid JSON Schema file first.');
    Exit;
  end;

  try
    lSchemaStr := ReadFileContent(lSchemaPath);
  except
    on E: Exception do
    begin
      lblStatus.Caption := 'Error reading file.';
      lblStatus.Font.Color := clRed;
      ShowMessage('Error reading schema file: ' + E.Message);
      Exit;
    end;
  end;

  lSchemaVal := TJSONObject.ParseJSONValue(lSchemaStr);
  if not Assigned(lSchemaVal) then
  begin
    lblStatus.Caption := 'Error: Invalid JSON.';
    lblStatus.Font.Color := clRed;
    ShowMessage('Schema is not a valid JSON document.');
    Exit;
  end;

  try
    // Parse seed
    if not TryStrToInt64(edtSeed.Text, lSeed) or (lSeed < 0) then
    begin
      Randomize;
      lSeed := Random(2147483647);
      edtSeed.Text := IntToStr(lSeed);
    end;

    // Parse count
    if not TryStrToInt(edtCount.Text, lCount) or (lCount < 1) then
    begin
      lCount := 1;
      edtCount.Text := '1';
    end;

    lGenerator := TSchemaMockGenerator.Create(lSeed);
    try
      if lCount = 1 then
      begin
        lResultVal := lGenerator.Generate(lSchemaVal);
        lOutputStr := lResultVal.ToString;
        lResultVal.Free;
      end else
      begin
        lResultArray := TJSONArray.Create;
        try
          for lI := 1 to lCount do
            lResultArray.AddElement(lGenerator.Generate(lSchemaVal));
          lOutputStr := lResultArray.ToString;
        finally
          lResultArray.Free;
        end;
      end;

      // Prettify output JSON if possible
      mmoOutput.Text := lOutputStr;
      lblStatus.Caption := 'Mock data generated successfully.';
      lblStatus.Font.Color := clGreen;
    finally
      lGenerator.Free;
    end;
  finally
    lSchemaVal.Free;
  end;
end;

procedure TfrmMain.btnSaveClick(Sender: TObject);
begin
  if mmoOutput.Text = '' then
  begin
    lblStatus.Caption := 'Error: Nothing to save.';
    lblStatus.Font.Color := clRed;
    ShowMessage('No generated mock data to save.');
    Exit;
  end;

  if dlgSaveOutput.Execute then
  begin
    try
      WriteFileContent(dlgSaveOutput.FileName, mmoOutput.Text);
      lblStatus.Caption := 'File saved: ' + ExtractFileName(dlgSaveOutput.FileName);
      lblStatus.Font.Color := clGreen;
      ShowMessage('File saved successfully.');
    except
      on E: Exception do
      begin
        lblStatus.Caption := 'Error saving file.';
        lblStatus.Font.Color := clRed;
        ShowMessage('Error saving file: ' + E.Message);
      end;
    end;
  end;
end;

end.
