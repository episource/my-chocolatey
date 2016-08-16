. $PSScriptRoot/chocolateyCommon.ps1

# Uninstall start menu shortcut
If (Test-Path -Path $startLink) {
    Remove-item -Path $startLink
}