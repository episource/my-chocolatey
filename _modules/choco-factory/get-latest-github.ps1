# Copyright 2016 Philipp Serr (episource)
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

Set-StrictMode -Version latest
$ErrorAction = "Stop"

. $PSScriptRoot/_utils.ps1

Import-Module import-callerpreference

<#
.SYNOPSIS
    Retrieves current version information from github, that is compatible with
    the input expected by New-Package.

.DESCRIPTION
    This functions queries the github API to get information about the latest
    release from github. The result is compatible with the New-Package
    function from the choco-factory module.
    
    This function is a more specialized variant of Get-LatestReleaseFromGithub.
    
    Usage is subject to github's rate limit rules:
    https://developer.github.com/v3/rate_limit/
    
.PARAMETER Repo
    Name of the github repository to query: group/name
    
.PARAMETER File
    The filename for which the asset url is to be extracted. Can be an array of
    filenames.
    
.PARAMETER EnableRegex
    Interpret $File as regular expression.
    
.PARAMETER ExtractVersionHook
    A use defined script block to extract the version string from the release
    data: 1) release name and 2) tag_name.
    
    The resulting version string is checked to comply with the semver
    specification.
    
    The default is to return the tag name with any leading 'v' removed.
    
.OUTPUT
    A VersionInfo structure according to the description of the Export-Package
    cmdlet.
    
    The raw github API response is available through the field GithubRelease.
        
.EXAMPLE
    Get-VersionInfoFromGithub -Repo 'gurnec/HashCheck' -File "HashCheckSetup-v[0-9\.]+\.exe" -EnableRegex
#>
function Get-VersionInfoFromGithub {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]  [String]   $Repo,
        [Parameter(Mandatory=$true)]  [String[]] $File,
        [Parameter(Mandatory=$false)] [Switch]   $EnableRegex
            = $false,
        [Parameter(Mandatory=$false)] [ScriptBlock] $ExtractVersionHook
            = { 
                param($name, $tag_name)
                $version = $tag_name -replace "^v"
                While ($version.Split('.').length -lt 3) {
                    $version += '.0'
                }
                return $version
            },
        [Parameter(Mandatory=$false)] [String]   $ApiToken 
            = (_Get-Var 'global:CFGithubToken'      $null)
    )
    Import-CallerPreference -AdditionalPreferences @{ ProgressBarId = 0 }
    
    function Filter-Assets($assets, $filter) {
        $urls = @()
    
        ForEach ($f in $filter) {
            $matchingUrls = $assets | ?{ $_.name -match $f } |
                Select-Object -First 1 -ExpandProperty browser_download_url
            If (-not $matchingUrls) {
                Write-Error "Asset $f has not been found. Available assets:`n`
                    $($assets | Format-List | Out-String)"
                return
            }
        
            $urls += $matchingUrls
        }
        
        return $urls
    }
    
    
    # Build asset filter
    $normalizedFile     = @() + $File
    
    If (-not $EnableRegex) {
        $normalizedFile     = $normalizedFile | %{
            return '^' + [Regex]::Escape($_) + '$' }
    }
    
    
    # Query the latest release
    $jsonResponse = Invoke-GithubApiLatestRelease -Repo $repo `
        -ApiToken $ApiToken
    $assets       = $jsonResponse.assets
    $fileUrls = Filter-Assets $assets $normalizedFile

    
    # Extract and validate version
    $version = & $ExtractVersionHook $jsonResponse.name $jsonResponse.tag_name
    If (-not ($version -match $_semverRegex)) {
        Write-Error "$version does not comply with semver specification"
        return
    }

    
    # Format all version info
    $versionInfo = @{
        Version       = $version
        FileUrl       = $fileUrls
        GithubRelease = $jsonResponse
    }
    Write-Verbose (
        "Latest release of github repository $Repo`n" +
        "$(_Format-Hash $versionInfo)"
    )
    
    return $versionInfo    
}

<#
.SYNOPSIS
    Get information about the latest from github

