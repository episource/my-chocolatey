# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


function Normalize-Version($versionString) {
    $versionParts = $versionString.
            TrimStart("v").
            Split(".", [StringSplitOptions]::RemoveEmptyEntries)
    
    For ($i = 0; $i -lt 3; $i++) {
        If ($versionParts.Length -eq $i) {
            $versionParts += "0"
        } Else {
            $versionParts[$i] = [String][Int]$versionParts[$i]
        }
    }
        
    return [String]::Join(".", $versionParts)
}


$repo = "TransposonY/GestureSign"
$filenameRegex = "^GestureSign-\d(\.\d)+-Portable\.zip$"

$apiArgs = @{ ApiEndpoint = "/repos/$repo/releases" }
$apiToken = Get-Variable "CFGithubToken" -ErrorAction SilentlyContinue
If ($apiToken) {
    $apiArgs.ApiToken = $apiToken.Value
}
$releases = Invoke-GithubApi @apiArgs


$versionInfo = $releases[0] | Get-VersionInfoFromGithubResponse `
    -File $filenameRegex -EnableRegex

# Releases prior to 2015-08-12 have a chinese/japanese description
$changes = $releases | ?{ $_.published_at -ge "2015-08-12" } |
    %{
        $version = Normalize-Version $_.tag_name
        $date = ([DateTime]$_.published_at).ToString("yyyy-MM-dd")
        $text = $_.body `
            -replace "(?m)^#*\s*Major changes\s*$" `
            -replace "(?m)^#*\s*Bugfixes\s*$","`n## Bugfixes" `
            -replace "\[[^\]]+\.(zip|exe)\]\([^\)]+\)"
        $text = $text.Trim()
        
        return "# $version ($date)`n$text"
    }
$versionInfo.ReleaseNotes = [String]::Join("`n`n`n", $changes)


New-Package $versionInfo