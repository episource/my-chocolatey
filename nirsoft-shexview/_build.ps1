# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


New-Package -VersionInfo @{
    Version = "file:tools/shexview.exe"
    FileUrl = "http://www.nirsoft.net/utils/shexview-x64.zip"
}