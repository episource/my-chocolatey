. $PSScriptRoot/chocolateyCommon.ps1

# Install start menu shortcut
Install-ChocolateyShortCut `
    -ShortcutFilePath $startLink -TargetPath $exe

# Add shim to path
Install-BinFile -Name "${appname}_x86" -Path $x86exe
Install-BinFile -Name "${appname}_x64" -Path $x64exe
Install-BinFile -Name "$appname"       -Path $exe