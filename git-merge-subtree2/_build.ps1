# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


$repo = "episource/git-merge-subtree2"
$filename = "git-merge-subtree2.zip"

Get-VersionInfoFromGithub -Repo $repo -File $filename `
    | Add-ChecksumFromGithubAsset -Algorithm "sha256" `
        -ChecksumFileRegex "$filename.sha256" `
    | New-Package