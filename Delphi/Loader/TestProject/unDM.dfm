object DM: TDM
  OldCreateOrder = False
  Height = 229
  Width = 434
  object fdCon: TADConnection
    Params.Strings = (
      'Database=Z:\updates\Delphi\PatchPacker\updates.db'
      'StringFormat=Unicode'
      'DriverID=SQLite')
    FormatOptions.AssignedValues = [fvStrsTrim]
    FormatOptions.StrsTrim = False
    Left = 40
    Top = 48
  end
  object FDGUIxWaitCursor: TFDGUIxWaitCursor
    Provider = 'Forms'
    Left = 128
    Top = 48
  end
end
