object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'SchemaOptimizer - JSON Schema Simplification Utility'
  ClientHeight = 620
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
    Height = 590
    Cursor = crHSplit
  end
  object pnlLeft: TPanel
    Left = 0
    Top = 0
    Width = 380
    Height = 590
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      380
      590)
    object lblSchemaInput: TLabel
      Left = 16
      Top = 56
      Width = 113
      Height = 15
      Caption = 'Input JSON Schema:'
    end
    object btnLoadFile: TButton
      Left = 16
      Top = 16
      Width = 150
      Height = 25
      Caption = 'Load File...'
      TabOrder = 0
      OnClick = btnLoadFileClick
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
      TabOrder = 1
      WordWrap = False
    end
    object chkRemoveUnused: TCheckBox
      Left = 16
      Top = 495
      Width = 220
      Height = 17
      Anchors = [akLeft, akBottom]
      Caption = 'Remove Unused Definitions'
      TabOrder = 2
    end
    object chkMergeAllOf: TCheckBox
      Left = 16
      Top = 515
      Width = 220
      Height = 17
      Anchors = [akLeft, akBottom]
      Caption = 'Merge allOf blocks'
      TabOrder = 3
    end
    object chkPruneEmpty: TCheckBox
      Left = 16
      Top = 535
      Width = 220
      Height = 17
      Anchors = [akLeft, akBottom]
      Caption = 'Prune Empty & Duplicates'
      TabOrder = 4
    end
    object chkMinify: TCheckBox
      Left = 16
      Top = 555
      Width = 220
      Height = 17
      Anchors = [akLeft, akBottom]
      Caption = 'Minify JSON Output'
      TabOrder = 5
    end
  end
  object pnlRight: TPanel
    Left = 385
    Top = 0
    Width = 499
    Height = 590
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    DesignSize = (
      499
      590)
    object lblOutputSchema: TLabel
      Left = 16
      Top = 16
      Width = 107
      Height = 15
      Caption = 'Optimized Output:'
    end
    object mmoOutputSchema: TMemo
      Left = 16
      Top = 40
      Width = 467
      Height = 485
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
      Top = 540
      Width = 467
      Height = 35
      Anchors = [akLeft, akRight, akBottom]
      BevelOuter = bvNone
      TabOrder = 1
      DesignSize = (
        467
        35)
      object btnOptimize: TButton
        Left = 0
        Top = 5
        Width = 130
        Height = 25
        Caption = 'Optimize Schema'
        Default = True
        TabOrder = 0
        OnClick = btnOptimizeClick
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
    Top = 590
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
