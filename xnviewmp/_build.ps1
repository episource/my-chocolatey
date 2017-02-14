# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


# Parameters for parsing the download page
$downloadPageUrl = "http://www.xnview.com/en/xnviewmp/"
$versionRegex    = 'Download.+XnView MP (?<VERSION>\d+(?:\.\d+){1,2})'
$hrefRegex       = '<a.*href="(?<HREF>[^"]+)".*>.*Zip Win 64bit.*</a>'

# Query download page
$htmlResponse    = Invoke-WebRequest -UseBasicParsing -Uri $downloadPageUrl

If (-not ($htmlResponse.Content -match $versionRegex)) {
    Write-Error "Failed to parse XnView MP download page - version not found"
    return
}
$versionParts = @($Matches.VERSION.Split(".") | %{ [Int]$_ })
While ($versionParts.length -lt 3) {
    $versionParts += 0
}
$version = [String]::Join(".", $versionParts)

If (-not ($htmlResponse.Content -match $hrefRegex)) {
    Write-Error "Failed to parse XnView MP download page - download link not found"
    return
}
# append version => unique url for proper caching
$href = $Matches.HREF + "?version=$version"

# Build the package
@{
    Version  = $version
    FileUrl  = $href
} | New-Package