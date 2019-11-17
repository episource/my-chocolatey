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
$ErrorActionPreference = "Stop"

. $PSScriptRoot/_utils.ps1
Import-Module import-callerpreference

$vtApiScanUrl  = "https://www.virustotal.com/api/v3/urls"
$vtApiQueryFile = "https://www.virustotal.com/api/v3/files/"
$vtApiReport = "https://www.virustotal.com/api/v3/analyses/"
$vtGuiFile = "https://www.virustotal.com/gui/file/"   
$vtGuiUrl = "https://www.virustotal.com/gui/url/"

# max. $vtLimit Requests / $vtLimitWindow permitted
$vtLimit         = 4                       
$vtLimitWindow   = New-TimeSpan -Minutes 1
$vtSizeLimit     = 32000000 #32MB

# timestamps of recent API invocations
$global:GWFVirusTotalInvocations = @()


# VirusTotal timeout
$vtTimeout       = New-TimeSpan -Minutes 5


<#
.SYNOPSIS
    Scan a file from the web with VirusTotal.com

.DESCRIPTION
    This function uses the VirusTotal.com public API to scan a file on the web
    with VirusTotal.com. The maximum supported file size is 32Mb.
    
    Get-VtScan takes care of the VirusTotal.com rate limit of 4 Requests/Minutes
    and will delay a request if needed.
    
.PARAMETER ApiKey
    The VirusTotal.com api key used for authentication. You find this key in
    your VirusTotal.com community account preferences.
    
.PARAMETER Url
    The file to be scaned. Must be a http(s) Url pointing to a public web
    resource.

.OUTPUT
    Returns a result hash with the following content:
        positives    : The number of virus scanners that determined the file
                       downloaded from the provided URL to be a possible threat
        totalScans   : The number of virus scanners that have scanned the file
                       downloaded from the provided URL
        sha256       : A sha256 hash of the file scanned by VirusTotal.com
        permalink    : A permalink to a detailed file scan result for the file
                       downloaded from the provided URL
        urlPermalink : A permalink to a detailed site scan result for the
                       provided URL
    
.LINK
    www.virustotal.com
#>
function Get-VtScan{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]  [String]$ApiKey,
        [Parameter(Mandatory=$true)]  [String]$Url
    )
    Import-CallerPreference -AdditionalPreferences @{ ProgressBarId = 0 }
    
    $ProgressBarId      = $ProgressBarId + 1
    $pActivity          = "Perform VirusTotal.com virus scan: $Url"
    
    $now                = Get-Date
    $scanTimeout        = $now + $vtTimeout
    
    $urlReportId        = $null
    $urlId              = $null
    $fileHash           = $null
    $fileId             = $null
    
    $initialdelay    = New-TimeSpan -Seconds 1
    $delay           = $initialdelay
    
    $contentLength   = _Get-ContentLength $Url
    if ( -not $contentLength ) {
        Write-Error "No file has been scanned. Failed to retrieve content length!"
        return
    } elseif ( $contentLength -gt $vtSizeLimit ) {
        Write-Error "No file has been scanned. Filesize > 32MB!"
        return
    }
    
    For (; $scanTimeout -gt $now; $now = Get-Date) {
        $percent = 100 - ($scanTimeout - $now).TotalSeconds / `
            $vtTimeout.TotalSeconds * 100
            
        $method = ""
        $params = @{}
        
        # We are interested in the file scan result, but me must query the url
        # report first
        If ($fileHash) {
            Write-Progress -Activity $pActivity `
                -Id $ProgressBarId -ParentId ($ProgressBarId - 1) `
                -PercentComplete $percent -Status "Awaiting file scan result..."
        
            $vtApiUrl = $vtApiQueryFile + $fileHash
            $method = "GET"
        } ElseIf ($urlReportId -or $fileId) {
            Write-Progress -Activity $pActivity `
                -Id $ProgressBarId -ParentId ($ProgressBarId - 1) `
                -PercentComplete $percent -Status "Awaiting url scan result..."
        
            if ($fileId) {
                $vtApiUrl = $vtApiReport + $fileId
            } else {
                $vtApiUrl = $vtApiReport + $urlReportId
            }
            $method = "GET"
        } Else {
            Write-Progress -Activity $pActivity `
                -Id $ProgressBarId -ParentId ($ProgressBarId - 1) `
                -PercentComplete $percent -Status "Request url scan.."
        
            $vtApiUrl = $vtApiScanUrl
            $method = "POST"
            $params.url = $Url
        }
        
        Try {
            $apiResult = _Invoke-VtApi -ApiUrl $vtApiUrl -Method $method `
                -ApiKey $ApiKey -Params $params -AbsTimeout $scanTimeout
        } Catch {
            Write-Progress -Activity $pActivity `
                -Id $ProgressBarId -ParentId ($ProgressBarId - 1) `
                -Completed
            Write-Error $_.Exception.Message -TargetObject $_
            return
        }
                      
        If (-not $urlReportId) {
            $urlReportId = _Get-Field $apiResult { param($d) $d.data.id }
            if ($urlReportId) {
                $delay = $initialdelay
            }
        } ElseIf (-not $fileHash -and -not $fileId) {
            # file_analysis_info may be returned file is scanned for first time
            $fileId = _Get-Field $apiResult { param($d) $d.meta.file_analysis_info.id }
            $fileHash = _Get-Field $apiResult { param($d) $d.meta.file_info.sha256 }
            $urlId = _Get-Field $apiResult { param($d) $d.meta.url_info.id }
            if ($fileHash) {
                $delay = $initialdelay
            }
        } Else {
            $type = _Get-Field $apiResult { param($d) $d.data.type }
            $lastRes = _Get-Field $apiResult { param($d) $d.data.attributes.last_analysis_results }
            $stats = _Get-Field $apiResult { param($d) $d.data.attributes.last_analysis_stats }
            if ($type -ne "file") {
                Write-Progress -Activity $pActivity `
                    -Id $ProgressBarId -ParentId ($ProgressBarId - 1) `
                    -Completed
                Write-Error "Response object type is '$type', but expected 'file'!" `
                    -TargetObject $apiResult
                return
            }
            if (-not $fileHash) {
                $fileHash = _Get-Field $apiResult { param($d) $d.meta.file_info.sha256 }
            }
            
            
            if ($lastRes -and $stats) {
                $result = @{}
                $result.positives = [int]$stats.suspicious + [int]$stats.malicious
                $result.totalScans = $result.positives `
                        + [int]$stats.harmless + [int]$stats.undetected
                $result.sha256 = $fileHash
                $result.permalink = $vtGuiFile + $fileHash
                $result.urlPermalink = $vtGuiUrl + $urlId
                
                Write-Verbose "Scan result:`n$(_Format-Hash $result)"
                Write-Progress -Activity $pActivity `
                    -Id $ProgressBarId -ParentId ($ProgressBarId - 1) `
                    -Completed
                
                return $result
            }
        }
        
        $now = Get-Date
        $delayTimeout = $now + $delay
        For (; $delayTimeout -gt $now; $now = Get-Date) {
            If ($now -gt $scanTimeout) {
                Write-Error "VirusTotal timeout ($vtTimeout)."
                return
            }
        
            $remainingSeconds = ($delayTimeout - $now).TotalSeconds
            Write-Progress -Activity $pActivity `
                -Id $ProgressBarId -ParentId ($ProgressBarId - 1) `
                -Status "Awaiting next request..." `
                -SecondsRemaining $remainingSeconds `
                
            Start-Sleep -Seconds 1
        }
        $delay = New-TimeSpan -Seconds $($delay.Seconds * 3)
    }
    
    Write-Error "VirusTotal timeout ($vtTimeout)."
}

