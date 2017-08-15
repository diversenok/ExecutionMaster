object ExecListDialog: TExecListDialog
  Left = 353
  Top = 325
  Caption = 'Execution Master by diversenok'
  ClientHeight = 264
  ClientWidth = 648
  Color = clBtnFace
  Constraints.MinWidth = 510
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  ShowHint = True
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object PanelRight: TPanel
    Left = 404
    Top = 0
    Width = 244
    Height = 264
    Align = alRight
    BevelOuter = bvNone
    TabOrder = 0
    object LabelImagePath: TLabel
      Left = 8
      Top = 8
      Width = 86
      Height = 13
      Caption = 'Executable name:'
    end
    object GroupBoxAction: TGroupBox
      Left = 6
      Top = 56
      Width = 233
      Height = 206
      Caption = 'Action '
      TabOrder = 0
      object LabelNote: TLabel
        Left = 8
        Top = 160
        Width = 142
        Height = 43
        AutoSize = False
        Caption = 'Note: the last parameter will be original filename.'
        WordWrap = True
      end
      object EditExec: TEdit
        Left = 8
        Top = 132
        Width = 217
        Height = 21
        Enabled = False
        TabOrder = 0
      end
      object ButtonBrowseExec: TButton
        Left = 153
        Top = 160
        Width = 72
        Height = 25
        Caption = 'Browse'
        Enabled = False
        TabOrder = 1
        OnClick = ButtonBrowseExecClick
      end
    end
    object ButtonBrowse: TButton
      Left = 175
      Top = 25
      Width = 66
      Height = 25
      Caption = 'Browse'
      TabOrder = 1
      OnClick = ButtonBrowseClick
    end
    object EditImage: TEdit
      Left = 8
      Top = 27
      Width = 161
      Height = 21
      TabOrder = 2
    end
  end
  object PanelLeft: TPanel
    Left = 0
    Top = 0
    Width = 404
    Height = 264
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object ListViewExec: TListView
      Left = 0
      Top = 0
      Width = 404
      Height = 231
      Align = alClient
      Columns = <
        item
          Caption = 'Executable'
          MinWidth = 50
          Width = 180
        end
        item
          Caption = 'Action'
          Width = 220
        end>
      ColumnClick = False
      ReadOnly = True
      RowSelect = True
      TabOrder = 0
      ViewStyle = vsReport
      OnChange = ListViewExecChange
    end
    object PanelBottom: TPanel
      Left = 0
      Top = 231
      Width = 404
      Height = 33
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 1
      object ButtonRefresh: TBitBtn
        Left = 8
        Top = 4
        Width = 75
        Height = 25
        Caption = 'Refresh'
        Glyph.Data = {
          36050000424D3605000000000000360400002800000010000000100000000100
          08000000000000010000C40E0000C40E00000001000000010000623720007E47
          2A0094543100A6613700B26B3900B8713900BD783900C27F3900CA8E3900CE97
          3800D5A83500DAB53300DC00FF00BCA09200D0A78A00DBB78A00C7A69500CFAD
          9800D5B6A400E3C89900E7D09700E4CAA500D3C8C300E0CFC700EEE1C800F1E8
          C800FAFAFA000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          00000000000000000000000000000000000000000000000000000C0C0C0C0C0C
          0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C1A1A0C0C0C0C0C0C0C0C0C0C0C
          0C0C1600001A0C0C0C0C0C0C0C0C0C0C0C0C0C1A010D1A0C0C0C0C0C0C0C0C0C
          0C0C0C0C1002170C0C0C0C0C0C0C1A0C0C0C0C0C1203111A0C0C0C0C0C1A041A
          0C0C1A1A0E04041A1A0C0C0C1A0505051A1A050505050505051A0C1A06060606
          051A1A06060606061A0C1A070707070707071A1A0707071A0C0C0C1A1A07080F
          1A1A0C0C1A071A0C0C0C0C0C0C1308150C0C0C0C0C1A0C0C0C0C0C0C0C180913
          0C0C0C0C0C0C0C0C0C0C0C0C0C1A140A1A0C0C0C0C0C0C0C0C0C0C0C0C0C1A0B
          0B190C0C0C0C0C0C0C0C0C0C0C0C0C1A1A0C0C0C0C0C0C0C0C0C}
        TabOrder = 0
        OnClick = Refresh
      end
      object ButtonDelete: TButton
        Left = 90
        Top = 4
        Width = 75
        Height = 25
        Caption = ' Delete'
        Enabled = False
        TabOrder = 1
        OnClick = ButtonDeleteClick
      end
      object PanelAdd: TPanel
        Left = 324
        Top = 0
        Width = 80
        Height = 33
        Align = alRight
        BevelOuter = bvNone
        TabOrder = 2
        object ButtonAdd: TButton
          Left = 2
          Top = 4
          Width = 75
          Height = 25
          Caption = ' Add'
          TabOrder = 0
          OnClick = ButtonAddClick
        end
      end
    end
  end
  object OpenDlg: TOpenDialog
    Filter = 'Executables (*.exe; *.com)|*.exe; *.com'
    Options = [ofReadOnly, ofEnableSizing]
    Left = 593
    Top = 80
  end
end
