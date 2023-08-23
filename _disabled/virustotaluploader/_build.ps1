# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


$dlIndexUrl = "https://www.virustotal.com/de/documentation/desktop-applications/virustotal-uploader"
$dlIndexRaw = Invoke-WebRequest -UseBasicParsing $dlIndexUrl
$dlIndexRaw -match "/static/bin/(?<FNAME>vtuploader(?<VERSION>(?:\d+\.){1,3}\d+)\.exe)" | Out-Null

$fileUrl = "https://www.virustotal.com/static/bin/$($Matches.FNAME)"

$versionParts = $Matches.VERSION.Split(".")
while ($versionParts.Length -lt 3) {
    $versionParts += "0"
}
$version = [String]::Join(".", $versionParts)

New-Package -VersionInfo @{
    Version = $version
    FileUrl = $fileUrl
}