# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


$dlIndexUrl = "http://speedcrunch.org/download.html"
$dlIndexRaw = Invoke-WebRequest -UseBasicParsing $dlIndexUrl

# don't use the portable build - prefer the installer: the config file location
# is hardcoded at build-time (see settings.cpp) - only the installer build
# uses AppData. Lateron 7zip is used to extract the installer's content.
$dlIndexRaw -match "(?<FILEURL>https://bitbucket.org/heldercorreia/speedcrunch/downloads/SpeedCrunch-(?<VERSION>(?:\d+\.){1,3}\d+)-win32.exe)" | Out-Null
$zipUrl = $Matches.FILEURL

# expand version
$versionParts = $Matches.VERSION.Split('.')
While ($versionParts.length -lt 3) {
    $versionParts += 0
}
$version = [String]::Join(".", $versionParts)


New-Package -VersionInfo @{
    Version = $version
    FileUrl = $zipUrl
}
