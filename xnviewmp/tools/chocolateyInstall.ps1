Set-StrictMode -Version latest
$ErrorAction = "Stop"


$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$exe      = Join-Path $toolsDir "XnViewMP\xnviewmp.exe"
Set-AutoShim -Pattern $exe -Invert -Mode Ignore | Out-Null
Install-StartMenuLink -LinkName "XnView MP" -TargetPath $exe