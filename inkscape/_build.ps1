# Enable common parameters
[CmdletBinding()] Param()

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


$domain = "https://inkscape.org"
$latestUrl = "$domain/release/"
$latestResponse = Invoke-WebRequest -Uri $latestUrl -MaximumRedirection 0 -ErrorAction Ignore
$latestUrl = $latestResponse.Headers.Location

$versionText = Split-Path -Leaf $latestUrl
If (-not ($versionText -match "inkscape-(?<VERSION>\d+(?:\.\d+){0,2})")) {
    Write-Error "Failed to retrieve inkscape version."
    return
}

$version = $Matches.VERSION
While ($version.Split('.').length -lt 3) {
    $version += '.0'
}

$dlPage = Invoke-WebRequest "$domain/release/$versionText/windows/64-bit/compressed-7z/dl/" -UseBasicParsing
$fName = "$versionText-x64.7z"
$zipUrl = $dlPage.links | select -expand href -ErrorAction ignore `
    |? { $_ -match "$fName`$" }`
    |% { if ($_.StartsWith("http")) { "$_" } else { "$domain$_" } } `
    | select -first 1
$md5Url = $dlPage.links | select -expand href -ErrorAction ignore `
    |? { $_ -match "$fName.md5`$"  }`
    |% { if ($_.StartsWith("http")) { "$_" } else { "$domain$_" } } `
    | select -first 1
$md5 = Get-ChecksumFromWeb -Url $md5Url -Filename $fName -ValueOnly


# Format version info and build the package
$versionInfo = @{
    Version  = "$version"
    FileUrl  = "$zipUrl"
    Checksum = "md5:$md5"
}
New-Package -VersionInfo $versionInfo