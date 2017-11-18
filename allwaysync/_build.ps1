# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


# Query download page
$downloadPageUrl = "https://allwaysync.com/download/"
$response = Invoke-WebRequest -UseBasicParsing -Uri $downloadPageUrl
$href = $response.links | ?{ $_ -match "MSI 64-bit" } | %{ $_.href }

# Extract version
$href -match "allwaysync-x64-(?<VERSION>\d+-\d+-\d+)\.msi" | Out-Null
$version = $Matches.Version -replace "-","."

# Build the package
@{
    Version  = $version
    FileUrl  = $href
} | New-Package