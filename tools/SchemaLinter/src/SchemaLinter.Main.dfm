object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'SchemaLinter - JSON Schema Static Quality & Security Analyzer'
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
    object lblMinSeverity: TLabel
      Left = 16
      Top = 16
      Width = 72
      Height = 15
      Caption = 'Min Severity:'
    end
    object lblSchemaInput: TLabel
      Left = 16
      Top = 56
      Width = 104
      Height = 15
      Caption = 'Input JSON Schema:'
    end
    object cboMinSeverity: TComboBox
      Left = 120
      Top = 13
      Width = 240
      Height = 23
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
    end
    object mmoSchemaInput: TMemo
      Left = 16
      Top = 80
      Width = 348
      Height = 433
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
    object lblFindings: TLabel
      Left = 16
      Top = 16
      Width = 48
      Height = 15
      Caption = 'Findings:'
    end
    object lvwFindings: TListView
      Left = 16
      Top = 40
      Width = 467
      Height = 425
      Anchors = [akLeft, akTop, akRight, akBottom]
      Columns = <
        item
          Caption = 'Severity'
          Width = 70
        end
        item
          Caption = 'Rule ID'
          Width = 150
        end
        item
          Caption = 'Path'
          Width = 100
        end
        item
          Caption = 'Message'
          Width = 250
        end>
      GridLines = True
      ReadOnly = True
      RowSelect = True
      TabOrder = 0
      ViewStyle = vsReport
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
      object btnAnalyze: TButton
        Left = 0
        Top = 5
        Width = 130
        Height = 25
        Caption = 'Analyze Schema'
        Default = True
        TabOrder = 0
        OnClick = btnAnalyzeClick
      end
      object btnCopy: TButton
        Left = 144
        Top = 5
        Width = 150
        Height = 25
        Caption = 'Copy Markdown Report'
        TabOrder = 1
        OnClick = btnCopyClick
      end
      object btnExport: TButton
        Left = 307
        Top = 5
        Width = 160
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Export Report...'
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
end
