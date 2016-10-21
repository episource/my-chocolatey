# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1

#
# This script downloads a prebuild nupkg from the chocolatey galery
#

# Determine latest version
$versions = Invoke-Webrequest -UseBasicParsing `
        "https://chocolatey.org/api/v2/package-versions/chocolatey" |
    Select-Object -Expand Content  | ConvertFrom-Json
$newestVersion = $versions[-1]

# Check if the package has already been downloaded
$nupkgFile = Get-Item "$global:CFRepository/chocolatey.$newestVersion.nupkg" `
    -ErrorAction SilentlyContinue
If ($nupkgFile) {
    Write-Verbose "Existing package found: $nupkgFile"
    return $nupkgFile
}

$vtApiKey = Get-Variable "CFVtApiKey" -ErrorAction SilentlyContinue
$nupkgUrl = "https://chocolatey.org/api/v2/package/chocolatey/$newestVersion"
If ($vtApiKey) {
    Get-WebFile -Url $nupkgUrl -OutFile $global:CFBuildRoot -VtApiKey $vtApiKey
} Else {
    Get-WebFile -Url $nupkgUrl -OutFile $global:CFBuildRoot
}