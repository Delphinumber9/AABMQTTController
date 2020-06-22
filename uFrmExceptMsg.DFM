object frmError: TfrmError
  Left = 35
  Top = 126
  Width = 625
  Height = 607
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  Caption = 'iAvant Systemmeldung'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 40
    Top = 120
    Width = 315
    Height = 13
    Caption = 
      'Die detaillierte Meldung wird in der Datei Errorlog.txt aufgezei' +
      'chnet.'
  end
  object btn_OK: TButton
    Left = 476
    Top = 24
    Width = 117
    Height = 25
    Caption = 'OK'
    TabOrder = 0
    OnClick = btn_OKClick
  end
  object btn_Details: TButton
    Left = 476
    Top = 88
    Width = 117
    Height = 25
    Caption = 'Details zeigen'
    TabOrder = 1
    OnClick = btn_DetailsClick
  end
  object GroupBox1: TGroupBox
    Left = 40
    Top = 16
    Width = 410
    Height = 97
    Caption = 'Meldung'
    TabOrder = 2
    object lbl_UserMessage: TLabel
      Left = 15
      Top = 24
      Width = 65
      Height = 13
      Caption = 'UserMessage'
      Constraints.MaxWidth = 370
    end
  end
  object gbx_Details: TGroupBox
    Left = 40
    Top = 152
    Width = 553
    Height = 409
    Caption = 'Details'
    TabOrder = 3
    object mmo_DetailMessage: TMemo
      Left = 8
      Top = 16
      Width = 537
      Height = 385
      Lines.Strings = (
        '')
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
    end
  end
  object btn_Terminate: TButton
    Left = 476
    Top = 56
    Width = 117
    Height = 25
    Caption = 'Programm abbrechen'
    TabOrder = 4
    OnClick = btn_TerminateClick
  end
end
