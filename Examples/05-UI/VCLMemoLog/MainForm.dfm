object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Dext Framework - VCL Logging Example'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 624
    Height = 81
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 13
      Width = 238
      Height = 21
      Caption = 'Dext Logging System - VCL Demo'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object btnInfo: TButton
      Left = 16
      Top = 45
      Width = 100
      Height = 25
      Caption = 'Log Info'
      TabOrder = 0
      OnClick = btnInfoClick
    end
    object btnWarn: TButton
      Left = 122
      Top = 45
      Width = 100
      Height = 25
      Caption = 'Log Warning'
      TabOrder = 1
      OnClick = btnWarnClick
    end
    object btnError: TButton
      Left = 228
      Top = 45
      Width = 100
      Height = 25
      Caption = 'Log Error'
      TabOrder = 2
      OnClick = btnErrorClick
    end
    object btnStressTest: TButton
      Left = 508
      Top = 45
      Width = 100
      Height = 25
      Caption = 'Stress Test'
      TabOrder = 3
      OnClick = btnStressTestClick
    end
  end
  object memoLogs: TMemo
    Left = 0
    Top = 81
    Width = 624
    Height = 360
    Align = alClient
    Color = 3355443
    Font.Charset = ANSI_CHARSET
    Font.Color = clWhite
    Font.Height = -12
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
  end
end
