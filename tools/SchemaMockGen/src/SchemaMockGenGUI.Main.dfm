object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'JSON Schema Mock Generator'
  ClientHeight = 500
  ClientWidth = 800
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 800
    Height = 95
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblSchema: TLabel
      Left = 16
      Top = 19
      Width = 45
      Height = 15
      Caption = 'Schema:'
    end
    object lblSeed: TLabel
      Left = 16
      Top = 55
      Width = 29
      Height = 15
      Caption = 'Seed:'
    end
    object lblCount: TLabel
      Left = 320
      Top = 55
      Width = 36
      Height = 15
      Caption = 'Count:'
    end
    object edtSchemaPath: TEdit
      Left = 70
      Top = 16
      Width = 590
      Height = 23
      TabOrder = 0
    end
    object btnBrowseSchema: TButton
      Left = 670
      Top = 15
      Width = 110
      Height = 25
      Caption = 'Browse...'
      TabOrder = 1
      OnClick = btnBrowseSchemaClick
    end
    object edtSeed: TEdit
      Left = 70
      Top = 52
      Width = 120
      Height = 23
      TabOrder = 2
    end
    object btnRandomSeed: TButton
      Left = 200
      Top = 51
      Width = 95
      Height = 25
      Caption = 'Random Seed'
      TabOrder = 3
      OnClick = btnRandomSeedClick
    end
    object edtCount: TEdit
      Left = 365
      Top = 52
      Width = 60
      Height = 23
      TabOrder = 4
    end
    object btnGenerate: TButton
      Left = 470
      Top = 51
      Width = 140
      Height = 25
      Caption = 'Generate Mock'
      TabOrder = 5
      OnClick = btnGenerateClick
    end
    object btnSave: TButton
      Left = 620
      Top = 51
      Width = 160
      Height = 25
      Caption = 'Save to File...'
      TabOrder = 6
      OnClick = btnSaveClick
    end
  end
  object mmoOutput: TMemo
    Left = 0
    Top = 95
    Width = 800
    Height = 375
    Align = alClient
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object pnlStatus: TPanel
    Left = 0
    Top = 470
    Width = 800
    Height = 30
    Align = alBottom
    Alignment = taLeftJustify
    BevelOuter = bvNone
    TabOrder = 2
    object lblStatus: TLabel
      Left = 16
      Top = 8
      Width = 32
      Height = 15
      Caption = 'Ready'
    end
  end
  object dlgOpenSchema: TOpenDialog
    Filter = 'JSON Files (*.json)|*.json|All Files (*.*)|*.*'
    Left = 240
    Top = 160
  end
  object dlgSaveOutput: TSaveDialog
    DefaultExt = 'json'
    Filter = 'JSON Files (*.json)|*.json|All Files (*.*)|*.*'
    Left = 350
    Top = 160
  end
end
