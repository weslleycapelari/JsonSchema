unit Schema2Delphi.Lote;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, System.IOUtils, System.IniFiles,
  System.Generics.Collections;

type
  TSectionConfig = class(TObject)
    Name: string;
    SchemaPath: string;
    OutputPath: string;
    UnitName: string;
    ClassName: string;
  end;

  TfrmLote = class(TForm)
    pnlBody: TPanel;
    pnlBody1: TPanel;
    lblSchemaPath: TLabel;
    edtSchemaPath: TEdit;
    btnSchemaPath: TButton;
    pnlBody2: TPanel;
    lblOutputPath: TLabel;
    edtOutputPath: TEdit;
    btnOutputPath: TButton;
    grpOptions: TGroupBox;
    pnlBody3: TPanel;
    lblRootName: TLabel;
    edtUnitName: TEdit;
    pnlBody4: TPanel;
    lblBaseID: TLabel;
    edtClassName: TEdit;
    grpHistory: TGroupBox;
    lstHistory: TListBox;
    pnlButtons: TPanel;
    lblCodeEncoding: TLabel;
    btnConvertSchema: TButton;
    cbbCodeEncoding: TComboBox;
    btnConvertAll: TButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure lstHistoryClick(Sender: TObject);
    procedure btnSchemaPathClick(Sender: TObject);
    procedure btnOutputPathClick(Sender: TObject);
    procedure btnConvertSchemaClick(Sender: TObject);
    procedure btnConvertAllClick(Sender: TObject);
  private
    { Private declarations }
    FLastConfig: TSectionConfig;
    FConfigs: TObjectList<TSectionConfig>;
    FEncodings: TArray<TEncoding>;
    FEncodingsNames: TArray<string>;

    procedure AtualizarConfigs;
    procedure LoadConfigs;
    procedure ConvertSchema(const pConfigs: TSectionConfig);
  public
    { Public declarations }
  end;

var
  frmLote: TfrmLote;

implementation

uses System.JSON, Schema2Delphi.Utils;

{$R *.dfm}

procedure TfrmLote.AtualizarConfigs;
var
  LConfig: TSectionConfig;
  LIniFile: TIniFile;
  LSection: string;
  LSections: TStrings;
  LLastIndex: Integer;
  LLastConfig: string;
begin
  LIniFile := TIniFile.Create(ExpandFileName('.\config.ini'));
  LSections := TStringList.Create;

  try
    LIniFile.ReadSections(LSections);
    lstHistory.Clear;

    LLastIndex  := -1;
    LLastConfig := LIniFile.ReadString('CONFIG', 'LAST_CONFIG', '');;

    for LSection in LSections do
    begin
      if not LSection.ToLower.Equals('config') then
      begin
        LConfig := TSectionConfig.Create;

        LConfig.Name       := LSection;
        LConfig.SchemaPath := LIniFile.ReadString(LSection, 'SCHEMA_PATH', edtSchemaPath.Text);
        LConfig.OutputPath := LIniFile.ReadString(LSection, 'OUTPUT_PATH', edtOutputPath.Text);
        LConfig.UnitName   := LIniFile.ReadString(LSection, 'UNIT_NAME',   edtUnitName.Text);
        LConfig.ClassName  := LIniFile.ReadString(LSection, 'CLASS_NAME',  edtClassName.Text);

        if LConfig.Name.Equals(LLastConfig) then
          LLastIndex := FConfigs.Count;

        FConfigs.Add(LConfig);

        lstHistory.AddItem(LSection, LConfig);
      end;
    end;

    if LLastIndex > -1 then
    begin
      lstHistory.ItemIndex := LLastIndex;
      LoadConfigs;
    end;
  finally
    FreeAndNil(LIniFile);
  end;
end;

procedure TfrmLote.btnConvertAllClick(Sender: TObject);
var
  LConfig: TSectionConfig;
begin
  for LConfig in FConfigs do
    ConvertSchema(LConfig);

  ShowMessage('Arquivos Gerados com sucesso!');
end;

procedure TfrmLote.btnConvertSchemaClick(Sender: TObject);
var
  LConfigs: TSectionConfig;
begin
  LConfigs := TSectionConfig.Create;
  LConfigs.Name       := edtUnitName.Text;
  LConfigs.SchemaPath := edtSchemaPath.Text;
  LConfigs.OutputPath := edtOutputPath.Text;
  LConfigs.UnitName   := edtUnitName.Text;
  LConfigs.ClassName  := edtClassName.Text;

  ConvertSchema(LConfigs);

  ShowMessage('Arquivos Gerados com sucesso!');
end;

procedure TfrmLote.btnOutputPathClick(Sender: TObject);
var
  LFileDlg: TFileOpenDialog;
begin
  LFileDlg := TFileOpenDialog.Create(Self);
  try
    LFileDlg.Options := [fdoPickFolders];

    if LFileDlg.Execute then
      edtOutputPath.Text := LFileDlg.FileName;
  finally
    FreeAndNil(LFileDlg);
  end;
end;

procedure TfrmLote.btnSchemaPathClick(Sender: TObject);
var
  LFileDlg: TFileOpenDialog;
  LFileType: TFileTypeItem;
begin
  LFileDlg := TFileOpenDialog.Create(Self);
  try
    LFileType := LFileDlg.FileTypes.Add;
    LFileType.FileMask    := '*.json';
    LFileType.DisplayName := 'Arquivo JSON (*.json)';

    if LFileDlg.Execute then
      edtSchemaPath.Text := LFileDlg.FileName;
  finally
    FreeAndNil(LFileDlg);
  end;
