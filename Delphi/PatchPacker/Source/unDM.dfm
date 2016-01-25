object DM: TDM
  OldCreateOrder = False
  Height = 288
  Width = 406
  object fdCon: TADConnection
    Params.Strings = (
      'Database=Z:\updates\Delphi\PatchPacker\updates.db'
      'StringFormat=Unicode'
      'DriverID=SQLite')
    FormatOptions.AssignedValues = [fvStrsTrim]
    FormatOptions.StrsTrim = False
    Left = 72
    Top = 88
  end
  object FDGUIxWaitCursor: TADGUIxWaitCursor
    Provider = 'Forms'
    Left = 184
    Top = 88
  end
  object ADPhysSQLiteDriverLink: TADPhysSQLiteDriverLink
    Left = 184
    Top = 176
  end
end
