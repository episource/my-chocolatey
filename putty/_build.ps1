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


# Get putty.zip url + checksum
$zipUrl = $latestUrl + $zipFile

$sha256Url      = $latestUrl + $sha256File
$sha256Regex    = "(?m)^(?<CHECKSUM>[a-zA-Z0-9]+)\s+" + `
    [Regex]::Escape($zipFile)
$sha256Response = Invoke-WebRequest -UseBasicParsing -Uri $sha256Url

# The content property gives only a byte[] due to missing ContentType
# => ToString() gives the expected plain text result
If (-not ($sha256Response.ToString() -match $sha256Regex)) {
    Write-Error "Failed to retrieve putty.zip checksum!"
}

$sha256 = $Matches.CHECKSUM


# Format version info
$versionInfo = @{
    Version = $version
    Url     = $zipUrl
    UrlHash = "sha256:$sha256"
}
Write-Verbose `
    "Putty version info`n$($versionInfo | Format-List | Out-String)"
    
# Buid the package (subject to _config.ps1)
New-Package -VersionInfo $versionInfo -TemplateDir $PSScriptRoot