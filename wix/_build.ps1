# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


$rootUrl = "http://wixtoolset.org"
$dlMainIndexUrl = "$rootUrl/releases/"
$dlMainIndex = Invoke-WebRequest -UseBasicParsing $dlMainIndexUrl
$dlMainIndex -match "(?s)<h2>Archived Builds</h2>.*<ul>.*?<a href=""(?<INDEX_URL>[^""]+)""" | Out-Null

$dlIndexUrl = "$rootUrl$($Matches.INDEX_URL)"
$dlIndex = Invoke-WebRequest -UseBasicParsing $dlIndexUrl

$dlIndex -match "<title>(?<VERSION>.*)</title>" | Out-Null
$version = $Matches.VERSION.TrimStart("v")
$dlIndex -match "href=""(?<FILE_URL>.*-binaries.zip)""" | Out-Null
$fileUrl = "$rootUrl$($Matches.FILE_URL)"

New-Package -VersionInfo @{
    Version = $version
    FileUrl = $fileUrl
}
