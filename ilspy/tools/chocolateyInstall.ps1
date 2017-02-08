Set-StrictMode -Version latest
$ErrorAction = "Stop"


$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$exe      = Join-Path $toolsDir "ILSpy.exe"
Install-StartMenuLink -LinkName "ILSpy" -TargetPath $exe