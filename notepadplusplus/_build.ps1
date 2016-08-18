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
$versionRegex    = '<title>Notepad\+\+ v(?<VERSION>\d\.\d\.\d) - Current Version</title>'
$zipPackageRegex = '>Notepad\+\+ zip package<'
$hashFileRegex   = '>SHA-1 digests for binary packages<'


# Query download page
$htmlResponse    = Invoke-WebRequest -UseBasicParsing -Uri $downloadPageUrl

If (-not ($htmlResponse.Content -match $versionRegex)) {
    Write-Error "Failed to parse notepad++ download page - version not found"
    return
}
$version = $Matches.VERSION

$zipUrl  = $null
$sha1Url = $null
ForEach ($link in $htmlResponse.Links) {
    $href = _Resolve-Uri $downloadPageUrl $link.href
    If ($link.outerHTML -match $zipPackageRegex) {
        $zipUrl = $href
    } ElseIf ($link.outerHTML -match $hashFileRegex) {
        $sha1Url = $href
    }
}
If (-not $zipUrl -or -not $sha1Url) {
    Write-Error "Failed to parse notepad++ download page - download link not found!"
    return
}


# Extract checksum
$sha1 = Get-ChecksumFromWeb -Url $sha1url -Filename (Split-Path -Leaf $zipUrl)


# Format version info
$versionInfo = @{
    Version = $version
    Url     = $zipUrl
    UrlHash = "sha1:$sha1"
}
Write-Verbose `
    "Notepad++ version info`n$($versionInfo | Format-List | Out-String)"


# Buid the package (subject to _config.ps1)
New-Package -VersionInfo $versionInfo -TemplateDir $PSScriptRoot

