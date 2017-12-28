Set-StrictMode -Version latest
$ErrorAction = "Stop"

$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$x64dbgDir = Join-Path $toolsDir "../../x64dbg/tools"


Remove-Item "$x64dbgDir/release/x64/plugins/OllyDumpEx_X64Dbg.dp64"
Remove-Item "$x64dbgDir/release/x32/plugins/OllyDumpEx_X64Dbg.dp32"