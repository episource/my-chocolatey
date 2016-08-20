# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


# Query github API to get url and version of the latest release
$repo = "processhacker2/processhacker2"
$filename = "ProcessHacker-[0-9\.]+-bin\.zip"


# Export the package (subject to _config.ps1)
Get-VersionInfoFromGithub -Repo $repo -File $filename -EnableRegex |
New-Package