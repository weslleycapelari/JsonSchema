object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Delphi2Schema - JSON Schema Generator'
  ClientHeight = 561
  ClientWidth = 784
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 784
    Height = 113
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      784
      113)
    object lblBpl: TLabel
      Left = 16
      Top = 16
      Width = 70
      Height = 15
      Caption = 'BPL Package:'
    end
    object lblClass: TLabel
      Left = 16
      Top = 48
      Width = 65
      Height = 15
      Caption = 'Class Name:'
    end
    object edtBplPath: TEdit
      Left = 96
      Top = 13
      Width = 570
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      ReadOnly = True
      TabOrder = 0
    end
    object btnBrowseBpl: TButton
      Left = 672
      Top = 12
      Width = 97
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Browse...'
      TabOrder = 1
      OnClick = btnBrowseBplClick
    end
    object cboClass: TComboBox
      Left = 96
      Top = 45
      Width = 570
      Height = 23
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 2
    end
    object chkScanFields: TCheckBox
      Left = 96
      Top = 80
      Width = 97
      Height = 17
      Caption = 'Scan Fields'
      TabOrder = 3
    end
    object chkScanProperties: TCheckBox
      Left = 200
      Top = 80
      Width = 121
      Height = 17
      Caption = 'Scan Properties'
      TabOrder = 4
    end
    object chkUseEnumNames: TCheckBox
      Left = 328
      Top = 80
      Width = 145
      Height = 17
      Caption = 'Use Enum Names'
      TabOrder = 5
    end
    object btnGenerate: TButton
      Left = 672
      Top = 44
      Width = 97
      Height = 53
      Anchors = [akTop, akRight]
      Caption = 'Generate'
      TabOrder = 6
      OnClick = btnGenerateClick
    end
  end
  object mmoSchema: TMemo
    Left = 0
    Top = 113
    Width = 784
    Height = 418
    Align = alClient
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 1
    WordWrap = False
  end
  object pnlStatus: TPanel
    Left = 0
    Top = 531
    Width = 784
    Height = 30
    Align = alBottom
    Alignment = taLeftJustify
    BevelOuter = bvNone
    TabOrder = 2
    object lblStatus: TLabel
      Left = 10
      Top = 8
      Width = 32
      Height = 15
      Caption = 'Ready'
    end
  end
  object dlgOpen: TOpenDialog
    Left = 512
    Top = 80
  end
end
