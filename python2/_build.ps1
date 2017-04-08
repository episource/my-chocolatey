# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


$dlIndexUrl = "https://www.python.org/downloads/windows/"
$dlIndex = Invoke-WebRequest -UseBasicParsing $dlIndexUrl
$dlIndex -match "Latest Python 2 release - Python (?<VERSION>(?:\d+\.){2,3}\d+)" | Out-Null
$version = $Matches.VERSION

New-Package -VersionInfo @{
    Version =  $version
    FileUrl = "https://www.python.org/ftp/python/$version/python-$version.amd64.msi"
}