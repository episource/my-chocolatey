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
    information. The hook is passed the raw github response object as variables
    `$_` and `$GithubResponse`.
    
    The resulting version string is checked to comply with the semver
    specification.
    
    The default is to return the tag name with any leading 'v' removed.
    
.PARAMETER Limit
    OPTIONAL - The number of releases to search for the given assets. A value
    of `1` means only the latest release should be searched.
    
    Defaults to `1`.
    
.PARAMETER FindMax
    OPTIONAL - Search up to `Limit` releases to find the release with the
    highest version number.
    
    Defaults to `$false`.
    
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
        [Int] $Limit = 1,
        
        [Parameter(Mandatory=$false)]
        [Switch] $FindMax = $false,
        
        [Parameter(Mandatory=$false)]
        [String] $ApiToken = (_Get-Var 'global:CFGithubToken' $null)
    )
    Import-CallerPreference -AdditionalPreferences @{ ProgressBarId = 0 }
    
    $maxVi = $null
    $firstAssetError = $null
    for ($pageIndex = 0; $pageIndex -lt $Limit; $pageIndex++) {
        $ghResponse = Invoke-GithubApi `
            -ApiEndpoint "/repos/$($repo.Trim('/'))/releases?per_page=1&page=$pageIndex" `
            -ApiToken $ApiToken
        
        $args = @{
            GithubResponse = $ghResponse
            File           = $File
            EnableRegex    = $EnableRegex
            NoValidation   = $true
        }
        
        if ($ExtractVersionHook) {
            $args.ExtractVersionHook = $ExtractVersionHook
        }
        
        $vi = $null
        try {
            $vi = Get-VersionInfoFromGithubResponse @args
        } catch {
            write-verbose "Release[$pageIndex] didn't match:`n$_"
        
            if (-not $firstAssetError) {
                $firstAssetError = $_
            }
        }
        
        if ($vi) {
            if (-not ($vi.Version -match $_semverRegex)) {
                Write-Error "$($vi.Version) does not comply with semver specification"
                return
            }
            if (-not $FindMax) {
                return $vi
            }
            
            if (-not $maxVi) {
                $maxVi = $vi
            } else {
                $vis = @() + $vi + $maxVi
                $vis = ConvertTo-SortedByVersion $vis -Property "Version" -Descending
                $maxVi = $vis[0]
            }
        }
    }
    
    if (-not $maxVi) {
        Write-Error "No release has been found, that provides the requested files.`n$firstAssetError"
        return
    }
    return $maxVi
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
    
.PARAMETER NoValidation
    OPTIONAL - Disable validation of extracted version string. The only
    validation currently implemented is checking against semver specification.
    
.PARAMETER ExtractVersionHook
    A user defined script block to extract the version string from the release
    data information provided by the github api:
    https://developer.github.com/v3/repos/releases/#get-the-latest-release
    
    A custom hook can access the github response via the variables `$_` and
    `$GithubResponse`. The variable `$FileUrl` gives access to the urls of
    any asset matching the `File` argument or pattern. If option `EnableRegex`
    is being used, the variable `$Matches` provides the regular expression
    pattern matching results for each of the file patterns.
    
    The resulting version string is checked to comply with the semver
    specification.
    
    The default is to return the tag name with any leading 'v' removed. If 
    option `EnableRegex` is enabled and any of the file patterns returned a
    value for the named capturing group 'VERSION', that value is returned
    instead. The default hook adds '.0' to the version string until the string
    has a length of three version parts (major, minor, patch).
    
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
        [Switch] $NoValidation = $false,
        
        [Parameter(Mandatory=$false)] 
        [ScriptBlock] $ExtractVersionHook = { 
                $version = $null
                ForEach ($m in $Matches) {
                    $version = $m['VERSION']
                    If ($version) {
                        break
                    }
                }
                
                If (-not $version) {
                    $version = $_.tag_name -replace "^v"
                }
                
                While ($version.Split('.').length -lt 3) {
                    $version += '.0'
                }
                return $version
            }
    )
    Begin {
        Import-CallerPreference -AdditionalPreferences @{ ProgressBarId = 0 }
        
        function Filter-Assets($assets, $filter) {
            $result = @{ urls=@(); matches=@() }
        
            ForEach ($f in $filter) {
                $Matches = $null
                ForEach ($a in $assets) {
                    If ($a.name -match $f) {
                        $result.urls += $a.browser_download_url
                        $result.matches += $Matches
                        break
                    }
                }
                If (-not $Matches) {
                    Write-Error "Asset $f has not been found. Available assets:`n $($assets | Format-List | Out-String)"
                    return
                }
            }
            
            return $result
        }
        
        # Build asset filter
        $normalizedFile     = @() + $File
        If (-not $EnableRegex) {
            $normalizedFile     = $normalizedFile | %{
                return '^' + [Regex]::Escape($_) + '$' }
        }
    }
    Process {
        $assets   = $GithubResponse.assets
        $filtered = Filter-Assets $assets $normalizedFile
    
        function Invoke-ExtractVersionHook {
            Try {
                $ExtractVersionHook.InvokeWithContext(@{}, @(
                        [PSVariable]::new('_', $GithubResponse)
                        [PSVariable]::new('GithubResponse', $GithubResponse)
                        [PSVariable]::new('Matches', $filtered.matches)                          
                    )
                )
            } Catch {
                # Propagate original exception
                throw $_.Exception.InnerException
            }
        }
    
        # Extract and validate version
        $version = Invoke-ExtractVersionHook
        If (-not $NoValidation -and -not ($version -match $_semverRegex)) {
            Write-Error "$version does not comply with semver specification"
            return
        }

    
        # Format all version info
        $versionInfo = @{
            Version       = $version
            FileUrl       = $filtered.urls
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