# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1

function _Resolve-Uri($pageUri, $linkUri) {
    return New-object -TypeName System.Uri -ArgumentList `
        @([System.Uri]$pageUri, $linkUri) | `
        Select-Object -ExpandProperty "AbsoluteUri"
}


# Parameters for parsing the download page
$downloadPageUrl = "https://notepad-plus-plus.org/download/"
$versionRegex    = '<title>Notepad\+\+ v(?<VERSION>\d(?:\.\d){0,2}) - Current Version</title>'
$zipPackageRegex = '>Notepad\+\+ zip package 32-bit x86<'
$hashFileRegex   = '>SHA-256/SHA-1/MD5 digests for binary packages<'


# Query download page
$htmlResponse    = Invoke-WebRequest -UseBasicParsing -Uri $downloadPageUrl

If (-not ($htmlResponse.Content -match $versionRegex)) {
    Write-Error "Failed to parse notepad++ download page - version not found"
    return
}
$versionParts = @($Matches.VERSION.Split(".") | %{ [Int]$_ })
While ($versionParts.length -lt 3) {
    $versionParts += 0
}
$version = [String]::Join(".", $versionParts)

$zipUrl = $null
$shaUrl = $null
ForEach ($link in $htmlResponse.Links) {
    $href = _Resolve-Uri $downloadPageUrl $link.href
    If ($link.outerHTML -match $zipPackageRegex) {
        $zipUrl = $href
    } ElseIf ($link.outerHTML -match $hashFileRegex) {
        $shaUrl = $href
    }
}
If (-not $zipUrl -or -not $shaUrl) {
    Write-Error "Failed to parse notepad++ download page - download link not found!"
    return
}


# Extract checksum
$sha = Get-ChecksumFromWeb -Url $shaurl -ChecksumType Sha256 `
    -Filename (Split-Path -Leaf $zipUrl) -ValueOnly


# Format version info
$versionInfo = @{
    Version  = $version
    FileUrl  = $zipUrl
    Checksum = "sha256:$sha"
}
Write-Verbose `
    "Notepad++ version info`n$($versionInfo | Format-List | Out-String)"


# Buid the package (subject to _config.ps1)
New-Package -VersionInfo $versionInfo 

