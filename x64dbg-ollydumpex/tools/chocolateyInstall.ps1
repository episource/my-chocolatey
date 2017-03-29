Set-StrictMode -Version latest
$ErrorAction = "Stop"

$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$x64dbgDir = Join-Path $toolsDir "../../x64dbg/tools"


New-Item -Type Directory "$x64dbgDir/release/x64/plugins" -ErrorAction SilentlyContinue
Copy-Item "$toolsDir/*/OllyDumpEx_X64Dbg.dp64" "$x64dbgDir/release/x64/plugins" -Force

New-Item -Type Directory "$x64dbgDir/release/x32/plugins" -ErrorAction SilentlyContinue
Copy-Item "$toolsDir/*/OllyDumpEx_X64Dbg.dp32" "$x64dbgDir/release/x32/plugins" -Force