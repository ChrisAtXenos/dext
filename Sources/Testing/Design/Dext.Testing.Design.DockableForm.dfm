object FormDextTestRunner: TFormDextTestRunner
  Left = 0
  Top = 0
  Caption = 'Dext Test Explorer'
  ClientHeight = 500
  ClientWidth = 571
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 13
  object NameSplitter: TSplitter
    Left = 0
    Top = 277
    Width = 571
    Height = 3
    Cursor = crVSplit
    Align = alBottom
    ExplicitTop = 300
    ExplicitWidth = 350
  end
  object SessionsPageControl: TPageControl
    Left = 0
    Top = 66
    Width = 571
    Height = 211
    ActivePage = DefaultSessionTabSheet
    Align = alClient
    TabOrder = 0
    object DefaultSessionTabSheet: TTabSheet
      Caption = 'Tests'
      object TestsTreeView: TTreeView
        Left = 0
        Top = 0
        Width = 563
        Height = 183
        Align = alClient
        Indent = 19
        ReadOnly = True
        TabOrder = 0
        OnDblClick = TestsTreeViewDblClick
      end
    end
  end
  object DetailsPanel: TPanel
    Left = 0
    Top = 280
    Width = 571
    Height = 220
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object DetailsMemo: TMemo
      Left = 0
      Top = 30
      Width = 571
      Height = 190
      Align = alClient
      ReadOnly = True
      ScrollBars = ssBoth
      TabOrder = 0
    end
    object SummaryPanel: TPanel
      Left = 0
      Top = 0
      Width = 571
      Height = 30
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 1
      object SummaryTotalLabel: TLabel
        AlignWithMargins = True
        Left = 3
        Top = 6
        Width = 55
        Height = 18
        Margins.Top = 6
        Margins.Bottom = 6
        Align = alLeft
        Caption = 'Total: 9999'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        ExplicitHeight = 13
      end
      object SummarySelectedLabel: TLabel
        AlignWithMargins = True
        Left = 64
        Top = 6
        Width = 73
        Height = 18
        Margins.Top = 6
        Margins.Bottom = 6
        Align = alLeft
        Caption = 'Selected: 9999'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        ExplicitHeight = 13
      end
      object SummarySuccessLabel: TLabel
        AlignWithMargins = True
        Left = 143
        Top = 6
        Width = 66
        Height = 18
        Margins.Top = 6
        Margins.Bottom = 6
        Align = alLeft
        Caption = 'Passed: 9999'
        Color = clBtnFace
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGreen
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
        ExplicitHeight = 13
      end
      object SummaryFailedLabel: TLabel
        AlignWithMargins = True
        Left = 215
        Top = 6
        Width = 61
        Height = 18
        Margins.Top = 6
        Margins.Bottom = 6
        Align = alLeft
        Caption = 'Failed: 9999'
        Color = clBtnFace
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clRed
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
        ExplicitHeight = 13
      end
      object SummarySkippedLabel: TLabel
        AlignWithMargins = True
        Left = 282
        Top = 6
        Width = 72
        Height = 18
        Margins.Top = 6
        Margins.Bottom = 6
        Align = alLeft
        Caption = 'Skipped: 9999'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        ExplicitHeight = 13
      end
      object SummaryTimeLabel: TLabel
        AlignWithMargins = True
        Left = 360
        Top = 6
        Width = 87
        Height = 18
        Margins.Top = 6
        Margins.Bottom = 6
        Align = alLeft
        Caption = 'Time: 9999.9999s'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        ExplicitHeight = 13
      end
      object SummaryTotalTimeLabel: TLabel
        AlignWithMargins = True
        Left = 453
        Top = 6
        Width = 112
        Height = 18
        Margins.Top = 6
        Margins.Bottom = 6
        Align = alLeft
        Caption = 'Total Time: 9999.9999s'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        ExplicitHeight = 13
      end
    end
  end
  object ButtonsPanel: TPanel
    Left = 0
    Top = 35
    Width = 571
    Height = 31
    Margins.Left = 0
    Margins.Right = 0
    Margins.Bottom = 6
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 2
    object RefreshButton: TButton
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 80
      Height = 25
      Align = alLeft
      Caption = 'Refresh'
      TabOrder = 0
      OnClick = RefreshButtonClick
    end
    object RunAllButton: TButton
      AlignWithMargins = True
      Left = 89
      Top = 3
      Width = 85
      Height = 25
      Align = alLeft
      Caption = 'Run All'
      TabOrder = 1
      OnClick = RunAllButtonClick
    end
    object RunSelectedButton: TButton
      AlignWithMargins = True
      Left = 180
      Top = 3
      Width = 85
      Height = 25
      Align = alLeft
      Caption = 'Selected'
      TabOrder = 2
      OnClick = RunSelectedButtonClick
    end
    object StopButton: TButton
      AlignWithMargins = True
      Left = 271
      Top = 3
      Width = 50
      Height = 25
      Align = alLeft
      Caption = 'Stop'
      TabOrder = 3
      OnClick = StopButtonClick
    end
    object ActionsButton: TButton
      AlignWithMargins = True
      Left = 543
      Top = 3
      Width = 25
      Height = 25
      Align = alRight
      Caption = '...'
      TabOrder = 4
      OnClick = ActionsButtonClick
    end
  end
  object ProjectsComboBox: TComboBox
    AlignWithMargins = True
    Left = 3
    Top = 7
    Width = 565
    Height = 21
    Margins.Top = 7
    Margins.Bottom = 7
    Align = alTop
    Style = csDropDownList
    TabOrder = 3
    OnChange = ProjectsComboBoxChange
  end
  object ActionsPopupMenu: TPopupMenu
    Left = 396
    Top = 122
    object EnableDisableTestExplorerMenuItem: TMenuItem
      Caption = 'Disable Test Explorer'
      Hint = 'Disable Test Explorer'
    end
    object CreateaNewSessionMenuItem: TMenuItem
      Caption = 'Create a New Session'
    end
    object ClearMenuItem: TMenuItem
      Caption = 'Clear Tests and Console Log'
      Hint = 'Clear Tests and Console Log'
    end
    object ClearSeparator: TMenuItem
      Caption = '-'
    end
    object GroupByClassMenuItem: TMenuItem
      Caption = 'Group by Code Structure'
      GroupIndex = 10
      RadioItem = True
    end
    object GroupByTestStatusMenuItem: TMenuItem
      Caption = 'Group by Test Status'
      GroupIndex = 10
      RadioItem = True
    end
    object LayoutSeparator: TMenuItem
      AutoCheck = True
      Caption = '-'
      GroupIndex = 10
      RadioItem = True
    end
    object SplitBottomLayoutMenuItem: TMenuItem
      AutoCheck = True
      Caption = 'Split Bottom Layout'
      GroupIndex = 20
      RadioItem = True
    end
    object SplitRightLayoutMenuItem: TMenuItem
      AutoCheck = True
      Caption = 'Split Right Layout'
      GroupIndex = 20
      RadioItem = True
    end
    object TabbedLayoutMenuItem: TMenuItem
      AutoCheck = True
      Caption = 'Tabbed Layout'
      GroupIndex = 20
      Hint = 'Tabbed Layout at Bottom'
      RadioItem = True
    end
    object ExportSeparator: TMenuItem
      Caption = '-'
      GroupIndex = 20
    end
    object ExportToJUnitXmlMenutem: TMenuItem
      Caption = 'Export to JUnit XML'
      GroupIndex = 20
      Hint = 'Export test execution report to JUnit XML'
    end
    object ExportToXUnitXMLMenutem: TMenuItem
      Caption = 'Export to XUnit XML'
      GroupIndex = 20
      Hint = 'Export test execution report to XUnit XML'
    end
    object ExportToJsonMenutem: TMenuItem
      Caption = 'Export to JSON'
      GroupIndex = 20
      Hint = 'Export test execution report to JSON'
    end
    object ExportToSonarQubeXmlMenutem: TMenuItem
      Caption = 'Export to SonarQube XML'
      GroupIndex = 20
      Hint = 'Export test execution report to SonarQube XML'
    end
    object ExportToHtmlReportMenuItem: TMenuItem
      Caption = 'Export to HTML Report'
      GroupIndex = 20
      Hint = 'Export test execution report to HTML Report'
    end
  end
end
