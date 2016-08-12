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
. $PSScriptRoot/_utils.ps1

Import-Module import-callerpreference

<#
.SYNOPSIS
    Retrieves current version information from github, that is compatible with
    the input expected by Export-Package.

.DESCRIPTION
    This functions queries the github.api to get information about the latest
    release from github. The result is compatible with the Export-Package
    function from the choco-factory module.
    
    This function is a more specialized variant of Get-LatestReleaseFromGithub.
    
    Usage is subject to github's rate limit rules:
    https://developer.github.com/v3/rate_limit/
    
.PARAMETER Repo
    Name of the github repository to query: group/name
    
.PARAMETER File
    The filename for which the asset url is to be extracted. Can be an array of
    filenames.
        
.PARAMETER HashFile
    The filename of an asset containing the hash of the file addressed by
    $File. The hash algorithm defaults to sha256, but can be overwritten
    using $HashAlgorithm. Just like $File, this can be an array, too. The number
    of entries must be less  than the number of Files specified.
    
    If no $HashFile is provided, no hash can be retrieved and Export-Package
    won't be able to check file integrity.
        
.PARAMETER HashAlgorithm
    The hash algorithm that has been used to create $HashFile. Supported values
    are all arguments accepted by the Get-FileHash cmdlet's Algorithm parameter.
    
    An array can be specified to set a different algorithm vor each $HashFile.
    If there are more $HashFile-s than $HashAlgorithm-s specified, the last
    algorithm is used for all remaining files.
    
    The default algorithm is sha256.
    
.PARAMETER EnableRegex
    Interpret $File and $HashFile as regular expression.
    
.PARAMETER ExtractVersionHook
    A use defined script block to extract the version string from the release
    data: 1) release name and 2) tag_name.
    
    The resulting version string is checked to comply with the semver
    specification.
    
    The default is to return (1) if not null or empty and otherwiese (2).
    
.OUTPUT
    A VersionInfo structure according to the description of the Export-Package
    cmdlet.
        
.EXAMPLE
    Get-VersionInfoFromGithub -Repo 'gurnec/HashCheck' -FilenameRegex '.*'
