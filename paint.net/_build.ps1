# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


$dlIndexUrl = "http://www.getpaint.net/updates/versions.8.1000.0.x64.en.txt"
$dlIndexRaw = Invoke-WebRequest -UseBasicParsing $dlIndexUrl
$dlIndexRaw -match "FullZipUrlList=(?<FILEURL>http://www.getpaint.net/updates/zip/paint.net.(?<VERSION>(?:\d+\.){2,3}\d+).install.zip)," | Out-Null

New-Package -VersionInfo @{
    Version = $Matches.VERSION
    FileUrl = $Matches.FILEURL
}