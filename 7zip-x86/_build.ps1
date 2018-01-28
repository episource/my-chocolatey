# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


$versionInfo = Get-VersionInfoFromSourceforge `
    -Project "sevenzip" `
    -Filter  "/7-Zip/(?<VERSION>\d+\.\d+)/7z\d+\.msi"
$versionInfo.ReleaseNotes = Invoke-WebRequest -UseBasicParsing `
    -Uri     "http://7-zip.org/history.txt"

#Normalize version string to be semver compatible
$versionParts = $versionInfo.Version.Split(".") | %{ [Int]$_ }
While ($versionParts.length -lt 3) {
    $versionParts += 0
}
$versionInfo.Version = [String]::Join(".", $versionParts)
   
   
New-Package -VersionInfo $versionInfo