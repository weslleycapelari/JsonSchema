object frmLote: TfrmLote
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Gerador de C'#243'digo Delphi a partir de JSON Schema - Gerar em Lote'
  ClientHeight = 408
  ClientWidth = 575
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  TextHeight = 15
  object pnlBody: TPanel
    Left = 0
    Top = 0
    Width = 575
    Height = 376
    Align = alClient
    TabOrder = 0
    object pnlBody1: TPanel
      Left = 1
      Top = 1
      Width = 573
      Height = 30
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      object lblSchemaPath: TLabel
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 86
        Height = 24
        Align = alLeft
        AutoSize = False
        Caption = 'JSON-Schema'
        Layout = tlCenter
        ExplicitHeight = 16
      end
      object edtSchemaPath: TEdit
        AlignWithMargins = True
        Left = 95
        Top = 3
        Width = 439
        Height = 24
        Align = alClient
        TabOrder = 0
        Text = '../../../tests/json_1.schema.json'
        ExplicitHeight = 23
      end
      object btnSchemaPath: TButton
        AlignWithMargins = True
        Left = 540
        Top = 3
        Width = 30
        Height = 24
        Align = alRight
        Caption = '...'
        TabOrder = 1
        OnClick = btnSchemaPathClick
      end
    end
    object pnlBody2: TPanel
      Left = 1
      Top = 31
      Width = 573
      Height = 30
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 1
      object lblOutputPath: TLabel
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 86
        Height = 24
        Align = alLeft
        AutoSize = False
        Caption = 'Output Path'
        Layout = tlCenter
        ExplicitHeight = 26
      end
      object edtOutputPath: TEdit
        AlignWithMargins = True
        Left = 95
        Top = 3
        Width = 439
        Height = 24
        Align = alClient
        TabOrder = 0
        Text = '../../../sample'
        ExplicitHeight = 23
      end
      object btnOutputPath: TButton
        AlignWithMargins = True
        Left = 540
        Top = 3
        Width = 30
        Height = 24
        Align = alRight
        Caption = '...'
        TabOrder = 1
        OnClick = btnOutputPathClick
      end
    end
    object grpOptions: TGroupBox
      AlignWithMargins = True
      Left = 4
      Top = 64
      Width = 567
      Height = 81
      Align = alTop
      Caption = 'Options'
      TabOrder = 2
      object pnlBody3: TPanel
        Left = 2
        Top = 17
        Width = 563
        Height = 30
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object lblRootName: TLabel
          AlignWithMargins = True
          Left = 3
          Top = 3
          Width = 81
          Height = 24
          Align = alLeft
          AutoSize = False
          Caption = 'Unit Name'
          Layout = tlCenter
          ExplicitHeight = 26
        end
        object edtUnitName: TEdit
          AlignWithMargins = True
          Left = 90
          Top = 3
          Width = 470
          Height = 24
          Align = alClient
          TabOrder = 0
          Text = 'test'
          ExplicitHeight = 23
        end
      end
      object pnlBody4: TPanel
        Left = 2
        Top = 47
        Width = 563
        Height = 30
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 1
        object lblBaseID: TLabel
          AlignWithMargins = True
          Left = 3
          Top = 3
          Width = 81
          Height = 24
          Align = alLeft
          AutoSize = False
          Caption = 'Class Name'
          Layout = tlCenter
          ExplicitHeight = 26
        end
        object edtClassName: TEdit
          AlignWithMargins = True
          Left = 90
          Top = 3
          Width = 470
          Height = 24
          Align = alClient
          TabOrder = 0
          Text = 'example.id'
          ExplicitHeight = 23
        end
      end
    end
    object grpHistory: TGroupBox
      AlignWithMargins = True
      Left = 4
      Top = 151
      Width = 567
      Height = 221
      Align = alClient
      Caption = 'History Configs'
      TabOrder = 3
      object lstHistory: TListBox
        AlignWithMargins = True
        Left = 5
        Top = 20
        Width = 557
        Height = 196
        Align = alClient
        ItemHeight = 15
        TabOrder = 0
        OnClick = lstHistoryClick
      end
    end
  end
  object pnlButtons: TPanel
    Left = 0
    Top = 376
    Width = 575
    Height = 32
    Align = alBottom
    TabOrder = 1
    object lblCodeEncoding: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 4
      Width = 91
      Height = 15
      Align = alLeft
      Caption = 'Output Encoding'
      Layout = tlCenter
    end
    object btnConvertSchema: TButton
      AlignWithMargins = True
      Left = 450
      Top = 4
      Width = 121
      Height = 24
      Align = alRight
      Caption = 'Convert Schema'
      TabOrder = 0
      OnClick = btnConvertSchemaClick
    end
    object cbbCodeEncoding: TComboBox
      AlignWithMargins = True
      Left = 101
      Top = 4
      Width = 145
      Height = 23
      Align = alLeft
      Style = csDropDownList
      TabOrder = 1
      StyleName = 'Windows'
    end
    object btnConvertAll: TButton
      AlignWithMargins = True
      Left = 323
      Top = 4
      Width = 121
      Height = 24
      Align = alRight
      Caption = 'Convert All'
      TabOrder = 2
      OnClick = btnConvertAllClick
    end
  end
end
