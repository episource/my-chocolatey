. $PSScriptRoot/chocolateyCommon.ps1

# Uninstall start menu shortcut
If (Test-Path -Path $startLink) {
    Remove-item -Path $startLink
}

# Uninstall context menu entry
If (Test-Path -LiteralPath $menuKey) {
    Remove-Item -Force -Recurse -LiteralPath $menuKey
}