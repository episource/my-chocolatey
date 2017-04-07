# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


$dlIndexUrl = "https://1.eu.dl.wireshark.org/win64/"
$dlIndex = Invoke-WebRequest -UseBasicParsing $dlIndexUrl
$versionInfo = $dlIndex.Links | %{ 
    If ($_.href -match "Wireshark-win64-(?<VERSION>(?:\d+\.){2,3}\d+).exe") {
        return @{ FileUrl="$dlIndexUrl$($_.href)"; Version=$Matches.VERSION } 
    } 
} | ConvertTo-SortedByVersion -Property "Version" -Descending | Select-Object -First 1

New-Package -VersionInfo $versionInfo