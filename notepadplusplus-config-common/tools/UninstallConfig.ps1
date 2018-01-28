[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [String] $nppPackageDir
)
. $PSScriptRoot/Common.ps1


# Restore backup
If (Test-Path -Path $configModelBackup) {
    Move-item $configModelBackup $configModel -Force
}
If (Test-Path -Path $stylersModelBackup) {
    Move-item $stylersModelBackup $stylersModel -Force
}
If (Test-Path -Path $shortcutsBackup) {
    Move-item $shortcutsBackup $shortcuts -Force
}