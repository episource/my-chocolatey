# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../../_root.ps1

# Format version info
$versionInfo = @{
    Version      = "1.0.0"
    FileUrl      = @()
    Checksum     = @()
}

New-Package -VersionInfo $versionInfo

