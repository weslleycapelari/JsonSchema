unit Schema2Delphi.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, System.JSON,
  Schema2Delphi.Lote;

type
  TfrmMain = class(TForm)
    pnlClient: TPanel;
    splMain: TSplitter;
    mmoPasOutput: TMemo;
    mmoSchemaInput: TMemo;
    pnlStatusPanel: TPanel;
    lblStatus: TLabel;
    pnlTopPanel: TPanel;
    lblUnitName: TLabel;
    edtUnitName: TEdit;
    btnGenerate: TButton;
    lblClassName: TLabel;
    edtClassName: TEdit;
    btnGenerateLote: TButton;
    pnlBrandBar: TPanel;
    procedure btnGenerateClick(Sender: TObject);
    procedure btnGenerateLoteClick(Sender: TObject);
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

uses Schema2Delphi.Utils;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  lblStatus.Font.Color := clGreen;
  lblStatus.Caption := 'Ready';
end;

procedure TfrmMain.btnGenerateClick(Sender: TObject);
var
  lSchemaObj: TJSONObject;
begin
  mmoPasOutput.Clear;
  lblStatus.Caption := 'Gerando código...';
  lblStatus.Font.Color := $000288D1;
  lblStatus.Update;

  if Trim(mmoSchemaInput.Text) = '' then
  begin
    lblStatus.Font.Color := clRed;
    lblStatus.Caption := 'Erro: O JSON Schema não pode estar vazio.';
    Exit;
  end;

  if Trim(edtUnitName.Text) = '' then
  begin
    lblStatus.Font.Color := clRed;
    lblStatus.Caption := 'Erro: Por favor, forneça um nome para a unit.';
    Exit;
  end;

  try
    lSchemaObj := TJSONObject.ParseJSONValue(mmoSchemaInput.Text, True) as TJSONObject;
    if not Assigned(lSchemaObj) then
    begin
      lblStatus.Font.Color := clRed;
      lblStatus.Caption := 'Erro: JSON inválido.';
      Exit;
    end;

    try
      mmoPasOutput.Text := GenerateClassFromSchema(lSchemaObj, edtClassName.Text, edtUnitName.Text);
      lblStatus.Font.Color := clGreen;
      lblStatus.Caption := 'Arquivo .pas gerado com sucesso!';
    finally
      lSchemaObj.Free;
    end;
  except
    on E: Exception do
    begin
      lblStatus.Font.Color := clRed;
      lblStatus.Caption := 'Erro: ' + E.Message;
    end;
  end;
end;

procedure TfrmMain.btnGenerateLoteClick(Sender: TObject);
begin
  Application.CreateForm(TfrmLote, frmLote);
  try
    frmLote.ShowModal;
  finally
    frmLote.Free;
  end;
end;

end.
