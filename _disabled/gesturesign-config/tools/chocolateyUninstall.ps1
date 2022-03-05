. $PSScriptRoot/chocolateyCommon.ps1

Set-Location $gestureSignDir
If (Test-Path -Type Container "Defaults.old") {
    Remove-Item -Recurse "Defaults" | Out-Null
    Rename-Item "Defaults.old" "Defaults" | Out-Null
}
