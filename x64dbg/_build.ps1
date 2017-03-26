# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


# Note: There's only "one" github release, whose assets get updated frequently
$apiArgs = @{ ApiEndpoint = "/repos/x64dbg/x64dbg/releases" }
$apiToken = Get-Variable "CFGithubToken" -ErrorAction SilentlyContinue
If ($apiToken) {
    $apiArgs.ApiToken = $apiToken.Value
}
$release = $( Invoke-GithubApi @apiArgs )[0]
$asset = $release.assets | 
    Sort-Object -Property name -Descending |
    Select-Object -First 1
    
$asset.Name -match "snapshot_(?<DATE>\d+-\d+-\d+)_(?<TIME>\d+-\d+).zip" 
New-Package -VersionInfo @{
    Version = "$($Matches.DATE -replace "-",".").$($Matches.TIME -replace "-")" -replace "\.0+","."
    FileUrl = $asset.browser_download_url
}
