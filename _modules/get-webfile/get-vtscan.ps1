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

# Based on Version 3.7.3 taken from http://poshcode.org/3226
# Authors: Joel Bennet, Bill Barry, Gwen Dallas, Mike Ling
# Original license: CC0 "No Rights Reserved"
# (see http://poshcode.org/Terms.html)

Set-StrictMode -Version latest
$ErrorActionPreference = "Stop"

Import-Module import-callerpreference

$vtApiUrlReport  = "http://www.virustotal.com/vtapi/v2/url/report"
$vtApiFileReport = "https://www.virustotal.com/vtapi/v2/file/report"    

# max. $vtLimit Requests / $vtLimitWindow permitted
$vtLimit         = 4                       
$vtLimitWindow   = New-TimeSpan -Minutes 1

# timestamps of recent API invocations
$global:GWFVirusTotalInvocations = @()

# consider the scan result incomplete if not this amount of scans is available
$vtMinResults    = 50

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
    
.PARAMETER MinResults
    The minimum number of scan results (scan engines) for a request to be
    considered successful.

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
        [Parameter(Mandatory=$true)]  [String]$Url,
        [Parameter(Mandatory=$false)]    [int]$MinResults = $vtMinResults
    )
    Import-CallerPreference -AdditionalPreferences @{ ProgressBarId = 0 }
    
    $ProgressBarId      = $ProgressBarId + 1
    $pActivity          = "Perform VirusTotal.com virus scan: $Url"
    
    $now                = Get-Date
    $scanTimeout        = $now + $vtTimeout
    
    $resultCount        = 0
    $positveCount       = $null
    $urlScanId          = $null
    $urlReportPermalink = $null 
    $fileScanId         = $null
    
    $delaySec           = 5
    
    For (; $scanTimeout -gt $now; $now = Get-Date) {
        $percent = 100 - ($scanTimeout - $now).TotalSeconds / `
            $vtTimeout.TotalSeconds * 100
            
        $params = @{
            'apikey' = $ApiKey
        }
        
        # We are interested in the file scan result, but me must query the url
        # report first
        If ($fileScanId) {
            Write-Progress -Activity $pActivity `
                -Id $ProgressBarId -ParentId ($ProgressBarId - 1) `
                -PercentComplete $percent -Status "Query file scan result..."
        
            $vtApiUrl        = $vtApiFileReport
            $params.resource = $fileScanId
        } ElseIf ($urlScanId) {
            Write-Progress -Activity $pActivity `
                -Id $ProgressBarId -ParentId ($ProgressBarId - 1) `
                -PercentComplete $percent -Status "Awaiting url scan result..."
        
            $vtApiUrl        = $vtApiUrlReport
            $params.resource = $Url
        } Else {
            Write-Progress -Activity $pActivity `
                -Id $ProgressBarId -ParentId ($ProgressBarId - 1) `
                -PercentComplete $percent -Status "Query url scan result..."
        
            $vtApiUrl        = $vtApiUrlReport
            $params.resource = $Url
            $params.scan     = '1'
        }
        
        Try {
            $apiResult = _Invoke-VtApi -ApiUrl $vtApiUrl -Params $params `
                -AbsTimeout $scanTimeout
        } Catch {
            Write-Error $_.Exception.Message
            return
        }
               
        $responseCode = $apiResult | Select-Object `
            -ExpandProperty "response_code" -ErrorAction SilentlyContinue
            
        If ($responseCode -ne 1) {
            Write-Verbose "Result not yet available - Retrying!"
            
            $now = Get-Date
            $delayTimeout = $now + $delaySec
            For (; $delayTimeout -gt $now; $now = Get-Date) {
                If ($now -gt $scanTimeout) {
                    Write-Error "VirusTotal timeout ($vtTimeout)."
                    return
                }
            
                $remainingSeconds = ($delayTimeout - $now).TotalSeconds
                Write-Progress -Activity $pActivity `
                    -Id $ProgressBarId -ParentId ($ProgressBarId - 1) `
                    -Status "Waiting for next request..." `
                    -SecondsRemaining $remainingSeconds `
                    
                Start-Sleep -Seconds 1
            }
            
            $delaySec *= 2
        } Else {
            If ($fileScanId) { # A file scan result has been retrieved
                # Too few results:
                # When submitting a file to the web frontend, not all results
                # are available immediately. Maybe it's the same with the API.
                # => Retry
                If ($resultCount -lt $MinResults) {
                    Write-Verbose "Received $resultCount results. At least $MinResults wanted. Retrying!"
                } Else { # We are done
                    $result = @{
                        'positives'    = $apiResult.positives
                        'totalScans'   = $apiResult.total
                        'sha256'       = $apiResult.sha256
                        'permalink'    = $apiResult.permalink
                        'urlPermalink' = $urlReportPermalink
                    }
                    
                    Write-Verbose "Scan result:`n$(_Format-Hash $result)"
                    Write-Progress -Activity $pActivity `
                        -Id $ProgressBarId -ParentId ($ProgressBarId - 1) `
                        -Completed
                    
                    return $result
                }
                
            } Else { # A url scan result has been retrieved
                $resultCount  = $apiResult | Select-Object `
                    -ExpandProperty "total" -ErrorAction SilentlyContinue
                $fileScanId         = $apiResult | Select-Object `
                    -ExpandProperty "filescan_id" -ErrorAction SilentlyContinue
                $urlScanId          = $apiResult | Select-Object `
                    -ExpandProperty "scan_id" -ErrorAction SilentlyContinue
                $urlReportPermalink = $apiResult | Select-Object `
                    -ExpandProperty "permalink" -ErrorAction SilentlyContinue
                    
                If (($resultCount -gt 0) -and ($fileScanId -eq $null)) {
                    Write-Error "No file has been scanned. Filesize > 32MB?"
                    return
                }
            }
        
        }
    }
    
    Write-Error ("VirusTotal timeout ($vtTimeout):`n" + `
        " -> Received $total/$MinScans scan results")
}

function _Invoke-VtApi($ApiUrl, $Params, $AbsTimeout) {
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
        Write-Debug "POST $ApiUrl`n$(_Format-Hash $Params)"
        
        $now = Get-Date
        $remainingSeconds = ($AbsTimeout - $now).TotalSeconds
        $response = Invoke-WebRequest -Uri $ApiUrl -Method POST -Body $Params `
            -TimeoutSec $remainingSeconds -Verbose:$false `
            -UseBasicParsing
        
        Write-Debug "Raw response:`n$(_Format-Object $response)"
        
        If ($response.StatusCode -eq 200) {
            $json = $response.Content | ConvertFrom-Json
            Write-Debug "Got VirusTotal.com API response:`n$(_Format-Object $json)"
       
            return $json
        } ElseIf ($response.StatusCode -eq 403) {
            Write-Error "Received HTTP 403 - Wrong ApiKey?"
            return
        } ElseIf ($response.StatusCode -ne 204) {
            Write-Error "Received HTTP $($response.StatusCode)"
            return
        }
        
        Write-Verbose "Received HTTP $($response.StatusCode) - Retrying"
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

function _Format-Hash($Hash) {
    $obj = New-Object psobject -Property $Hash
    return _Format-Object $obj
}

function _Format-Object($Obj) {
    $str = $Obj | Format-List | Out-String
    return $str.Trim()
}