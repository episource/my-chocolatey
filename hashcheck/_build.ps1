# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


# Query github API to get url and version of the latest release
$repo = 'gurnec/HashCheck'
$filename = "HashCheckSetup-v[0-9\.]+\.exe"
$hashfile = "HashCheckSetup-v[0-9\.]+\.exe\.sha256"


# Export the package (subject to _config.ps1)
Get-VersionInfoFromGithub -Repo $repo `
    -File $filename -HashFile $hashfile -HashAlgorithm 'sha256' `
    -EnableRegex `
    -ExtractVersionHook `
        { param($name, $tag_name) return $tag_name -replace "^v" } |
New-Package -TemplateDir $PSScriptRoot
