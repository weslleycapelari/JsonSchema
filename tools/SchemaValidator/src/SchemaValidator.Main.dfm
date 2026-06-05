object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'JSON Schema Validator GUI'
  ClientHeight = 650
  ClientWidth = 850
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
    Width = 850
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblDraft: TLabel
      Left = 15
      Top = 22
      Width = 74
      Height = 15
      Caption = 'Schema Draft:'
    end
    object lblLocale: TLabel
      Left = 250
      Top = 22
      Width = 37
      Height = 15
      Caption = 'Locale:'
    end
    object cboDraft: TComboBox
      Left = 95
      Top = 18
      Width = 130
      Height = 23
      Style = csDropDownList
      TabOrder = 0
    end
    object cboLocale: TComboBox
      Left = 295
      Top = 18
      Width = 130
      Height = 23
      Style = csDropDownList
      TabOrder = 1
    end
    object chkEnforceFormats: TCheckBox
      Left = 450
      Top = 21
      Width = 150
      Height = 17
      Caption = 'Enforce Formats'
      TabOrder = 2
    end
    object btnValidate: TButton
      Left = 710
      Top = 12
      Width = 120
      Height = 35
      Caption = 'Validate'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
      OnClick = btnValidateClick
    end
  end
  object pnlClient: TPanel
    Left = 0
    Top = 60
    Width = 850
    Height = 390
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object splMain: TSplitter
      Left = 410
      Top = 0
      Width = 5
      Height = 390
    end
    object pnlSchema: TPanel
      Left = 0
      Top = 0
      Width = 410
      Height = 390
      Align = alLeft
      BevelOuter = bvNone
      TabOrder = 0
      object lblSchema: TLabel
        Left = 0
        Top = 0
        Width = 410
        Height = 15
        Align = alTop
        Caption = '  JSON Schema Source'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        ExplicitWidth = 125
      end
      object mmoSchema: TMemo
        Left = 0
        Top = 15
        Width = 410
        Height = 335
        Align = alClient
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ScrollBars = ssBoth
        TabOrder = 0
        WordWrap = False
      end
      object pnlSchemaActions: TPanel
        Left = 0
        Top = 350
        Width = 410
        Height = 40
        Align = alBottom
        BevelOuter = bvNone
        TabOrder = 1
        object btnLoadSchema: TButton
          Left = 8
          Top = 8
          Width = 120
          Height = 25
          Caption = 'Load Schema...'
          TabOrder = 0
          OnClick = btnLoadSchemaClick
        end
      end
    end
    object pnlInstance: TPanel
      Left = 415
      Top = 0
      Width = 435
      Height = 390
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      object lblInstance: TLabel
        Left = 0
        Top = 0
        Width = 435
        Height = 15
        Align = alTop
        Caption = '  JSON Instance to Validate'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        ExplicitWidth = 148
      end
      object mmoInstance: TMemo
        Left = 0
        Top = 15
        Width = 435
        Height = 335
        Align = alClient
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ScrollBars = ssBoth
        TabOrder = 0
        WordWrap = False
      end
      object pnlInstanceActions: TPanel
        Left = 0
        Top = 350
        Width = 435
        Height = 40
        Align = alBottom
        BevelOuter = bvNone
        TabOrder = 1
        object btnLoadInstance: TButton
          Left = 8
          Top = 8
          Width = 120
          Height = 25
          Caption = 'Load Instance...'
          TabOrder = 0
          OnClick = btnLoadInstanceClick
        end
      end
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 450
    Width = 850
    Height = 200
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object lblStatus: TLabel
      Left = 0
      Top = 0
      Width = 850
      Height = 25
      Align = alTop
      AutoSize = False
      Caption = '  Ready'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Layout = tlCenter
    end
    object lstErrors: TListView
      Left = 0
      Top = 25
      Width = 850
      Height = 175
      Align = alClient
      Columns = <
        item
          Caption = 'Keyword'
          Width = 120
        end
        item
          Caption = 'Error Message'
          Width = 450
        end
        item
          Caption = 'Suggested Resolution'
          Width = 250
        end>
      GridLines = True
      ReadOnly = True
      RowSelect = True
      TabOrder = 0
      ViewStyle = vsReport
    end
  end
  object dlgOpen: TOpenDialog
    Left = 520
    Top = 8
  end
end
