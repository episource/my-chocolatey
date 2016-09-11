. $PSScriptRoot/chocolateyCommon.ps1

# Uninstall context menu entry
If (Test-Path -LiteralPath $menuKey) {
    Remove-Item -Force -Recurse -LiteralPath $menuKey
}