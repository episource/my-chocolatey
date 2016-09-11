$myConfig = @{
    "SOFTWARE\HashCheck" = @{
        # Configuration of the HashCheck context menu entry
        # -> show HashCheck entry only in extend context menu (shift +
        #    right click). Possible options are:
        # => https://github.com/gurnec/HashCheck/blob/v2.4.0/CHashCheck.cpp#L111
        #      - No MenuDisplay value or MenuDisplay=0 : show HashCheck entry in
        #        normal and extended context menu
        #      - MenuDisplay=1 : show HashCheck entry in extended context menu
        #        only
        #      - MenuDisplay=2 : never show HashCheck entry in context menu
        MenuDisplay = 0x00000001
        
        # Selection of checksum algorithms
        # -> enable MD5 checksum calculation which is disabled by default. The
        #    resulting configuration is CRC32+MD5+SHA1+SHA256+SHA512.
        #    Possible bit flags are:
        # => https://github.com/gurnec/HashCheck/blob/v2.4.0/libs/WinHash.h#L64-L89
        #      - CRC32    : 0x01
        #      - MD5      : 0x02
        #      - SHA1     : 0x04
        #      - SHA256   : 0x08
        #      - SHA512   : 0x10
        #      - SHA3_256 : 0x20
        #      - SHA3_512 : 0x40
        # -> The default value used if the registry value does not exist is 0x1d
        Checksums   = 0x0000001f
    }
}
Install-UserProfileRegistryImage -Image $myConfig -Force