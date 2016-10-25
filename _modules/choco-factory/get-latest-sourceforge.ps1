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
    Retrieves information about the latest release from Sourceforge.

.DESCRIPTION
    This functions queries a Sourceforge project to get information about the
    latest available version.
    
    One are many regular expressions can be specified to select a specific file
    and to extract version information from the file's path.
    
.PARAMETER Project
    Name of the sourceforge project.
    
.PARAMETER Filter
    One or many filter regular expressions to select the files of interest.
    
    For each filter expression, the matching items are sorted by Version,
    publication date and file path in descending order. The file url of the 
    first item is used as result. 
    
    The first filter expression must include a named capture group "VERSION"
    capturing a version string. The version string should be a valid semver
    version with optional revision number - otherwise the returned VersionInfo
    structure needs extra processing to be compatible with the Publish-Package
    cmdlet.
    
    All following filter expression can use the named backreference 
    '\k<VERSION>' to refer to the version of the item that matched the first
    filter expression. It's also possible to include a capture group "VERSION".
    Then only items with a version equal to the version of the item that matched
    the first filter expression are considered for selection.
    
    An error is reported when a filter does not match any item.
    
.OUTPUT
    A VersionInfo structure including a version string and one ore many file
    urls. The version string is returned as captured by the $Filter. Depending
    on the filter expression, post processing might be required to convert the
    version string into a valid "semver with revision" version string.

#>
function Get-VersionInfoFromSourceforge {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String] $Project,
        
        [Parameter(Mandatory=$true)]
        [String[]] $Filter
    )
    Import-CallerPreference -AdditionalPreferences @{ ProgressBarId = 0 }
    
    $rssUrl      = "https://sourceforge.net/projects/$Project/rss?path=/"
    $rssResponse = Invoke-Webrequest -UseBasicParsing -Uri $rssUrl
    $rssXml      = [Xml]$rssResponse
    
    $versionInfo = @{
        Version  = $null
        FileUrl  = @()
        Checksum = @()
    }
    
    ForEach ($f in $Filter) {
        $expandedFilter = $f
        If ($versionInfo.Version) {
            $expandedFilter = $f -replace '\\k<VERSION>',$versionInfo.version
        }
        
        $matchingItems = $rssXml.rss.channel.item | % {
            $item = @{
                Title   = $_.title.InnerText
                PubDate = [DateTime]::ParseExact(
                    $_.pubDate, 'ddd, dd MMM yyyy HH:mm:ss UT',
                    [CultureInfo]::InvariantCulture)
                FileUrl = $_.link
                Checksum = "$($_.content.hash.algo):$($_.content.hash.'#text')"
            }
            
            $isMatch = $false
            If ($item.Title -match $expandedFilter) {
                If (-not $versionInfo.Version) {
                    If ($Matches['VERSION']) {
                        $isMatch      = $true
                        $item.Version = $Matches['VERSION']
                    }
                } ElseIf (-not $Matches['VERSION'] `
                        -or $Matches['VERSION'] -eq $versionInfo.Version) {
                    $isMatch      = $true
                    $item.Version = $Matches['VERSION']
                }
            }
            
            If ($isMatch) {
                New-Object PSObject -Property $item | Write-Output
            }
        } 
        
        If ($matchingItems) {
            Write-Debug "Matching items:`n`n$(_Format-Object $matchingItems)"
        
            $newestItem = $matchingItems | `
                Sort-Object -Property PubDate,Title -Descending | `
                ConvertTo-SortedByVersion -Property Version -Descending | `
                Select-Object -First 1
                
            $versionInfo.FileUrl  += $newestItem.FileUrl
            $versionInfo.Checksum += $newestItem.Checksum
            
            If (-not $versionInfo.Version) {
                $versionInfo.Version = $newestItem.Version
            }
        } Else {
            Write-Error `
                "No item matched the filter expression ""$expandedFilter"""
        }
    }
    
    If ($versionInfo.FileUrl.length -eq 1) {
        $versionInfo.FileUrl  = $versionInfo.FileUrl[0]
        $versionInfo.Checksum = $versionInfo.Checksum[0]
    }
    return $versionInfo    
}