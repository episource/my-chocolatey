Set-StrictMode -Version latest
$ErrorAction = "Stop"
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"


Install-StartMenuLink -LinkName "Wix Toolset" -TargetPath "$toolsDir"
Set-AutoShim -Pattern "tools/sdk/**" -Mode Ignore | Out-Null