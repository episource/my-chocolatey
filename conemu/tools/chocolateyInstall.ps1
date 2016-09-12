$toolsDir  = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"


# Extract conEmu
$conemuZip = Get-Item "$toolsDir/ConEmuPack*.7z"
Get-ChocolateyUnzip -FileFullPath $conemuZip.FullName -Destination $toolsDir
Remove-Item $conemuZip


# Create a shim for ConEmu64.exe only
# Create a startmenu entry
$exe64 = "$toolsDir/ConEmu64.exe"
Set-AutoShim -Pattern $exe64 -Invert -Mode Ignore | Out-Null
Install-StartMenuLink -LinkName "ConEmu" -TargetPath $exe64