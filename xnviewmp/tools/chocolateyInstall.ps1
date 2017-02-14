Set-StrictMode -Version latest
$ErrorAction = "Stop"


$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$exe      = Join-Path $toolsDir "XnViewMP\xnviewmp.exe"
Install-StartMenuLink -LinkName "XnView MP" -TargetPath $exe