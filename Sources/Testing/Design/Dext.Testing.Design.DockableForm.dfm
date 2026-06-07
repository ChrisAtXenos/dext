object FormDextTestRunner: TFormDextTestRunner
  Left = 0
  Top = 0
  Caption = 'Dext Test Explorer'
  ClientHeight = 500
  ClientWidth = 350
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 0
    Top = 350
    Width = 350
    Height = 3
    Cursor = crVSplit
    Align = alBottom
    ExplicitTop = 300
    ExplicitWidth = 350
  end
  object pnlToolbar: TPanel
    Left = 0
    Top = 0
    Width = 350
    Height = 35
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object cbProjects: TComboBox
      Left = 5
      Top = 7
      Width = 150
      Height = 21
      Style = csDropDownList
      TabOrder = 0
      OnChange = cbProjectsChange
    end
    object btnRunAll: TButton
      Left = 160
      Top = 5
      Width = 50
      Height = 25
      Caption = 'Run All'
      TabOrder = 1
      OnClick = btnRunAllClick
    end
    object btnRunSelected: TButton
      Left = 215
      Top = 5
      Width = 55
      Height = 25
      Caption = 'Selected'
      TabOrder = 2
      OnClick = btnRunSelectedClick
    end
    object btnStop: TButton
      Left = 275
      Top = 5
      Width = 40
      Height = 25
      Caption = 'Stop'
      TabOrder = 3
      OnClick = btnStopClick
    end
  end
  object pcSessions: TPageControl
    Left = 0
    Top = 35
    Width = 350
    Height = 315
    ActivePage = tsDefaultSession
    Align = alClient
    TabOrder = 1
    object tsDefaultSession: TTabSheet
      Caption = 'Tests'
      object tvTests: TTreeView
        Left = 0
        Top = 0
        Width = 342
        Height = 287
        Align = alClient
        Indent = 19
        ReadOnly = True
        TabOrder = 0
        OnDblClick = tvTestsDblClick
      end
    end
  end
  object pnlDetails: TPanel
    Left = 0
    Top = 353
    Width = 350
    Height = 147
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object memDetails: TMemo
      Left = 0
      Top = 0
      Width = 350
      Height = 147
      Align = alClient
      ReadOnly = True
      ScrollBars = ssBoth
      TabOrder = 0
    end
  end
end
