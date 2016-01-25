object dmUpd: TdmUpd
  OldCreateOrder = False
  Height = 229
  Width = 303
  object lbCryptographicLibrary: TCryptographicLibrary
    Left = 138
    Top = 33
  end
  object lbHash: THash
    CryptoLibrary = lbCryptographicLibrary
    Left = 138
    Top = 113
    HashId = 'native.hash.MD5'
  end
  object lbSignatory: TSignatory
    Codec = lbCodec
    Left = 38
    Top = 113
  end
  object lbCodec: TCodec
    AsymetricKeySizeInBits = 1024
    AdvancedOptions2 = []
    CryptoLibrary = lbCryptographicLibrary
    Left = 38
    Top = 33
    StreamCipherId = 'native.RSA'
    BlockCipherId = ''
    ChainId = 'native.CBC'
  end
end
