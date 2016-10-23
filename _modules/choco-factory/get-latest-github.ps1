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
Import-Module github-api

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
        [Parameter(Mandatory=$true)]
        [String] $Repo,
        
        [Parameter(Mandatory=$true)]
        [String[]] $File,
        
        [Parameter(Mandatory=$false)]
        [Switch] $EnableRegex = $false,
            
        [Parameter(Mandatory=$false)]
        [ScriptBlock] $ExtractVersionHook = $null,
        
        [Parameter(Mandatory=$false)]
        [String] $ApiToken = (_Get-Var 'global:CFGithubToken' $null)
    )
    Import-CallerPreference -AdditionalPreferences @{ ProgressBarId = 0 }
    
    
    $args = @{
        GithubResponse = Invoke-GithubApi `
            -ApiEndpoint "/repos/$($repo.Trim('/'))/releases/latest" `
            -ApiToken $ApiToken
        File           = $File
        EnableRegex   = $EnableRegex
    }
    
    If ($ExtractVersionHook) {
        $args.ExtractVersionHook = $ExtractVersionHook
    }
    
    return Get-VersionInfoFromGithubResponse @args
}


<#
.SYNOPSIS
    Retrieves current version information from github, that is compatible with
    the input expected by New-Package.

.DESCRIPTION
    This functions parses the release description returned by the github API to
    get information about the latest release from github. The result is 
    compatible with the New-Package function from the choco-factory module.
    
.PARAMETER GithubResponse
    The result of calling any of the github release API functions.
    
.PARAMETER File
    The filename for which the asset url is to be extracted. Can be an array of
    filenames.
    
.PARAMETER EnableRegex
    Interpret $File as regular expression.
    
.PARAMETER ExtractVersionHook
    A user defined script block to extract the version string from the release
    data information provided by the github api:
    https://developer.github.com/v3/repos/releases/#get-the-latest-release
    
    A custom hook can access the github response via the variables $_ and
    $GithubResponse.
    
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
function Get-VersionInfoFromGithubResponse {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Object] $GithubResponse,
        
        [Parameter(Mandatory=$true)]
        [String[]] $File,
        
        [Parameter(Mandatory=$false)]
        [Switch] $EnableRegex = $false,
        
        [Parameter(Mandatory=$false)] 
        [ScriptBlock] $ExtractVersionHook = { 
                $version = $_.tag_name -replace "^v"
                While ($version.Split('.').length -lt 3) {
                    $version += '.0'
                }
                return $version
            }
    )
    Begin {
        Import-CallerPreference -AdditionalPreferences @{ ProgressBarId = 0 }
        
        function Filter-Assets($assets, $filter) {
            $urls = @()
        
            ForEach ($f in $filter) {
                $matchingUrls = $assets | ?{ $_.name -match $f } |
                    Select-Object -First 1 -ExpandProperty browser_download_url
                If (-not $matchingUrls) {
                    Write-Error "Asset $f has not been found. Available assets:`n $($assets | Format-List | Out-String)"
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
    }
    Process {
        function Invoke-ExtractVersionHook {
            Try {
                $ExtractVersionHook.InvokeWithContext(@{}, @(
                        [PSVariable]::new('_', $GithubResponse)
                        [PSVariable]::new('GithubResponse', $GithubResponse)     
                    )
                )
            } Catch {
                # Propagate original exception
                throw $_.Exception.InnerException
            }
        }
    
        $assets   = $GithubResponse.assets
        $fileUrls = Filter-Assets $assets $normalizedFile

    
        # Extract and validate version
        $version = Invoke-ExtractVersionHook
        If (-not ($version -match $_semverRegex)) {
            Write-Error "$version does not comply with semver specification"
            return
        }

    
        # Format all version info
        $versionInfo = @{
            Version       = $version
            FileUrl       = $fileUrls
            GithubRelease = $GithubResponse
        }
        Write-Verbose (
            "VersionInfo:`n" +
            "$(_Format-Hash $versionInfo)"
        )
        
        return $versionInfo    
    }
}

Set-Alias glv-gh Get-VersionInfoFromGithub