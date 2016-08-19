# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


# Configuration
$zipFile    = "x86/putty.zip"
$sha256File = "sha256sums"


# Query latest version
$latestUrl      = "https://the.earth.li/~sgtatham/putty/latest/"
$latestResponse = Invoke-WebRequest -UseBasicParsing -MaximumRedirection 0 `
    -ErrorAction Ignore -Uri $latestUrl
$latestUrl      = $latestResponse.Headers.Location

$version = Split-Path -Leaf $latestUrl
While ($version.Split('.').length -lt 3) {
    $version += '.0'
}


# Get putty.zip url
$zipUrl = $latestUrl + $zipFile


# Get checksum
$sha256Url = $latestUrl + $sha256File
$sha256    =  Get-ChecksumFromWeb -Url $sha256Url -Filename $zipFile -ValueOnly


# Format version info
$versionInfo = @{
    Version  = $version
    FileUrl  = $zipUrl
    Checksum = "sha256:$sha256"
}
Write-Verbose `
    "Putty version info`n$($versionInfo | Format-List | Out-String)"
    
# Buid the package (subject to _config.ps1)
New-Package -VersionInfo $versionInfo -TemplateDir $PSScriptRoot