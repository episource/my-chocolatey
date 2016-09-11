# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


New-Package @{
    Version      = "1.0.0"
    FileUrl      = @()
    Checksum     = @()
    ReleaseNotes = @"
v1.0.0 - Initial version
"@
}