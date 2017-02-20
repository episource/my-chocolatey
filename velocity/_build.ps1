# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


# Query download page
$downloadPageUrl = "http://velocity.silverlakesoftware.com/"
$response = Invoke-WebRequest -UseBasicParsing -Uri $downloadPageUrl
$href = $response.links | ?{
    Set-StrictMode -Off; $_.id -ieq "downloadbutton"
} | %{ $_.href }

# Extract version
$href -match "VelocitySetup-(?<VERSION>\d+\.\d+\.\d+)" | Out-Null
$version = $Matches.Version

# Build the package
@{
    Version  = $version
    FileUrl  = $href
} | New-Package