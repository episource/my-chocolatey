# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1

$fileUrl = "http://rammichael.com/downloads/7tt_setup.exe"
$infoUrl = "${fileUrl}?version&changelog=0.0"

$infoResponse        = Invoke-WebRequest -UseBasicParsing $infoUrl
$versionAndChangelog = $infoResponse.Content.Split("`0")

$versionParts        = $versionAndChangelog[0].Split(".")
While ($versionParts.length -lt 3) {
    $versionParts   += "0"
}
$version             = [String]::Join(".", $versionParts)

# Append a version dependend query string to prevent an old version to be
# fetched from the download cache.
# Note: ?vesion=... can't be used - the version query string always returns the
# current version string, no file would be downloaded.
New-Package -VersionInfo @{
    Version      = $version
    FileUrl      = "${fileUrl}?unique=$version"
    ReleaseNotes = $versionAndChangelog[1]
}