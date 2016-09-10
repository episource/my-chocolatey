# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../../_root.ps1

# Format version info
$versionInfo = @{
    Version      = "1.1.1"
    FileUrl      = @()
    Checksum     = @()
    ReleaseNotes = @"
v1.1.1 - All links used to be created with "Run as admin" enabled. This has
         been fixed.
v1.1.0 - Add auto-uninstall feature
v1.0.0 - Initial version
"@
}

New-Package -VersionInfo $versionInfo

