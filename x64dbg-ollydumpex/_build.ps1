# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1

$dlIndexRaw = Invoke-WebRequest -UseBasicParsing "http://low-priority.appspot.com/ollydumpex/"

$dlIndexRaw -match "(?si)<a href=""OllyDumpEx_v(?<VERSION>(?:\d+\.){1,3}\d+)\.zip"">v\<VERSION></a>" | Out-Null
$versionRaw = $Matches.VERSION
$versionParts = $versionRaw.Split(".")
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
    FileUrl = "https://github.com/lowpriority/release_archive/blob/master/ollydumpex/OllyDumpEx_v$versionRaw.zip?raw=true"
    ReleaseNotes = $changes
}