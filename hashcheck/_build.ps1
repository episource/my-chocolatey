# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


# Query github API to get url and version of the latest release
$repo = 'gurnec/HashCheck'
$filename = "HashCheckSetup-v[0-9\.]+\.exe"
$hashfile = "HashCheckSetup-v[0-9\.]+\.exe\.sha256"


# Export the package (subject to _config.ps1)
Get-VersionInfoFromGithub -Repo $repo -File $filename -EnableRegex |
Add-ChecksumFromGithubAsset -ChecksumFileRegex $hashfile -Algorithm sha256 |
New-Package