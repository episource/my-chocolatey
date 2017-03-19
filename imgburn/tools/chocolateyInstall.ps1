Set-StrictMode -Version latest
$ErrorAction = "Stop"

$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"


Set-AutoShim -Pattern "ImgBurn.exe" -Invert -Mode Ignore | Out-Null
Install-StartMenuLink -LinkName "ImgBurn" -TargetPath "$toolsDir\ImgBurn.exe"
