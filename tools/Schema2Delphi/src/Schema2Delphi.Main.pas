unit Schema2Delphi.Main;



interface



uses

  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,

  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, System.JSON,

  Schema2Delphi.Lote;



type

  TfrmMain = class(TForm)

    pnlClient: TPanel;

    spl1: TSplitter;

    mmoPasOutput: TMemo;

    mmoSchemaInput: TMemo;

    pnlStatusPanel: TPanel;

    LabelStatus: TLabel;

    pnlTopPanel: TPanel;

    Label1: TLabel;

    edtUnitName: TEdit;

    btnGenerate: TButton;

    Label2: TLabel;

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

  LabelStatus.Font.Color := $00CC6600;

  LabelStatus.Caption := 'Ready';

end;



procedure TfrmMain.btnGenerateClick(Sender: TObject);

var

  LSchemaObj: TJSONObject;

begin

  mmoPasOutput.Clear;

  LabelStatus.Caption := '';



  if Trim(mmoSchemaInput.Text) = '' then

  begin

    LabelStatus.Font.Color := clRed;

    LabelStatus.Caption := 'Erro: O JSON Schema não pode estar vazio.';

    Exit;

  end;



  if Trim(edtUnitName.Text) = '' then

  begin

    LabelStatus.Font.Color := clRed;

    LabelStatus.Caption := 'Erro: Por favor, forneça um nome para a unit.';

    Exit;

  end;



  try

    LSchemaObj := TJSONObject.ParseJSONValue(mmoSchemaInput.Text, True) as TJSONObject;

  except

    on E: Exception do

    begin

      LabelStatus.Font.Color := clRed;

      LabelStatus.Caption := 'Erro de parsing no JSON Schema: ' + E.Message;

      Exit;

    end;

  end;



  try

    mmoPasOutput.Text := GenerateClassFromSchema(LSchemaObj, edtClassName.Text, edtUnitName.Text);

    LabelStatus.Font.Color := clGreen;

    LabelStatus.Caption := 'Arquivo .pas gerado com sucesso!';

  finally

    LSchemaObj.Free;

  end;

end;



procedure TfrmMain.btnGenerateLoteClick(Sender: TObject);

begin

  Application.CreateForm(TfrmLote, frmLote);

  frmLote.ShowModal;

  frmLote.Free;

end;



end.

