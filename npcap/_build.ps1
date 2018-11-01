# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


$apiArgs = @{ ApiEndpoint = "/repos/nmap/npcap/releases" }
$apiToken = Get-Variable "CFGithubToken" -ErrorAction SilentlyContinue
If ($apiToken) {
    $apiArgs.ApiToken = $apiToken.Value
}
$releaseList = Invoke-GithubApi @apiArgs
$release = $releaseList `
    | ?{ $_.name -match "npcap \d+(\.\d+){1,2}(-r\d+)?" } `
    | Select-Object -first 1

$distVersion = $release.tag_name.TrimStart("v")
$versionParts = $distVersion.replace("-r", ".").Split(".")
While ($versionParts.Length -lt 3) {
    $versionParts += "0"
}
$version = [String]::Join(".", $versionParts)


New-Package -VersionInfo @{
    Version = $version
    Fileurl = "https://nmap.org/npcap/dist/npcap-$distVersion.exe"
}