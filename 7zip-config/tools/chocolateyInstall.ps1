$myConfig = @{
    "SOFTWARE\7-Zip\Options" = @{
        # Configuration of the 7-Zip Context Menu:
        # => HKEY_CURRENT_USER\SOFTWARE\7-Zip\Options\ContextMenu
        # - Default value is 80003f77
        # - Default value is used if registry entry is missing
        # - MSI installer does not create registry entry - it is created when
        #   settings are changed first via the settings GUI
        # - Supported flags from source (7-zip/CPP/7zip/UI/Explorer/
        #   ContextMenuFlags.h):
        #     namespace NContextMenuFlags
        #     {
        #       const UInt32 kExtract = 1 << 0;
        #       const UInt32 kExtractHere = 1 << 1;
        #       const UInt32 kExtractTo = 1 << 2;
        #     
        #       const UInt32 kTest = 1 << 4;
        #       const UInt32 kOpen = 1 << 5;
        #       const UInt32 kOpenAs = 1 << 6;
        #     
        #       const UInt32 kCompress = 1 << 8;
        #       const UInt32 kCompressTo7z = 1 << 9;
        #       const UInt32 kCompressEmail = 1 << 10;
        #       const UInt32 kCompressTo7zEmail = 1 << 11;
        #       const UInt32 kCompressToZip = 1 << 12;
        #       const UInt32 kCompressToZipEmail = 1 << 13;
        #     
        #       const UInt32 kCRC = (UInt32)1 << 31;
        #     }
        # - My custom default: Enable all but kCRC => don't show "CRC SHA"
        #   context menu entry
        ContextMenu = 0x00003f77
    }
}
Install-UserProfileRegistryImage -Image $myConfig -Force