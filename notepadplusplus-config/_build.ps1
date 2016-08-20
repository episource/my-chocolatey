# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1

# Format version info
$versionInfo = @{
    Version      = "1.1.0"
    FileUrl      = @()
    Checksum     = @()
    ReleaseNotes = @"
v1.1.0 : Change shortcuts
    - SCI_SELECTIONDUPLICATE: Ctrl+Shift+D (custom - default was Ctrl+D)
    - SCI_LINEDELETE: Ctrl+D (custom), Ctrl+Shift+L (default)
v1.0.0 : Initial version
"@
}

New-Package -VersionInfo $versionInfo

