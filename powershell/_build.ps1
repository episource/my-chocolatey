# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


New-Package @{
    Version      = "5.0.10586.494"
    FileUrl      = @()
    Checksum     = @()
    ReleaseNotes = @"
v5.0.10586.494 - Initial package version based on powershell for windows 10
"@
}