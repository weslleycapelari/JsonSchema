object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'JSON Schema Test Suite - Visual Compliance Runner'
  ClientHeight = 620
  ClientWidth = 950
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 950
    Height = 65
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblSuiteDir: TLabel
      Left = 16
      Top = 11
      Width = 104
      Height = 15
      Caption = 'Test Suite Directory:'
    end
    object lblDraft: TLabel
      Left = 520
      Top = 11
      Width = 75
      Height = 15
      Caption = 'Target Draft:'
    end
    object edtSuiteDir: TEdit
      Left = 16
      Top = 30
      Width = 380
      Height = 23
      TabOrder = 0
    end
    object btnBrowse: TButton
      Left = 402
      Top = 29
      Width = 95
      Height = 25
      Caption = 'Browse...'
      TabOrder = 1
      OnClick = btnBrowseClick
    end
    object cmbDraft: TComboBox
      Left = 520
      Top = 30
      Width = 120
      Height = 23
      Style = csDropDownList
      TabOrder = 2
    end
    object btnRun: TButton
      Left = 660
      Top = 29
      Width = 120
      Height = 25
      Caption = 'Run Test Suite'
      Default = True
      TabOrder = 3
      OnClick = btnRunClick
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 580
    Width = 950
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object lblSummary: TLabel
      Left = 16
      Top = 12
      Width = 47
      Height = 15
      Caption = 'Summary'
    end
    object lblCompliance: TLabel
      Left = 780
      Top = 10
      Width = 145
      Height = 20
      Alignment = taRightJustify
      Caption = 'Compliance: 0.0%'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object pbProgress: TProgressBar
      Left = 320
      Top = 12
      Width = 430
      Height = 17
      TabOrder = 0
    end
  end
  object pnlMain: TPanel
    Left = 0
    Top = 65
    Width = 950
    Height = 515
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object splSplitter: TSplitter
      Left = 320
      Top = 0
      Width = 5
      Height = 515
      Cursor = crHSplit
    end
    object pnlLeft: TPanel
      Left = 0
      Top = 0
      Width = 320
      Height = 515
      Align = alLeft
      BevelOuter = bvNone
      TabOrder = 0
      object tvTestTree: TTreeView
        Left = 0
        Top = 0
        Width = 320
        Height = 515
        Align = alClient
        Indent = 19
        ReadOnly = True
        TabOrder = 0
        OnChange = tvTestTreeChange
      end
    end
    object pnlRight: TPanel
      Left = 325
      Top = 0
      Width = 625
      Height = 515
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      object lblInspection: TLabel
        Left = 16
        Top = 10
        Width = 135
        Height = 20
        Caption = 'Inspection Details'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clHotLight
        Font.Height = -15
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblSchema: TLabel
        Left = 16
        Top = 40
        Width = 77
        Height = 15
        Caption = 'Tested Schema:'
      end
      object lblData: TLabel
        Left = 320
        Top = 40
        Width = 79
        Height = 15
        Caption = 'Data Instance:'
      end
      object lblResultTitle: TLabel
        Left = 16
        Top = 275
        Width = 96
        Height = 15
        Caption = 'Validation Result:'
      end
      object lblResultDetail: TLabel
        Left = 130
        Top = 273
        Width = 70
        Height = 18
        Caption = 'RESULT'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblErrors: TLabel
        Left = 16
        Top = 305
        Width = 83
        Height = 15
        Caption = 'Error Messages:'
      end
      object mmoSchema: TMemo
        Left = 16
        Top = 60
        Width = 285
        Height = 200
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
      object mmoData: TMemo
        Left = 320
        Top = 60
        Width = 285
        Height = 200
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 1
        WordWrap = False
      end
      object mmoErrors: TMemo
        Left = 16
        Top = 325
        Width = 590
        Height = 175
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 2
        WordWrap = False
      end
    end
  end
end
