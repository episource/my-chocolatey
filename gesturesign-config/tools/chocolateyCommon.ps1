Set-StrictMode -Version latest
$ErrorActionPreference = "Stop"

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$gestureSignDir  = Join-Path $toolsDir "../../gesturesign/tools"