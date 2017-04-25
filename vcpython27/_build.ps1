# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


$dlIndexUrl = "http://aka.ms/vcpython27"
$dlIndexRaw = Invoke-WebRequest -UseBasicParsing $dlIndexUrl

$dlIndexRaw -match "Version:[^\d]*?(?<VERSION>(?:\d+\.){2,3}\d+)" | Out-Null
$version = $Matches.VERSION
$dlIndexRaw -match "confirmation.aspx\?id=(?<ID>\d+)" | Out-Null
$dlId = $Matches.ID

$dlStartUrl = "https://www.microsoft.com/en-us/download/confirmation.aspx?id=$dlId"
$dlStartRaw = Invoke-WebRequest -UseBasicParsing $dlStartUrl
$dlStartRaw -match "meta http-equiv=""refresh"" content=""0;url=(?<FILEURL>.+\.msi)" | Out-Null

New-Package -VersionInfo @{
    Version = $version
    FileUrl = $Matches.FileUrl
}