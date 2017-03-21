Set-StrictMode -Version latest
$ErrorAction = "Stop"


$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
Install-StartMenuLink -LinkName "NirSoft\ShellExView" -TargetPath "$toolsDir/shexview.exe"