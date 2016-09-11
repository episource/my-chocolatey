$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$nppDir   = Join-Path $toolsDir "../../notepadplusplus/tools" | Resolve-Path
$nppExe   = Join-Path $nppDir "notepad++.exe"

$myConfig = @{
    "SOFTWARE\Binary Fortress Software\FileSeek" = @{
        # Disable built-in auto update
        AutoUpdate              = "0"
        AutoUpdateBeta          = "0"
        
        # Use notepad++ as default viewer
        NameForOtherApplication = "Notepad++"
        OpenOther               = "$nppExe"
        OpenOtherArgs           = '-n$line$ "$file$"'
        SelectedStartupParam    = "3"
        
        # Search options
        ShowEmptyPDFErrors      = "1"
        
        # Result View Settings
        ShowCharCount           = "100"
    }
}
Install-UserProfileRegistryImage -Image $myConfig -Force