Set-StrictMode -Version latest
$ErrorAction = "Stop"
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"


$installerExe = Get-Item "$toolsDir/Wireshark-latest-x64.exe"
Get-ChocolateyUnzip -FileFullPath $installerExe.FullName -Destination $toolsDir
Remove-Item $installerExe
Remove-Item "$toolsDir/uninstall.exe"
Remove-Item -Recurse "$toolsDir/`$PLUGINSDIR"

$withShim = @( 
    "Wireshark.exe", "capinfos.exe", "dumpcap.exe", "editcap.exe",
    "mergecap.exe", "rawshark.exe", "reordercap.exe", "text2pcap.exe",
    "tshark.exe" 
)
Set-AutoShim -Pattern $withShim -Invert -Mode Ignore | Out-Null
Install-StartMenuLink -LinkName "Wireshark" -TargetPath "$toolsDir\Wireshark.exe"