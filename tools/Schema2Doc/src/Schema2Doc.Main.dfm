object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Schema2Doc - JSON Schema Documentation Generator'
  ClientHeight = 600
  ClientWidth = 884
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object splSplitter: TSplitter
    Left = 380
    Top = 4
    Width = 5
    Height = 566
  end
  object pnlBrandBar: TPanel
    Left = 0
    Top = 0
    Width = 884
    Height = 4
    Align = alTop
    BevelOuter = bvNone
    Color = 13395456
    ParentBackground = False
    TabOrder = 3
  end
  object pnlLeft: TPanel
    Left = 0
    Top = 4
    Width = 380
    Height = 566
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      380
      566)
    object lblFormat: TLabel
      Left = 16
      Top = 16
      Width = 82
      Height = 15
      Caption = 'Output Format:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 13395456
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblTitle: TLabel
      Left = 16
      Top = 48
      Width = 74
      Height = 15
      Caption = 'Override Title:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 13395456
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblSchemaInput: TLabel
      Left = 16
      Top = 88
      Width = 107
      Height = 15
      Caption = 'Input JSON Schema:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 13395456
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object cboFormat: TComboBox
      Left = 120
      Top = 13
      Width = 240
      Height = 23
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
      OnChange = cboFormatChange
    end
    object edtTitle: TEdit
      Left = 120
      Top = 45
      Width = 240
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 1
    end
    object mmoSchemaInput: TMemo
      Left = 16
      Top = 112
      Width = 348
      Height = 436
      Anchors = [akLeft, akTop, akRight, akBottom]
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
      ScrollBars = ssBoth
      TabOrder = 2
      WordWrap = False
    end
  end
  object pnlStatus: TPanel
    Left = 0
    Top = 570
    Width = 884
    Height = 30
    Align = alBottom
    Alignment = taLeftJustify
    BevelOuter = bvNone
    TabOrder = 1
    object lblStatus: TLabel
      Left = 16
      Top = 8
      Width = 32
      Height = 15
      Caption = 'Ready'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 13395456
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlRight: TPanel
    Left = 385
    Top = 4
    Width = 499
    Height = 566
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    DesignSize = (
      499
      566)
    object lblDocOutput: TLabel
      Left = 16
      Top = 16
      Width = 116
      Height = 15
      Caption = 'Generated Document:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 13395456
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object pgcOutput: TPageControl
      Left = 16
      Top = 45
      Width = 467
      Height = 457
      ActivePage = tsCode
      Anchors = [akLeft, akTop, akRight, akBottom]
      TabOrder = 0
      object tsCode: TTabSheet
        Caption = 'Code'
        object mmoDocOutput: TMemo
          Left = 0
          Top = 0
          Width = 459
          Height = 427
          Align = alClient
          Font.Charset = ANSI_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Consolas'
          Font.Style = []
          ParentFont = False
          ReadOnly = True
          ScrollBars = ssBoth
          TabOrder = 0
          WordWrap = False
        end
      end
      object tsPreview: TTabSheet
        Caption = 'Visualization'
        ImageIndex = 1
        object wbPreview: TWebBrowser
          Left = 0
          Top = 0
          Width = 459
          Height = 427
          Align = alClient
          TabOrder = 0
          ControlData = {
            4C000000021F0000810F00000000000000000000000000000000000000000000
            000000004C000000000000000000000001000000E0D057007335CF11AE690800
            2B2E126208000000000000004C0000000114020000000000C000000000000046
            8000000000000000000000000000000000000000000000000000000000000000
            00000000000000000100000000000000000000000000000000000000}
        end
      end
    end
    object pnlButtons: TPanel
      Left = 0
      Top = 516
      Width = 499
      Height = 50
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 1
      object btnGenerate: TButton
        Left = 16
        Top = 10
        Width = 140
        Height = 30
        Caption = 'Generate Document'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
        OnClick = btnGenerateClick
      end
      object btnCopy: TButton
        Left = 168
        Top = 10
        Width = 120
        Height = 30
        Caption = 'Copy Document'
        TabOrder = 1
        OnClick = btnCopyClick
      end
      object btnExport: TButton
        Left = 300
        Top = 10
        Width = 120
        Height = 30
        Caption = 'Export File...'
        TabOrder = 2
        OnClick = btnExportClick
      end
    end
  end
  object dlgSave: TSaveDialog
    Left = 784
    Top = 496
  end
end
