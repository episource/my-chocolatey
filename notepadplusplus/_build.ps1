# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


# Parameters for parsing the download page
$githubRepo      = "notepad-plus-plus/notepad-plus-plus"
$downloadPrefix  = "http://download.notepad-plus-plus.org/repository"

# Note: Scraping new notepad-plus-plus.org site is blocked by cloudflare
$githubRelease   = Invoke-GithubApi `
        -ApiEndpoint "/repos/$githubRepo/releases/latest" `
        -ApiToken $global:CFGithubToken
$tagVersion      = $githubRelease.tag_name -replace "^v"
$fullVersion     = $tagVersion
while ($fullVersion.Split('.').length -lt 3) {
    $fullVersion += '.0'
}
$majorVersion = $fullVersion.Split('.')[0]

# Build download urls
$zipUrl = "$downloadPrefix/$majorVersion.x/$tagVersion/npp.$tagVersion.bin.x64.zip"
$shaUrl = "$downloadPrefix/$majorVersion.x/$tagVersion/npp.$tagVersion.checksums.sha256.txt"

# Extract checksum
$sha = Get-ChecksumFromWeb -Url $shaurl -ChecksumType Sha256 `
    -Filename (Split-Path -Leaf $zipUrl) -ValueOnly


# Format version info
$versionInfo = @{
    Version  = $fullVersion
    FileUrl  = $zipUrl
    Checksum = "sha256:$sha"
}
Write-Verbose `
    "Notepad++ version info`n$($versionInfo | Format-List | Out-String)"


# Buid the package (subject to _config.ps1)
New-Package -VersionInfo $versionInfo 

