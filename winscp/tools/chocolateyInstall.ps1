Set-StrictMode -Version latest
$ErrorAction = "Stop"
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"


# Install start menu shortcut
$exe = Join-Path $toolsDir "WinSCP.exe"
Install-StartMenuLink -LinkName "WinSCP" -TargetPath $exe