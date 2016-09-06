# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


$downloadIndexUrl = "https://download.tortoisegit.org/tgit/"
$notesBaseUrl     = 
$versionUrlRegex  = "^(?<VERSION>(\d+\.){2,3}\d+)/?$"
$htmlResponse     = Invoke-WebRequest -UseBasicParsing -Uri $downloadIndexUrl


$version = $htmlResponse.Links | %{
        If ($_.href -match "^(?<VERSION>(\d+\.){2,3}\d+)/?$") {
            write-output $Matches.VERSION 
        } 
    } | Sort-Object -Property @{ Expression = { [Version]$_ } } -Descending |
    Select-Object -First 1


$fileUrl   = "$downloadIndexUrl/$version/TortoiseGit-$version-64bit.msi"
$notesUrl  = "https://tortoisegit.org/docs/releasenotes/#Release_$version"

$notesHtml = Invoke-WebRequest -UseBasicParsing -Uri $notesUrl
$notesHtml -match `
    "(?is)<pre[^>]*>\s*(?<RELEASENOTES><strong\s*id=""?Release.+)</pre>" | Out-Null
$notes     = $Matches.RELEASENOTES -replace `
    '<[^>]+>(?<INNERHTML>[^<]+)</[^>]+>','${INNERHTML}'
    
    
New-Package -VersionInfo @{
    Version      = $version
    FileUrl      = $fileUrl
    Checksum     = $null
    ReleaseNotes = $notes
}
