Set-StrictMode -Version latest
$ErrorAction = "Stop"

$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"


$withShim = @( "cdbxpcmd.exe", "cdbxpp.exe" )
Set-AutoShim -Pattern $withShim -Invert -Mode Ignore | Out-Null
Install-StartMenuLink -LinkName "CDBurnerXP" -TargetPath "$toolsDir/cdbxpp.exe"


# store settings per use / not in the application folder
Set-Content -Path "$toolsDir/Config.ini" -Value @"
[CDBurnerXP]
Portable=0
"@