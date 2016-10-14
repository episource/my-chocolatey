# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../../_root.ps1

# Format version info
$versionInfo = @{
    Version      = "3.0.2-SNAPSHOT"
    FileUrl      = @()
    Checksum     = @()
    ReleaseNotes = @"
v3.0.2   - Fix New-RegistryKey to use the literal path instead of expanding
           globs
         - Fix uninstall cmdlets to use the literal key path instead of
           expanding globs
v3.0.1   - Make cmdlet Edit-AllLocalUserProfileHives usable outside the regedit
           module: Until now the variable `$hkuPath has not been accessible
           outside module scope
v3.0.0   - Fix exporting of (Default) registry entries
         - Fix filtering registry entries to be exported
         - Add support for filtering registry entries using powershell regular
           expressions
         - Handle non-existing paths gracefully
v2.1.0   - Add a cmdlet for merging registry images
v2.0.0   - Read registry image from pipeline
         - Make Test-RegistryPathValidity accept PSDrives again
v1.2.0   - Format powershell byte arrays using hex notation
v1.1.1   - Stop Export-Registry to write 'true' to the pipeline as first item
v1.1.0   - Export Edit-AllLocalUserProfileHives cmdlet
v1.0.0.1 - Important bug fixes - no functional changes
v1.0.0   - Initial version
"@
}

New-Package -VersionInfo $versionInfo
