object CounterViewFrame: TCounterViewFrame
  Left = 0
  Top = 0
  Width = 400
  Height = 480
  TabOrder = 0
  object CountLabel: TLabel
    Left = 10
    Top = 10
    Width = 380
    Height = 60
    Alignment = taCenter
    AutoSize = False
    Caption = '0'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = 12092416
    Font.Height = -48
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object StepLabel: TLabel
    Left = 10
    Top = 76
    Width = 380
    Height = 21
    Alignment = taCenter
    AutoSize = False
    Caption = 'Step: 1'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGray
    Font.Height = -16
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
  end
  object HistoryLabel: TLabel
    Left = 10
    Top = 288
    Width = 43
    Height = 15
    Caption = 'History:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object IncrementButton: TButton
    Left = 270
    Top = 110
    Width = 120
    Height = 35
    Caption = '+ 1'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
  end
  object DecrementButton: TButton
    Left = 10
    Top = 110
    Width = 120
    Height = 35
    Caption = '- 1'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
  end
  object IncrementStepButton: TButton
    Left = 270
    Top = 151
    Width = 120
    Height = 35
    Caption = '+ Step'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
  end
  object DecrementStepButton: TButton
    Left = 10
    Top = 151
    Width = 120
    Height = 35
    Caption = '- Step'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
  end
  object ResetButton: TButton
    Left = 150
    Top = 248
    Width = 100
    Height = 30
    Caption = 'Reset'
    TabOrder = 4
  end
  object StepsPanel: TPanel
    Left = 10
    Top = 200
    Width = 380
    Height = 40
    BevelOuter = bvNone
    TabOrder = 5
    object Step1Button: TButton
      Left = 0
      Top = 0
      Width = 120
      Height = 35
      Caption = 'Step = 1'
      TabOrder = 0
    end
    object Step5Button: TButton
      Left = 130
      Top = 0
      Width = 120
      Height = 35
      Caption = 'Step = 5'
      TabOrder = 1
    end
    object Step10Button: TButton
      Left = 260
      Top = 0
      Width = 120
      Height = 35
      Caption = 'Step = 10'
      TabOrder = 2
    end
  end
  object HistoryMemo: TMemo
    Left = 10
    Top = 309
    Width = 380
    Height = 161
    Color = clWhitesmoke
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 6
  end
end
