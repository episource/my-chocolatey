Set-StrictMode -Version latest
$ErrorAction = "Stop"
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"


$installerExe = Get-Item "$toolsDir/*-installer1?.exe"
Get-ChocolateyUnzip -FileFullPath $installerExe.FullName -Destination $toolsDir
Remove-Item $installerExe
Remove-Item "$toolsDir/uninstall.exe"
Remove-Item -Recurse "$toolsDir/`$PLUGINSDIR"

$exePath = "$toolsDir/bin/FreeCAD.exe"
Install-StartMenuLink -LinkName "FreeCAD" -TargetPath $exePath
Set-AutoShim -Pattern $exePath -Invert -Mode Ignore | Out-Null