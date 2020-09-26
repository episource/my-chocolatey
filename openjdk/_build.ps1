# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


# Query github API to get url and version of the latest release
$repo = 'ojdkbuild/ojdkbuild'
$filename = "java-[0-9]+-openjdk-(?<VERSION>[0-9\.]+-[0-9]).windows\.ojdkbuild\.x86_64\.zip"
$hashfile = "$filename\.sha256"


# Export the package (subject to _config.ps1)
$vi = Get-VersionInfoFromGithub -Repo $repo -File $filename -EnableRegex -Limit 20 -FindMax |
      Add-ChecksumFromGithubAsset -ChecksumFileRegex $hashfile -Algorithm sha256
      
# Massage the version identifier
# Chocolatey uses a flavored semver style
#  - "-" separated sufix introduces prerelease information
# Openjdk uses "-" sufix for build information
#  => merge revision and build number
$semverTokens = Get-SemverTokens $vi.Version -DefaultMajorMinorPatch
$revision = [int]$semverTokens.REVISION * 100 + [int]$semverTokens.PRERELEASE
$vi.Version = "$($semverTokens.MAJOR).$($semverTokens.MINOR).$($semverTokens.PATCH).$revision"

New-Package -VersionInfo $vi -AutoUnzip:$false