object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Schema2REST - JSON Schema to Delphi REST Endpoint Generator'
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
    object lblFramework: TLabel
      Left = 16
      Top = 16
      Width = 63
      Height = 15
      Caption = 'Framework:'
    end
    object lblEntityName: TLabel
      Left = 16
      Top = 48
      Width = 68
      Height = 15
      Caption = 'Entity Name:'
    end
    object lblSchemaInput: TLabel
      Left = 16
      Top = 88
      Width = 104
      Height = 15
      Caption = 'Input JSON Schema:'
    end
    object cboFramework: TComboBox
      Left = 120
      Top = 13
      Width = 240
      Height = 23
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
    end
    object edtEntityName: TEdit
      Left = 120
      Top = 45
      Width = 240
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 1
      Text = 'Customer'
    end
    object mmoSchemaInput: TMemo
      Left = 16
      Top = 112
      Width = 348
      Height = 401
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
  object pnlRight: TPanel
    Left = 385
    Top = 0
    Width = 499
    Height = 531
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object lblPascalOutput: TLabel
      Left = 16
      Top = 16
      Width = 126
      Height = 15
      Caption = 'Generated Pascal Code:'
    end
    object mmoPascalOutput: TMemo
      Left = 16
      Top = 45
      Width = 467
      Height = 422
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
      Left = 0
      Top = 481
      Width = 499
      Height = 50
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 1
      DesignSize = (
        499
        50)
      object btnGenerate: TButton
        Left = 16
        Top = 10
        Width = 130
        Height = 30
        Caption = 'Generate REST'
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
        Left = 160
        Top = 10
        Width = 120
        Height = 30
        Caption = 'Copy Code'
        TabOrder = 1
        OnClick = btnCopyClick
      end
      object btnExport: TButton
        Left = 296
        Top = 10
        Width = 120
        Height = 30
        Caption = 'Export File...'
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
      Caption = 'Ready'
    end
  end
  object dlgSave: TSaveDialog
    Left = 784
    Top = 496
  end
end
