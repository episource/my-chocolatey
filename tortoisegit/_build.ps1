# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


# Find download url + version
$downloadPageUrl     = "https://tortoisegit.org/download/"
$downloadPageContent = Invoke-WebRequest -UseBasicParsing -Uri $downloadPageUrl

$msiUrl = $DownloadPageContent.Links | ?{
    $_.href -match "TortoiseGit-(?<VERSION>(?:\d+\.){2,3}\d+)-64bit\.msi$" 
} | %{ $_.href -replace "^//","http://" } | Select-Object -First 1
$version = $Matches.VERSION


# Prepare release notes
$releaseNotesUrl     = "https://tortoisegit.org/docs/releasenotes/"
$releaseNotesContent = Invoke-WebRequest -UseBasicParsing -Uri $releaseNotesUrl
$releaseNotesContent -match `
    "(?is)<pre[^>]*class=releasenotes>\s*(?<RELEASENOTES>.+)</pre>" | Out-Null
$releaseNotes = $Matches.RELEASENOTES -replace '<[^>]+?/?>',''
    
    
New-Package -VersionInfo @{
    Version      = $version
    FileUrl      = $msiUrl
    Checksum     = $null
    ReleaseNotes = $releaseNotes
}