function _Invoke-VtApi($ApiUrl, $Method, $ApiKey, $Params, $AbsTimeout) {
    $ProgressBarId = $ProgressBarId + 1
    $pActivity    = "Invoke VirusTotal.com API: $ApiUrl"
    $pId          = 1
    

    $now          = Get-Date
    $oneMinuteAgo = $now - $vtLimitWindow

    
    # remove invocations outside the rate limit window
    $invocations  = @()
    Foreach ($i in $global:GWFVirusTotalInvocations) {
        If ($i -gt $oneMinuteAgo) {
            $invocations += $i
        }
    }
    
    # wait for rate limit 
    If ($invocations.Length -ge $vtLimit) {
        $timeout = $invocations[-$vtLimit] + $vtLimitWindow
        For (; $timeout -gt $now; $now = Get-Date) {
            If ($now -gt $AbsTimeout) {
                Write-Error "VirusTotal timeout ($vtTimeout)."
                return
            }
        
            $remainingSeconds = ($timeout - $now).TotalSeconds
            Write-Progress -Activity $pActivity `
                -Id $ProgressBarId -ParentId ($ProgressBarId - 1) `
                -Status "Waiting due to rate limit..." `
                -SecondsRemaining $remainingSeconds `
                
            Start-Sleep -Seconds 1
        }
    }
    
    
    # send request
    Try {
        Write-Progress -Activity $pActivity `
            -Id $ProgressBarId -ParentId ($ProgressBarId - 1) `
            -Status "Awaiting API response..." -SecondsRemaining 0
        Write-Verbose "$Method x-apikey=$ApiKey from/to $ApiUrl`n$(_Format-Hash $Params)"
        
        $now = Get-Date
        $remainingSeconds = ($AbsTimeout - $now).TotalSeconds
        Try {
            $response = Invoke-WebRequest -Uri $ApiUrl -Method $Method `
                -Headers @{ "x-apikey" = $ApiKey } `
                -Body $Params -TimeoutSec $remainingSeconds -Verbose:$false `
                -UseBasicParsing -ErrorAction SilentlyContinue
        } Catch {
            $response = $_.Exception.Response
        }
        
        Write-Debug "Raw response:`n$(_Format-Object $response)"
        Write-Verbose "Virus total answer:`n$($response.Content)"
        
        $sc = $response.StatusCode
        If ($sc -eq 200) {
            $json = $response.Content | ConvertFrom-Json
            Write-Debug "Got VirusTotal.com API response:`n$(_Format-Object $json)"
       
            return $json
        } ElseIf ($sc -eq 401) {
            Write-Error "Received HTTP 401 - Check ApiKey!" -TargetObject $response
            return
        } ElseIf ($sc -eq 403 ) {
            Write-Error "Received HTTP 403 - Wrong ApiKey?" -TargetObject $response
            return
        } ElseIf ($sc -ne 429) {
            Write-Error "Received HTTP $sc - giving up!" -TargetObject $response
            return
        }
        
        Write-Verbose "Received HTTP $sc - Retrying"
    } Finally {
        $invocations += Get-Date
        $global:GWFVirusTotalInvocations = $invocations
        
        Write-Progress -Activity $pActivity `
            -Id $ProgressBarId -ParentId ($ProgressBarId - 1) `
            -Completed
    }
    
    
    # Ups, we didn't receive HTTP 200 - Retry
    return _Invoke-VtApi -ApiUrl $ApiUrl -Params $Params -AbsTimeout $AbsTimeout
}