#>
function Get-VersionInfoFromGithub {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]  [String]   $Repo,
        [Parameter(Mandatory=$true)]  [String[]] $File,
        [Parameter(Mandatory=$false)] [String[]] $HashFile
            = @(),
        [Parameter(Mandatory=$false)] [String[]] $HashAlgorithm 
            = @('sha256'),
        [Parameter(Mandatory=$false)] [Switch]   $EnableRegex
            = $false,
        [Parameter(Mandatory=$false)] [ScriptBlock] $ExtractVersionHook
            = { param($name, $tag_name) If ($name) { return $name } return $tag_name },
        [Parameter(Mandatory=$false)] [String]   $ApiToken 
            = (_Get-Var 'global:CFGithubToken'      $null)
    )
    Import-CallerPreference -AdditionalPreferences "ProgressBarId"
    
    # Build asset filter
    $normalizedFile     = @() + $File
    $normalizedHashFile = @() + $HashFile
    $fileCount          = $normalizedFile.length
    
    If ($EnableRegex) {
        $filter = @() + $normalizedFile + $normalizedHashFile
    } Else {
        $filter = @()
        ForEach ($f in $normalizedFile) {
            $filter += '^' + [Regex]::Escape($f) + '$'
        }
        ForEach ($f in $normalizedHashFile) {
            $filter += '^' + [Regex]::Escape($f) + '$'
        }
    }
    
    $algorithms  = @() + $HashAlgorithm
    
    
    # Query the latest release
    $release = Invoke-GithubApiLatestRelease -Repo $repo `
        -Filter $filter -ApiToken $ApiToken
    For ($i = 0; $i -lt $filter.length; $i++) {
        If (-not $release.Url[$i]) {
            Write-Error "Asset $($filter[$i]) has not been found."
            return
        }
    }
        
    $normalizedUrls = @() + $release.Url
    $fileUrls       = $normalizedUrls[0..($fileCount - 1)]
    $hashUrls       = @()
    
    write-debug "here"
    If ($normalizedUrls.length -gt $fileCount) {
        $hashUrls   = $normalizedUrls[$fileCount..($normalizedUrls.length - 1)]
    }
    
    
    # Extract and validate version
    $version = & $ExtractVersionHook $release.name $release.tag_name
    If (-not ($version -match $_semverRegex)) {
        Write-Error "$version does not comply with semver specification"
        return
    }

    
    # Download the hash file and exract the hash value
    $hashValues = @()
    For ($i = 0; $i -lt $hashUrls.length; $i++) {
        $algoIdx = $i
        If ($algoIdx -ge $algorithms.length) {
            $algoIdx = $algorithms[-1]
        }
    
        $hashResponse = Invoke-WebRequest -Uri $hashUrls[$i] -UseBasicParsing
        $hashString   = [System.Text.UTF8Encoding]::UTF8. `
            GetString($hashResponse.Content) -replace ' .*$'
        $hashValues  += "$($algorithms[$algoIdx]):$hashString" 
    }
   

    # Format all version info
    $versionInfo = @{
        Version = $version
        Url     = $fileUrls
        UrlHash = $hashValues
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
    The function returns a hash with the following values:
        version : The version string of the latest release. This is either the
                  name of the latest release - if defined - or the associated
                  tag_name. This item is common to all functions in the
                  get-latest module.
        url     : Download url of the selected asset. See also parameter  
                  $FilenameRegex. An array of urls might might be returned if
                  $Limit is greater 1. An array of urls is always returned if
                  multiple $Filter regular expressions have been provided. When
                  multiple $Filter regular expressions are provided and $Limit
                  is set to a value greater than 1, each array entry might be an
                  array of urls, too.
                  $null is returned if no matching asset has been found.
                  This item is common to all functions in the get-latest module.
        name    : The name of the release as provided by the github api.
        tag_name: The name of the underlying git tag.
        
.EXAMPLE
    Get-LatestVersionFromGithub -Repo 'gurnec/HashCheck' -FilenameRegex '.*'
#>
function Invoke-GithubApiLatestRelease {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]  [String]   $Repo,
        [Parameter(Mandatory=$false)] [String[]] $Filter = ".*",
        [Parameter(Mandatory=$false)] [Int]      $Limit = 1,
        [Parameter(Mandatory=$false)] [String]   $ApiToken 
            = (_Get-Var 'global:CFGithubToken'      $null)
    )
    Import-CallerPreference -AdditionalPreferences "ProgressBarId"
    
    $ProgressBarId = $ProgressBarId + 1
    $pActivity = "Querying latest release for github repository $Repo"
    

    $apiUrl = "https://api.github.com/repos/$repo/releases/latest"
    $requestHeader = @{}
    If ($ApiToken) {
        $requestHeader.Authorization = "token $ApiToken"
    }
    
    $json = $null
    Try {
        While ($json -eq $null) {
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
                $json = $response.Content | ConvertFrom-Json
                break
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
    
    $normalizedFilters = @() + $Filter
    $assets            = $json.assets
    $allUrls           = @()
    
    ForEach ($filter in $normalizedFilters) {
        $curUrls = $assets | ? { $_.name -match $filter } |
            Select-Object -First $Limit -ExpandProperty 'browser_download_url'
        $curUrls = @() + $curUrls
            
        If ($curUrls.length -eq 1) {
            $allUrls += $curUrls[0]
        } ElseIf ($curUrls.length -eq 0) {
            $allUrls += $null
        } Else {
            # http://stackoverflow.com/questions/6157179/append-an-array-to-an-array-of-arrays-in-powershell
            $allUrls += ,$curUrls
        } 
    }
    
    $url              = $allUrls
    If ($url.length -eq 1) {
        $url = $allUrls[0]
    }

    return @{
        url      = $url

        name     = $json.name
        tag_name = $json.tag_name
    }
}

Set-Alias glv-gh Get-VersionInfoFromGithub