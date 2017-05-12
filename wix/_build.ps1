# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


$cache = @{ changes = "" }
$vi = Get-VersionInfoFromGithub `
    -Repo "wixtoolset/wix3" -File "wix\d+-binaries.zip" -EnableRegex `
    -ExtractVersionHook {
        $changes = Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/wixtoolset/wix3/$($_.tag_name)/History.md"
        $changes -match "#.*Version (?<VERSION>(?:\d+\.){2,3}\d+)" | Out-Null
        $cache["changes"] = $changes
        return $Matches.VERSION
    }
$vi["ReleaseNotes"] = $cache["changes"]

New-Package -VersionInfo $vi
