object ExecListDialog: TExecListDialog
  Left = 353
  Top = 325
  Caption = 'Execution Master by diversenok'
  ClientHeight = 347
  ClientWidth = 693
  Color = clBtnFace
  Constraints.MinWidth = 510
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu
  OldCreateOrder = False
  ShowHint = True
  OnClose = FormClose
  OnCreate = FormCreate
  DesignSize = (
    693
    347)
  PixelsPerInch = 96
  TextHeight = 13
  object LabelImagePath: TLabel
    Left = 453
    Top = 3
    Width = 86
    Height = 13
    Anchors = [akTop, akRight]
    Caption = 'Executable name:'
    ExplicitLeft = 487
  end
  object ListViewExec: TListView
    Left = 0
    Top = 0
    Width = 444
    Height = 311
    Anchors = [akLeft, akTop, akRight, akBottom]
    Columns = <
      item
        Caption = 'Executable'
        MinWidth = 100
        Width = 150
      end
      item
        Caption = 'Action'
        MinWidth = 150
        Width = 265
      end>
    ColumnClick = False
    DoubleBuffered = True
    ReadOnly = True
    RowSelect = True
    ParentDoubleBuffered = False
    TabOrder = 0
    ViewStyle = vsReport
    OnChange = ListViewExecChange
  end
  object ButtonDelete: TButton
    Left = 88
    Top = 317
    Width = 75
    Height = 25
    Hint = 'Deletes the selected action'
    Anchors = [akLeft, akBottom]
    Caption = ' Delete'
    ElevationRequired = True
    Enabled = False
    TabOrder = 1
    OnClick = ButtonDeleteClick
  end
  object ButtonRefresh: TBitBtn
    Left = 6
    Top = 317
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
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
    TabOrder = 2
    OnClick = Refresh
  end
  object ButtonAdd: TButton
    Left = 372
    Top = 317
    Width = 75
    Height = 25
    Hint = 
      'Registers the specified action. Note that the change is system-w' +
      'ide.'
    Anchors = [akRight, akBottom]
    Caption = ' Add'
    ElevationRequired = True
    TabOrder = 3
    OnClick = ButtonAddClick
  end
  object GroupBoxActions: TGroupBox
    Left = 453
    Top = 49
    Width = 235
    Height = 293
    Anchors = [akTop, akRight]
    Caption = 'Actions '
    TabOrder = 4
    object LabelNote: TLabel
      Left = 6
      Top = 258
      Width = 142
      Height = 26
      Hint = 'A.exe /param  -->  B.exe A.exe /param'
      AutoSize = False
      Caption = 'Note: the last parameter will be the original filename.'
      WordWrap = True
    end
    object RadioButtonDrop: TRadioButton
      Tag = 1
      Left = 7
      Top = 42
      Width = 220
      Height = 17
      Hint = 
        'Drop administrative privileges of the process. Even if the token' +
        ' is still elevated administrators group membership is used for d' +
        'eny only.'
      Caption = 'Dro&p admin rights'
      TabOrder = 0
      OnClick = RadioButtonClick
    end
    object RadioButtonDisplayOn: TRadioButton
      Tag = 4
      Left = 7
      Top = 108
      Width = 220
      Height = 17
      Hint = 'Force the display to be on until the process exits'
      Caption = 'Force d&isplay on'
      TabOrder = 1
      OnClick = RadioButtonClick
    end
    object RadioButtonElevate: TRadioButton
      Tag = 2
      Left = 7
      Top = 65
      Width = 220
      Height = 17
      Hint = 'Elevates the process to run as Administrator'
      Caption = '&Elevate'
      TabOrder = 2
      OnClick = RadioButtonClick
    end
    object RadioButtonNoSleep: TRadioButton
      Tag = 3
      Left = 7
      Top = 86
      Width = 220
      Height = 17
      Hint = 'Force the computer not to sleep until the process exits'
      Caption = 'No sleep &until exit'
      TabOrder = 3
      OnClick = RadioButtonClick
    end
    object RadioButtonBlock: TRadioButton
      Tag = 5
      Left = 7
      Top = 130
      Width = 220
      Height = 17
      Hint = 'Block the process start and show a notification to the user'
      Caption = '&Deny and notify user'
      TabOrder = 4
      OnClick = RadioButtonClick
    end
    object RadioButtonAsk: TRadioButton
      Left = 7
      Top = 20
      Width = 220
      Height = 17
      Hint = 'Ask user before starting the program'
      Caption = '&Ask permission to start'
      Checked = True
      TabOrder = 5
      TabStop = True
      OnClick = RadioButtonClick
    end
    object RadioButtonExecute: TRadioButton
      Tag = 13
      Left = 7
      Top = 205
      Width = 220
      Height = 17
      Hint = 
        'The system will run the executable below instead of running the ' +
        'executable above'
      Caption = 'E&xecute another program instead:'
      TabOrder = 6
      OnClick = RadioButtonClick
    end
    object ButtonBrowseExec: TButton
      Left = 155
      Top = 259
      Width = 72
      Height = 25
      Caption = 'Browse'
      Enabled = False
      TabOrder = 7
      OnClick = ButtonBrowseExecClick
    end
    object ComboBoxErrorCodes: TComboBox
      Left = 6
      Top = 176
      Width = 221
      Height = 21
      Hint = 'Deny the execution and return the error code to the caller:'
      Style = csDropDownList
      ItemIndex = 2
      TabOrder = 8
      Text = '5 Access is denied'
      OnClick = ComboBoxErrorCodesClick
      Items.Strings = (
        '0 Success [not recommended]'
        '2 Cannot find the file specified'
        '5 Access is denied'
        '32 The file is being used by another process'
        '87 Cannot execute the specified program'
        '129 The file cannot be run in Win32 mode'
        '193 Not a valid Win32 application')
    end
    object RadioButtonError: TRadioButton
      Tag = 6
      Left = 7
      Top = 152
      Width = 220
      Height = 17
      Hint = 
        'Block the process from being started and return this error code ' +
        'to the caller'
      Caption = 'Deny and return e&rror code:'
      TabOrder = 9
      OnClick = RadioButtonClick
    end
    object EditExec: TEdit
      Left = 6
      Top = 230
      Width = 221
      Height = 21
      Hint = 
        'It is highly recommended to place the filename into quotes, espe' +
        'cially if it contains spaces.'
      Enabled = False
      TabOrder = 10
    end
  end
  object ButtonBrowse: TButton
    Left = 619
    Top = 18
    Width = 66
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Browse'
    TabOrder = 5
    OnClick = ButtonBrowseClick
  end
  object EditImage: TEdit
    Left = 453
    Top = 22
    Width = 161
    Height = 21
    Hint = 'The filename without a path'
    Anchors = [akTop, akRight]
    TabOrder = 6
  end
  object OpenDlg: TOpenDialog
    Filter = 'Executables (*.exe; *.com)|*.exe; *.com'
    Options = [ofReadOnly, ofEnableSizing]
    Left = 249
    Top = 168
  end
  object MainMenu: TMainMenu
    Images = ImageList
    Left = 194
    Top = 168
    object MenuFile: TMenuItem
      Caption = 'Menu'
      object MenuRunAsAdmin: TMenuItem
        Caption = 'Restart as &Administrator'
        OnClick = MenuRunAsAdminClick
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object MenuReg: TMenuItem
        Caption = 'Register shell context menu'
        OnClick = MenuRegClick
      end
      object MenuUnreg: TMenuItem
        Caption = 'Unregister shell context menu'
        OnClick = MenuUnregClick
      end
      object N2: TMenuItem
        Caption = '-'
      end
      object MenuSource: TMenuItem
        Caption = 'Source code on Github'
        OnClick = MenuSourceClick
      end
    end
  end
  object ImageList: TImageList
    ColorDepth = cd32Bit
    AllocBy = 1
    Left = 304
    Top = 168
  end
end
