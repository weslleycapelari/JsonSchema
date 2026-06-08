object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Gerador de C'#243'digo Delphi a partir de JSON Schema'
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
  object pnlTopPanel: TPanel
    Left = 0
    Top = 4
    Width = 884
    Height = 64
    Align = alTop
    BevelOuter = bvNone
    Caption = 'pnlTopPanel'
    ShowCaption = False
    TabOrder = 0
    object Label1: TLabel
      Left = 6
      Top = 10
      Width = 77
      Height = 15
      Caption = 'Nome da Unit:'
      FocusControl = edtUnitName
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 13395456
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object Label2: TLabel
      Left = 6
      Top = 39
      Width = 88
      Height = 15
      Caption = 'Nome da Classe:'
      FocusControl = edtClassName
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 13395456
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object edtUnitName: TEdit
      Left = 100
      Top = 6
      Width = 229
      Height = 23
      TabOrder = 0
      Text = 'MyUnitName'
    end
    object btnGenerate: TButton
      Left = 335
      Top = 6
      Width = 95
      Height = 52
      Caption = '&Gerar C'#243'digo'
      Default = True
      TabOrder = 2
      OnClick = btnGenerateClick
    end
    object edtClassName: TEdit
      Left = 100
      Top = 35
      Width = 229
      Height = 23
      TabOrder = 1
      Text = 'MyClass'
    end
    object btnGenerateLote: TButton
      Left = 776
      Top = 6
      Width = 98
      Height = 52
      Caption = 'Gerar Em &Lote'
      Default = True
      TabOrder = 3
      OnClick = btnGenerateLoteClick
    end
  end
  object pnlStatusPanel: TPanel
    Left = 0
    Top = 570
    Width = 884
    Height = 30
    Align = alBottom
    BevelOuter = bvNone
    Caption = 'pnlStatusPanel'
    ShowCaption = False
    TabOrder = 1
    object LabelStatus: TLabel
      Left = 0
      Top = 0
      Width = 884
      Height = 30
      Align = alClient
      Alignment = taCenter
      Caption = 'Ready'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 13395456
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsItalic]
      ParentFont = False
      Layout = tlCenter
      ExplicitWidth = 33
      ExplicitHeight = 15
    end
  end
  object pnlClient: TPanel
    Left = 0
    Top = 68
    Width = 884
    Height = 502
    Align = alClient
    BevelOuter = bvNone
    Caption = 'pnlClient'
    ShowCaption = False
    TabOrder = 2
    object spl1: TSplitter
      Left = 430
      Top = 0
      Width = 5
      Height = 502
      ExplicitLeft = 369
      ExplicitHeight = 397
    end
    object mmoPasOutput: TMemo
      Left = 435
      Top = 0
      Width = 449
      Height = 502
      Align = alClient
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Consolas'
      Font.Style = []
      Lines.Strings = (
        '// O c'#243'digo Delphi gerado aparecer'#225' aqui...')
      ParentFont = False
      CanUndoSelText = True
      ScrollBars = ssVertical
      TabOrder = 1
    end
    object mmoSchemaInput: TMemo
      Left = 0
      Top = 0
      Width = 430
      Height = 502
      Align = alLeft
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Consolas'
      Font.Style = []
      Lines.Strings = (
        '{'
        '    "$schema": "https://json-schema.org/draft/2020-'
        '12/schema",'
        '    "$id": "https://example.com/product.schema.json",'
        '    "title": "Product",'
        '    "description": "A product from Acme'#39's catalog",'
        '    "type": "object",'
        '    "properties": {'
        '        "productId": {'
        '            "description": "The unique identifier for a '
        'product",'
        '            "type": "integer"'
        '        },'
        '        "productName": {'
        '            "description": "Name of the product",'
        '            "type": "string"'
        '        }'
        '    },'
        '    "required": ["productId", "productName"]'
        '}'
        '')
      ParentFont = False
      CanUndoSelText = True
      ScrollBars = ssVertical
      TabOrder = 0
    end
  end
end
