. $PSScriptRoot/chocolateyCommon.ps1

# Install start menu shortcut
Install-ChocolateyShortCut `
    -ShortcutFilePath $startLink -TargetPath $exe