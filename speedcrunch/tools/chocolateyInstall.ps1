Set-StrictMode -Version latest
$ErrorAction = "Stop"


$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$installerExe = Get-Item "$toolsDir/SpeedCrunch*.exe"
Get-ChocolateyUnzip -FileFullPath $installerExe.FullName -Destination $toolsDir


# Remove installer + installer internals that have just been extracted
# Note: Somehow Uninstall.exe doesn't get extracted when using Get-ChocolateyUnzip
# => try to delete anyway
Remove-Item $installerExe
Remove-Item "$toolsDir/Uninstall.exe" -ErrorAction SilentlyContinue
Remove-Item -Recurse "$toolsDir/`$PLUGINSDIR"


# Start menu
Install-StartMenuLink -LinkName "SpeedCrunch" -TargetPath "$toolsDir/speedcrunch.exe"