.DESCRIPTION
    This functions queries the github.api to get information about the latest
    release from github. Usage is subject to github's rate limit rules:
    https://developer.github.com/v3/rate_limit/
    
.PARAMETER Repo
    Name of the github repository to query: group/name
    
.PARAMETER Filter
    Selects for which assets the url should be returned. This can be a
    single regex or an array of regular expression if multiple assets should
    be queried. At most $Limit urls are returned for each $Filter.
    Assets are considered in the order they are returned by the github API.
    
    Any powershell regular expression is valid. Asset names are compared
    case insensitive. The default regular expression is '.*' matching all
    assets.
        
.PARAMETER Limit
    The maximum number of urls to retrieve. See $Filter.
        
.PARAMETER ApiToken
    A github api token to enable authenticated API requests. By default API
    requests are done without authentification which results in a lower
    rate limit.
    
    The token is used to access public information only. Access to any
    restricted scope is not needed. Hence, when creating the token, no scope
    should be assigned.
        
.OUTPUT
    The function returns the response returned by the github API. See
    https://developer.github.com/v3/repos/releases/#get-the-latest-release for
    details.
        
.EXAMPLE
    Get-Invoke-GithubApiLatestRelease -Repo 'git-for-windows/git'
#>
function Invoke-GithubApiLatestRelease {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]  [String]   $Repo,
        [Parameter(Mandatory=$false)] [String]   $ApiToken 
            = (_Get-Var 'global:CFGithubToken'      $null)
    )
    Import-CallerPreference -AdditionalPreferences @{ ProgressBarId = 0 }
    
    $ProgressBarId = $ProgressBarId + 1
    $pActivity = "Querying latest release for github repository $Repo"
    

    $apiUrl = "https://api.github.com/repos/$repo/releases/latest"
    $requestHeader = @{}
    If ($ApiToken) {
        $requestHeader.Authorization = "token $ApiToken"
    }
    
    Try {
        While ($true) {
            Write-Progress -Activity $pActivity `
                    -Id $ProgressBarId -ParentId ($ProgressBarId - 1) `
                    -Status "Waiting for API resonse" `
                    -PercentComplete 0 -SecondsRemaining -1
                    
            Try {
                $response = Invoke-WebRequest `
                    -UserAgent "my-chocolatey by episource@gmx.de" `
                    -Uri "$apiUrl" -Method GET -Headers $requestHeader `
                    -UseBasicParsing
            } Catch {
                # Invoke-WebRequest throws @ 4XX
                $response = $_.Exception.Response
            }
                
            Write-Debug "Raw response:`n$(_Format-Object $response)"
            
            If ($response.StatusCode -eq 200) {
                return $response.Content | ConvertFrom-Json
            } ElseIf ($response.StatusCode -eq 403) {
                $rateLimit      = $response.Headers.'X-RateLimit-Limit'
                $rateLimitReset = [DateTimeOffset]::FromUnixTimeSeconds(
                    $response.Headers.'X-RateLimit-Reset'
                ).LocalDateTime
                
                Write-Verbose "Github rate limit of $rateLimit requests per hour reached. Limit will be resetted at $($rateLimitReset.ToString())."
                
                Do {
                    $now              = Get-Date
                    $remainingSeconds = ($rateLimitReset - $now).TotalSeconds
                    
                    Write-Progress -Activity $pActivity `
                        -Id $ProgressBarId -ParentId ($ProgressBarId - 1) `
                        -Status "Waiting due to rate limit..." `
                        -SecondsRemaining $remainingSeconds -PercentComplete -1
                        
                    Start-Sleep -Seconds 1                    
                } While ($now -le $rateLimitReset)
         
                continue
            } ElseIf ($response.StatusCode -eq 401) {
                Write-Error "Received HTTP 401 - Wrong ApiToken?"
                return
            } Else {
                Write-Error "Received HTTP $($response.StatusCode)"
                return
            }
        }
    } Finally {
        Write-Progress -Completed -Activity $pActivity `
            -Id $ProgressBarId -ParentId ($ProgressBarId - 1) 
    }
}

Set-Alias glv-gh Get-VersionInfoFromGithub