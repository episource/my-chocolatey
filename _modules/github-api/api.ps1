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

Import-Module import-callerpreference


<#
.SYNOPSIS
    Invoke a github API endpoint respecting the rate limit.

.DESCRIPTION
    This cmdlet simplifies invocation of the github api. It takes care of 
    authentication and respects github's rate limit.
    
    Currently GET requests are supported only.
    
.PARAMETER ApiEndpoint
    The github API endpoint, e.g. /repos/:owner/:repo/releases/latest
    
.PARAMETER ApiToken
    A github api token to enable authenticated API requests. By default API
    requests are done without authentification which results in a lower
    rate limit. Some resources might not be available as well.
    
.OUTPUT
    The API's JSON response converted to a Powershell object (ConvertFrom-Json).
    See https://developer.github.com/v3/repos/releases/#get-the-latest-release 
    for details.
    
.EXAMPLE
    Get-Invoke-GithubApiLatestRelease -ApiEndpoint '/repos/git-for-windows/git/releases'
    
#>
function Invoke-GithubApi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String] $ApiEndpoint,
        
        [Parameter(Mandatory=$false)] 
        [String] $ApiToken = $null
    )
    Import-CallerPreference -AdditionalPreferences @{ ProgressBarId = 0 }
    
    $baseUri = [Uri]::new("https://api.github.com")
    $apiUrl = [Uri]::new($baseUri, $ApiEndpoint).AbsoluteUri
    
    $ProgressBarId = $ProgressBarId + 1
    $pActivity = "Querying Github API: $apiUrl"
    
    $requestHeader = @{
        Accept = "application/vnd.github.v3+json"
    }
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
                    -UserAgent "github-api client by episource@gmx.de" `
                    -Uri "$apiUrl" -Method GET -Headers $requestHeader `
                    -UseBasicParsing
            } Catch {
                # Invoke-WebRequest throws @ 4XX
                $response = $_.Exception.Response
                if ($response -eq $Null) {
                    Write-Error $_
                    return
                }
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

function _Format-Object($Obj) {
    $str = $Obj | Format-List | Out-String
    return $str.Trim()
}