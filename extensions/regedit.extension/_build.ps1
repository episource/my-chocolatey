# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../../_root.ps1

# Format version info
$versionInfo = @{
    Version      = "1.2.0"
    FileUrl      = @()
    Checksum     = @()
    ReleaseNotes = @"
v1.2.0   - Format powershell byte arrays using hex notation
v1.1.1   - Stop Export-Registry to write 'true' to the pipeline as first item
v1.1.0   - Export Edit-AllLocalUserProfileHives cmdlet
v1.0.0.1 - Important bug fixes - no functional changes
v1.0.0   - Initial version
"@
}

New-Package -VersionInfo $versionInfo
