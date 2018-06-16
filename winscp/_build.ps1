# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


# Parameters for parsing the download page
$baseUrl         = "https://winscp.net"
$downloadPageUrl = $baseUrl + "/eng/downloads.php"
$zipRegex        = 'href="(?<URL>/download/WinSCP-(?<VERSION>\d+(?:\.\d+){0,2})-Portable.zip)"'


# Query download page
$htmlResponse    = Invoke-WebRequest -UseBasicParsing -Uri $downloadPageUrl
If (-not ($htmlResponse.Content -match $zipRegex)) {
    Write-Error "Failed to parse winscp download page - version not found"
    return
}

$rawVersion = $Matches.VERSION
$versionParts = @($rawVersion.Split(".") | %{ [Int]$_ })
While ($versionParts.length -lt 3) {
    $versionParts += 0
}
$version = [String]::Join(".", $versionParts)
$downloadDetailsUrl = $baseUrl + $Matches.URL


# Extract Checksum from Readme
$htmlResponse  = Invoke-WebRequest -UseBasicParsing -Uri $downloadDetailsUrl
$checksumRegex = "(?s)<h2>Checksums</h2>.*?SHA-256: (?<SHA256>[0-9a-fA-F]{64})"
$urlRegex      = 'href="(?<URL>https://winscp.net/download/files/[0-9a-zA-z]+/WinSCP-' + ${rawVersion} + '-Portable.zip)"'

If (-not ($htmlResponse.Content -match $checksumRegex)) {
    Write-Error "Failed to parse winscp download page - checksum not found"
    return
}
$sha256 = $Matches["SHA256"]

If (-not ($htmlResponse.Content -match $urlRegex)) {
    Write-Error "Failed to parse winscp download page - url not found"
    return
}
$zipUrl = $Matches["URL"]



# Format version info and build the package
$versionInfo = @{
    Version  = "$version"
    FileUrl  = "$zipUrl"
    Checksum = "sha256:$sha256"
}
New-Package -VersionInfo $versionInfo