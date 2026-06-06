object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'SchemaBundler - JSON Schema Packaging Utility'
  ClientHeight = 561
  ClientWidth = 884
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 15
  object splSplitter: TSplitter
    Left = 380
    Top = 0
    Width = 5
    Height = 531
    Cursor = crHSplit
  end
  object pnlLeft: TPanel
    Left = 0
    Top = 0
    Width = 380
    Height = 531
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      380
      531)
    object lblFilePath: TLabel
      Left = 16
      Top = 16
      Width = 50
      Height = 15
      Caption = 'Root File:'
    end
    object lblSchemaInput: TLabel
      Left = 16
      Top = 56
      Width = 126
      Height = 15
      Caption = 'Root Schema Contents:'
    end
    object edtFilePath: TEdit
      Left = 80
      Top = 13
      Width = 200
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      ReadOnly = True
      TabOrder = 0
    end
    object btnSelectFile: TButton
      Left = 290
      Top = 12
      Width = 74
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Select...'
      TabOrder = 1
      OnClick = btnSelectFileClick
    end
    object mmoSchemaInput: TMemo
      Left = 16
      Top = 80
      Width = 348
      Height = 400
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
    object chkLegacy: TCheckBox
      Left = 16
      Top = 495
      Width = 150
      Height = 17
      Anchors = [akLeft, akBottom]
      Caption = 'Legacy "definitions"'
      TabOrder = 3
    end
    object chkIndent: TCheckBox
      Left = 200
      Top = 495
      Width = 150
      Height = 17
      Anchors = [akLeft, akBottom]
      Caption = 'Indent Output'
      TabOrder = 4
    end
  end
  object pnlRight: TPanel
    Left = 385
    Top = 0
    Width = 499
    Height = 531
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    DesignSize = (
      499
      531)
    object lblBundledOutput: TLabel
      Left = 16
      Top = 16
      Width = 92
      Height = 15
      Caption = 'Bundled Schema:'
    end
    object mmoBundledOutput: TMemo
      Left = 16
      Top = 40
      Width = 467
      Height = 425
      Anchors = [akLeft, akTop, akRight, akBottom]
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
    object pnlButtons: TPanel
      Left = 16
      Top = 480
      Width = 467
      Height = 35
      Anchors = [akLeft, akRight, akBottom]
      BevelOuter = bvNone
      TabOrder = 1
      DesignSize = (
        467
        35)
      object btnGenerate: TButton
        Left = 0
        Top = 5
        Width = 130
        Height = 25
        Caption = 'Bundle Schema'
        Default = True
        TabOrder = 0
        OnClick = btnGenerateClick
      end
      object btnCopy: TButton
        Left = 144
        Top = 5
        Width = 150
        Height = 25
        Caption = 'Copy to Clipboard'
        TabOrder = 1
        OnClick = btnCopyClick
      end
      object btnExport: TButton
        Left = 307
        Top = 5
        Width = 160
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Export Schema...'
        TabOrder = 2
        OnClick = btnExportClick
      end
    end
  end
  object pnlStatus: TPanel
    Left = 0
    Top = 531
    Width = 884
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
      Caption = 'Status'
    end
  end
  object dlgSave: TSaveDialog
    Left = 400
    Top = 80
  end
  object dlgOpen: TOpenDialog
    Left = 400
    Top = 130
  end
end
