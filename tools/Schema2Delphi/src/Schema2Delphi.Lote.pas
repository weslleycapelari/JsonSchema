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

    procedure AtualizarConfigs;
    procedure LoadConfigs;
    procedure ConvertSchema(const pConfigs: TSectionConfig);
  public
    { Public declarations }
  end;

var
  frmLote: TfrmLote;
  _Encodings: TArray<TEncoding>;
  _EncodingsNames: TArray<string>;

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
      if LSection.ToLower.Equals('config') then
        Continue;

      LConfig := TSectionConfig.Create;

      with LConfig do
      begin
        Name       := LSection;
        SchemaPath := LIniFile.ReadString(LSection, 'SCHEMA_PATH', edtSchemaPath.Text);
        OutputPath := LIniFile.ReadString(LSection, 'OUTPUT_PATH', edtOutputPath.Text);
        UnitName   := LIniFile.ReadString(LSection, 'UNIT_NAME',   edtUnitName.Text);
        ClassName  := LIniFile.ReadString(LSection, 'CLASS_NAME',  edtClassName.Text);
      end;

      if LConfig.Name.Equals(LLastConfig) then
        LLastIndex := FConfigs.Count;

      FConfigs.Add(LConfig);

      lstHistory.AddItem(LSection, LConfig);
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
  with LConfigs do
  begin
    Name       := edtUnitName.Text;
    SchemaPath := edtSchemaPath.Text;
    OutputPath := edtOutputPath.Text;
    UnitName   := edtUnitName.Text;
    ClassName  := edtClassName.Text;
  end;

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
begin
  LFileDlg := TFileOpenDialog.Create(Self);
  try
    with LFileDlg.FileTypes.Add do
    begin
      FileMask    := '*.json';
      DisplayName := 'Arquivo JSON (*.json)';
    end;

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
      raise Exception.Create('O arquivo JSON-Schema não existe');

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

      with LConfigs do
      begin
        Name       := pConfigs.UnitName;
        SchemaPath := pConfigs.SchemaPath;
        OutputPath := pConfigs.OutputPath;
        UnitName   := pConfigs.UnitName;
        ClassName  := pConfigs.ClassName;
      end;

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
         _Encodings[cbbCodeEncoding.ItemIndex]);
    finally
      if Assigned(LFileContent) then
        FreeAndNil(LFileContent);
    end;
  except
    on E: Exception do
      ShowMessage('Não foi possivel gerar os arquivos: ' + E.Message);
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
  _Encodings := [
    TEncoding.UTF8,
    TEncoding.ANSI,
    TEncoding.ASCII,
    TEncoding.Unicode,
    TEncoding.UTF7
  ];
  _EncodingsNames := ['UTF8', 'ANSI', 'ASCII', 'Unicode', 'UTF7'];

  cbbCodeEncoding.Items.Clear;
  for LCount := Low(_EncodingsNames) to High(_EncodingsNames) do
    cbbCodeEncoding.Items.Add(_EncodingsNames[LCount]);

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
