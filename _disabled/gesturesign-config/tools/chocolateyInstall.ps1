. $PSScriptRoot/chocolateyCommon.ps1

Set-Location $gestureSignDir
Rename-Item "Defaults" "Defaults.old" | Out-Null

Copy-Item -Recurse "$toolsDir/Defaults" "Defaults" | Out-Null