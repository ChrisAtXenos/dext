object FormDextTestRunner: TFormDextTestRunner
  Left = 0
  Top = 0
  Caption = 'Dext Test Explorer'
  ClientHeight = 500
  ClientWidth = 637
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 13
  object NameSplitter: TSplitter
    Left = 0
    Top = 350
    Width = 637
    Height = 3
    Cursor = crVSplit
    Align = alBottom
    ExplicitTop = 300
    ExplicitWidth = 350
  end
  object SessionsPageControl: TPageControl
    Left = 0
    Top = 70
    Width = 637
    Height = 280
    ActivePage = DefaultSessionTabSheet
    Align = alClient
    TabOrder = 0
    ExplicitTop = 61
    ExplicitHeight = 289
    object DefaultSessionTabSheet: TTabSheet
      Caption = 'Tests'
      object TestsTreeView: TTreeView
        Left = 0
        Top = 0
        Width = 629
        Height = 252
        Align = alClient
        Indent = 19
        ReadOnly = True
        TabOrder = 0
        OnDblClick = TestsTreeViewDblClick
        ExplicitHeight = 261
      end
    end
  end
  object DetailsPanel: TPanel
    Left = 0
    Top = 353
    Width = 637
    Height = 147
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object DetailsMemo: TMemo
      Left = 0
      Top = 0
      Width = 637
      Height = 147
      Align = alClient
      ReadOnly = True
      ScrollBars = ssBoth
      TabOrder = 0
    end
  end
  object ProjectsComboBox: TComboBox
    AlignWithMargins = True
    Left = 5
    Top = 7
    Width = 627
    Height = 21
    Margins.Left = 5
    Margins.Top = 7
    Margins.Right = 5
    Margins.Bottom = 7
    Align = alTop
    Style = csDropDownList
    TabOrder = 2
    OnChange = ProjectsComboBoxChange
  end
  object ButtonsPanel: TPanel
    AlignWithMargins = True
    Left = 0
    Top = 38
    Width = 637
    Height = 26
    Margins.Left = 0
    Margins.Right = 0
    Margins.Bottom = 6
    Align = alTop
    AutoSize = True
    BevelOuter = bvNone
    TabOrder = 3
    ExplicitTop = 35
    object RefreshButton: TButton
      Left = 5
      Top = 0
      Width = 80
      Height = 25
      Caption = 'Refresh'
      TabOrder = 0
      OnClick = RefreshButtonClick
    end
    object RunAllButton: TButton
      Left = 91
      Top = 1
      Width = 85
      Height = 25
      Caption = 'Run All'
      TabOrder = 1
      OnClick = RunAllButtonClick
    end
    object RunSelectedButton: TButton
      Left = 182
      Top = 1
      Width = 85
      Height = 25
      Caption = 'Selected'
      TabOrder = 2
      OnClick = RunSelectedButtonClick
    end
    object StopButton: TButton
      Left = 273
      Top = 1
      Width = 50
      Height = 25
      Caption = 'Stop'
      TabOrder = 3
      OnClick = StopButtonClick
    end
  end
end
