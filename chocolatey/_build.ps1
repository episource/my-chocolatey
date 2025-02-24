# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1

#
# This script downloads a prebuild nupkg from the chocolatey galery
#

# Determine latest version
$newestNupkgUrl = "https://community.chocolatey.org/api/v2/package/chocolatey/" 
$redirect = Invoke-Webrequest -usebasicparsing -maximumredirect 0 `
    -erroraction silentlycontinue $newestNupkgUrl
$nupkgName = Split-Path -leaf $redirect.Headers.Location 

# Check if the package has already been downloaded
$nupkgFile = Get-Item "$global:CFRepository/$nupkgName" `
    -ErrorAction SilentlyContinue
If ($nupkgFile) {
    Write-Verbose "Existing package found: $nupkgFile"
    return $nupkgFile
}

$vtApiKey = Get-Variable "CFVtApiKey" -ErrorAction SilentlyContinue
If ($vtApiKey) {
    Get-WebFile -Url $newestNupkgUrl -OutFile $global:CFBuildRoot -VtApiKey $vtApiKey
} Else {
    Get-WebFile -Url $newestNupkgUrl -OutFile $global:CFBuildRoot
}