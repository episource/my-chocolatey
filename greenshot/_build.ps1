# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


# Query github API to get url and version of the latest release
$repo = 'greenshot/greenshot'
$distfile = "Greenshot-NO-INSTALLER-[0-9\.]+-RELEASE\.zip"
$notesfile = "readme.txt"

# Retrieve version info
$vi = Get-VersionInfoFromGithub -Repo $repo -File $distfile -EnableRegex `
    -ExtractVersionHook { $_.tag_name -replace "^Greenshot-RELEASE-" }
$notesurl = $vi.GithubRelease.assets | ?{ $_.name -eq $notesfile } |
    Select-Object -First 1 -ExpandProperty browser_download_url
$response = Invoke-Webrequest -UseBasicParsing $notesurl
$vi.ReleaseNotes = [System.Text.Encoding]::UTF8.GetString($response.Content)

# Build the package
New-Package $vi