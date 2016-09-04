# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


# Query github API to get url and version of the latest release
$repo = 'git-for-windows/git'
$filename = "PortableGit-[0-9\.]+-64-bit\.7z\.exe"

# Export the package (subject to _config.ps1)
Get-VersionInfoFromGithub -Repo $repo `
    -File $filename -EnableRegex `
    -ExtractVersionHook {
        param($name, $tag_name)
        $tag_name -match "^v(?<MAIN_VERSION>\d+.\d+.\d+)\.windows\.(?<SUB_VERSION>\d+)" | Out-Null
        If ($Matches.SUB_VERSION -gt 1) {
            return "$($Matches.MAIN_VERSION).$($Matches.SUB_VERSION))"
        }
        return $Matches.MAIN_VERSION
    } |
Add-ChecksumFromGithubRelease -GetChecksumHook {
        param($ghRelease, $fname, $fnameEscaped)
        $ghRelease.body -match `
            "(?m)$fnameEscaped\s*\|\s*(?<CHECKSUM>[a-fA-F0-9]{64})" | Out-Null
        return "sha256:$($Matches.CHECKSUM)"
    } |
New-Package