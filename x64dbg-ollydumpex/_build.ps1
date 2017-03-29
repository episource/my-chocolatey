# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1

$dlIndexRaw = Invoke-WebRequest -UseBasicParsing "http://low-priority.appspot.com/ollydumpex/"

$dlIndexRaw -match "(?si)<a href=""OllyDumpEx\.zip"">OllyDumpEx.zip</a>.*?Version: v(?<VERSION>(?:\d+\.){1,3}\d+).*?MD5.*?(?<MD5>[0-9a-fA-F]{32})" | Out-Null
$checksum = "md5:$($Matches.MD5)"
$versionParts = $Matches.VERSION.Split(".")
While ($versionParts.Length -lt 3) {
    $versionParts += "0"
}
$version = [String]::Join(".", $versionParts)

$dlIndexRaw -match "(?si)<div id=""changes"">.*?<h2>.*?</h2>(?<CHANGES>.*?)</div>" | Out-Null
$changes = $Matches.Changes `
    -replace '.*<b>- (.*?)</b>','= ${1} =' `
    -replace ".*<ul>`r?`n" `
    -replace ".*<br>`r?`n" `
    -replace ".*</ul>" `
    -replace '.*<li>(.*?)</li>',' * ${1}'

New-Package -VersionInfo @{
    Version = $version
    FileUrl = "http://low-priority.appspot.com/ollydumpex/OllyDumpEx.zip"
    Checksum = $checksum
    ReleaseNotes = $changes
}