# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


$repo = "episource/bingimg"
$filename = "get-bingimg.ps1"

Get-VersionInfoFromGithub -Repo $repo -File $filename `
    | Add-ChecksumFromGithubAsset -Algorithm "sha256" `
        -ChecksumFileRegex "$filename.sha256" `
    | New-Package