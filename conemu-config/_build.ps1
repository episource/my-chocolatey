# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


New-Package @{
    Version      = "2.0.0"
    FileUrl      = @()
    Checksum     = @()
    ReleaseNotes = @"
v2.0.0 - Move ANSI logs to user profile folder (adopting ConEmu 160914's 
         default)
v1.0.0 - Initial version
"@
}