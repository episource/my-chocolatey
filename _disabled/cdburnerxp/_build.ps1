# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1

# Determine latest version + file url
$dlIndexUrl = "https://cdburnerxp.se/en/download"
$dlIndexRaw = Invoke-WebRequest -UseBasicParsing $dlIndexUrl
$dlIndexRaw -match "(?<ZIPURL>https://download.cdburnerxp.se/portable/CDBurnerXP-x64-(?<VERSION>(?:\d+\.){2,3}\d+).zip)" | Out-Null
$zipUrl = $Matches.ZIPURL
$version = $Matches.VERSION

# Extract changelog
$changelogUrl = "https://cdburnerxp.se/en/development?full"
$changelogRaw = Invoke-WebRequest -UseBasicParsing $changelogUrl
$changelogRaw -match "(?si)(?<CHANGES><b>Version $version.*)<h1>Development log</h1>" | Out-Null
$changes = $Matches.CHANGES `
    -replace '(?si)<b>(Version[^<]*)</b>[^<]*<ul class="vers">','= ${1} =' `
    -replace '[ \x09]*<li><div>(.)</div>','  ${1}' `
    -replace '<a[^>]*>([^<]*)</a>','${1}' `
    -replace '</li>','' `
    -replace '</?ul[^>]*>',''
    
New-Package -VersionInfo @{
    Version = $version
    FileUrl = $zipUrl
    ReleaseNotes = $changes
}