end;

procedure TfrmLote.ConvertSchema(const pConfigs: TSectionConfig);
var
  LIndex        : Integer;
  LConfigs      : TSectionConfig;
  LContent      : TJSONObject;
  LOutputPath   : string;
  LFileContent  : TStringList;
  LSchemaAbsPath: string;
begin
  try
    LSchemaAbsPath := ExpandFileName(pConfigs.SchemaPath);
    if not FileExists(LSchemaAbsPath) then
      raise Exception.Create('O arquivo JSON-Schema n?o existe');

    LFileContent := TStringList.Create;
    try
      LFileContent.LoadFromFile(LSchemaAbsPath, TEncoding.ANSI);
      LContent := TJSONValue.ParseJSONValue(LFileContent.Text) as TJSONObject;
    finally
      if Assigned(LFileContent) then
        FreeAndNil(LFileContent);
    end;

    LIndex := lstHistory.Items.IndexOf(pConfigs.UnitName);
    if LIndex < 0 then
    begin
      LIndex := lstHistory.Items.Count;

      lstHistory.Items.Add(pConfigs.UnitName);
      LConfigs := TSectionConfig.Create;

      LConfigs.Name       := pConfigs.UnitName;
      LConfigs.SchemaPath := pConfigs.SchemaPath;
      LConfigs.OutputPath := pConfigs.OutputPath;
      LConfigs.UnitName   := pConfigs.UnitName;
      LConfigs.ClassName  := pConfigs.ClassName;

      FConfigs.Add(LConfigs);
      FLastConfig := LConfigs;
    end
    else
      FLastConfig := FConfigs.Items[LIndex];

    lstHistory.ItemIndex := LIndex;

    LOutputPath := ExpandFileName(pConfigs.OutputPath);
    if not TDirectory.Exists(LOutputPath) then
      ForceDirectories(LOutputPath);

    LFileContent := TStringList.Create;
    try
      LOutputPath := ExpandFileName(TPath.Combine(pConfigs.OutputPath, pConfigs.UnitName + '.pas'));

      if FileExists(LOutputPath) then
        TFile.Delete(LOutputPath);

      LFileContent.Text := GenerateClassFromSchema(LContent, pConfigs.ClassName, pConfigs.UnitName);
      LFileContent.SaveToFile(LOutputPath,
         FEncodings[cbbCodeEncoding.ItemIndex]);
    finally
      if Assigned(LFileContent) then
        FreeAndNil(LFileContent);
    end;
  except
    on E: Exception do
      ShowMessage('N?o foi possivel gerar os arquivos: ' + E.Message);
  end;
end;

procedure TfrmLote.FormClose(Sender: TObject; var Action: TCloseAction);
var
  LConfig : TSectionConfig;
  LIniFile: TIniFile;
begin
  LIniFile := TIniFile.Create(ExpandFileName('.\config.ini'));

  try
    for LConfig in FConfigs do
    begin
      LIniFile.WriteString(LConfig.Name, 'SCHEMA_PATH', LConfig.SchemaPath);
      LIniFile.WriteString(LConfig.Name, 'OUTPUT_PATH', LConfig.OutputPath);
      LIniFile.WriteString(LConfig.Name, 'UNIT_NAME',   LConfig.UnitName);
      LIniFile.WriteString(LConfig.Name, 'CLASS_NAME',  LConfig.ClassName);
    end;

    if (FLastConfig <> nil) and Assigned(FLastConfig) then
      LIniFile.WriteString('CONFIG', 'LAST_CONFIG', FLastConfig.Name)
    else
      LIniFile.WriteString('CONFIG', 'LAST_CONFIG', '');
  finally
    FreeAndNil(LIniFile);
  end;
end;

procedure TfrmLote.FormCreate(Sender: TObject);
var
  LCount: Integer;
begin
  FEncodings := [
    TEncoding.UTF8,
    TEncoding.ANSI,
    TEncoding.ASCII,
    TEncoding.Unicode,
    TEncoding.UTF7
  ];
  FEncodingsNames := ['UTF8', 'ANSI', 'ASCII', 'Unicode', 'UTF7'];

  cbbCodeEncoding.Items.Clear;
  for LCount := Low(FEncodingsNames) to High(FEncodingsNames) do
    cbbCodeEncoding.Items.Add(FEncodingsNames[LCount]);

  cbbCodeEncoding.ItemIndex := 1;

  FConfigs := TObjectList<TSectionConfig>.Create;
  AtualizarConfigs;
end;

procedure TfrmLote.LoadConfigs;
begin
  if lstHistory.ItemIndex < 0 then
    Exit;

  FLastConfig := FConfigs[lstHistory.ItemIndex];

  if (FLastConfig <> nil) and Assigned(FLastConfig) then
  begin
    edtSchemaPath.Text := FLastConfig.SchemaPath;
    edtOutputPath.Text := FLastConfig.OutputPath;
    edtUnitName.Text   := FLastConfig.UnitName;
    edtClassName.Text  := FLastConfig.ClassName;
  end;
end;

procedure TfrmLote.lstHistoryClick(Sender: TObject);
begin
  if (FLastConfig <> nil) and Assigned(FLastConfig) then
    if FLastConfig.Name = FConfigs[lstHistory.ItemIndex].Name then
      Exit;

  FLastConfig := FConfigs[lstHistory.ItemIndex];
  LoadConfigs;
end;

end.
