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
    Add given checksums to a VersionInfo structure (hash table).

.DESCRIPTION
    Adds the given $Checksum-s to a VersionInfo structure (hash table) by
    appending them to the VersionInfo.Checksum item. The item is created if it
    does not yet exist.
    
.PARAMETER VersionInfo
    The version info to which the $Checksum will be appended.
    
.PARAMETER Checksum
    A single checksum or an array of checksums. The checksum must be a string of
    the form <md5|sha1|sha256|*>:<hash value> to be supported by the New-Package
    cmdlet. (* refers to any other algorithm supported by Get-FileHash).
    
.OUTPUT
    The $VersionInfo structure with the $Checksum added.
#>
function Add-Checksum {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true)]
        [HashTable[]] $VersionInfo,
        
        [Parameter(Mandatory=$true)]
        [String[]]    $Checksum
    )

    Begin {
        Import-CallerPreference
    } Process {
        ForEach ($vi in $VersionInfo) {
            $checksumProperty = $vi['Checksum']
            If (-not $checksumProperty) {
                $checksumProperty = $Checksum
            } Else {
                $checksumProperty  = @() + $checksumProperty
                $checksumProperty += $Checksum
            }
            
            $vi.Checksum = $checksumProperty
            Write-Output $vi
        }
    } End {
    
    }
}

<#
.SYNOPSIS
    Retrieve checksums for the files listed in a given VersionInfo structure
    (hash table) and adds them to the VersionInfo structure.

.DESCRIPTION
    Uses The Get-ChecksumFromWeb cmdlet to retrieve the checksums for the files
    listed in the VersionInfo.FileUrl item. The retrieved checksums are added
    to the VersionInfo.Checksum item. If the item does not yet exist, it is
    created. With $i being the index of any VersionInfo.FileUrl item, an
    existing checksum `$c = $VersionInfo.Checksum[$i]` is replaced if
    `$c -eq $null`.
    
.PARAMETER VersionInfo
    The VersionInfo structure to which checksums are to be appended.
    
.PARAMETER Algorithm
    Tha hash algorithm that has been used to create the checksum file pointed to
    by $ChecksumFileUrl. See Get-FileHash for a list of supported algorithms.
    
.PARAMETER ChecksumFileUrl
    Url pointing to one or many checksum files. If more than one $Url is given,
    the files are appended.
    
.OUTPUT
    The $VersionInfo structure with the $Checksum added.
#>
function Add-ChecksumFromWeb {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true)]
        [HashTable[]] $VersionInfo,
        
        [Parameter(Mandatory=$true)]
        [String]      $Algorithm,
        
        [Parameter(Mandatory=$true)]
        [Alias("Url", "Uri")]
        [String[]]    $ChecksumFileUrl
    )

    Begin {
        Import-CallerPreference
    } Process {
        ForEach ($vi in $VersionInfo) {
            $fileUrls  = @()  + $vi.FileUrl
            $checksums = @()  + $vi['Checksum']
            
            For ($i = 0; $i -lt $fileUrls.length; $i++) {
                If ($checksums.length -le $i) {
                    $checksums += $null
                }
                $csum = $checksums[$i]
                
                
                # Replace missing checksums only
                If (-not $csum) {
                    $furl = $fileUrls[$i]
                
                    $filename = $null
                    $dirname  = $furl
                    
                    # Also check filenames containing parts of the url
                    While (-not $csum -and $filename -ne $furl) {
                        If ($dirname) {
                            If ($filename) {
                                $filename = (Split-Path -Leaf $dirname) `
                                    + "/$filename"
                            } Else {
                                $filename = Split-Path -Leaf $dirname
                            }
                            
                            $dirname = Split-Path -Parent $dirname
                        } Else {
                            $filename = $furl
                        }
                        
                        Write-Verbose "Trying to get checksum for $filename"
                        $csum     = Get-ChecksumFromWeb -Url $ChecksumFileUrl `
                            -ErrorAction SilentlyContinue -ValueOnly `
                            -FileName $filename 
                    }
                    
                    If (-not $csum) {
                        Write-Error "Failed to retrieve checksum for $furl!"
                        $checksums[$i] = $null
                    } Else {
                        $checksums[$i] = "${Algorithm}:$csum"
                    }
                }
            }
                        
            If ($checksums.length -eq 1) {
                $vi.Checksum = $checksums[0]
            } Else {
                $vi.Checksum = $checksums
            }
            
            Write-Output $vi
        }
    } End {
    
    }
}


<#
.SYNOPSIS
    Retrieve checksums for the files listed in a given VersionInfo structure
    (hash table) and adds them to the VersionInfo structure.

.DESCRIPTION
    Uses The Get-ChecksumFromWeb cmdlet to retrieve the checksums for the files
    listed in the VersionInfo.FileUrl item from a checksum file attached to a
    github release.
    
    The $VersionInfo must have been created with Get-VersionInfoFromGithub. More
    precise it must contain a VersionInfo.GithubRelease item containing the raw
    API response (see Get-VersionInfoFromGithub for details).
    
.PARAMETER VersionInfo
    The VersionInfo structure to which checksums are to be appended. Must have
    VersionInfo.FileUrl and VersionInfo.GithubRelease items.
    
.PARAMETER Algorithm
    The hash algorithm that has been used to create the checksum file pointed to
    by $ChecksumFileUrl. See Get-FileHash for a list of supported algorithms.
    
.PARAMETER ChecksumFileRegex
    Regex matching the name of the release asset that represents the release
    asset.
    
.OUTPUT
    The $VersionInfo structure with the $Checksum added.
#>
function Add-ChecksumFromGithubAsset {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true)]
        [HashTable[]] $VersionInfo,
        
        [Parameter(Mandatory=$true)]
        [String]      $Algorithm,
        
        [Parameter(Mandatory=$true)]
        [Alias("Url", "Uri")]
        [String[]]    $ChecksumFileRegex
    )

    Begin {
        Import-CallerPreference
    } Process {
        ForEach ($vi in $VersionInfo) {
            $assets = $vi.GithubRelease.assets
            $checksumFileUrl = $assets | ?{
                    $_.name -match $ChecksumFileRegex } |
                Select-Object -First 1 -ExpandProperty browser_download_url
            If (-not $checksumFileUrl) {
                Write-Error `
                    "An asset matching $ChecksumFileRegex has not been found. `
                    Available assets:`n$($assets | Format-List | Out-String)"
                continue
            }
            
            Write-Output $vi | Add-ChecksumFromWeb `
                -ChecksumFileUrl $checksumFileUrl -Algorithm $Algorithm
        }
    } End {
    
    }
}


<#
.SYNOPSIS
    Extract checksums from the description of a github release and append them
    to a VersionInfo structure (HashTable).

.DESCRIPTION
    A user defined hook ($GetChecksumHook) is used for extracting checksum
    checksums that are missing in the VersionInfo structure by parsing the
    github release description.     information from the github release description. 
    
    The $VersionInfo must have been created with Get-VersionInfoFromGithub. More
    precise it must contain a VersionInfo.GithubRelease item containing the raw
    API response (see Get-VersionInfoFromGithub for details).
    
.PARAMETER VersionInfo
    The VersionInfo structure to which checksums are to be appended. Must have
    VersionInfo.FileUrl and VersionInfo.GithubRelease items.
    
.PARAMETER GetChecksumHook
    A user defined script block that extracts checksums from the github release
    description. The script block is passed the following parameters (in the
    given order):
        GithubRelease  : The github API response describing the latest release.
        Filename       : The name of the file for which a checksum is to be
                         retrieved.
        FilenameEscaped: The Filename (see above) escaped to be used inside
                         above regular expression.
        FileUrl        : Url of the file for which a checksum is to be
                         retrieved.
        
    The script block should return a String of the form 
    "<md5|sha1|sha256|*>:<hash>" where <md5|sha1|sha256|*> is any hash algorithm
    supported by the Get-FileHash cmdlet and <hash> is the hex encoded checksum
    value. If no checksum could be extracted, $null should be returned instead.
    
.OUTPUT
    The $VersionInfo structure with VersionInfo.Checksum containing the checksum
    values belonging to the VersionInfo.FileUrl-s.
#>
function Add-ChecksumFromGithubRelease {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true)]
        [HashTable[]] $VersionInfo,
        
        [Parameter(Mandatory=$true)]
        [ScriptBlock] $GetChecksumHook
    )

    Begin {
        Import-CallerPreference
    } Process {
        ForEach ($vi in $VersionInfo) {
            $fileUrls  = @()  + $vi.FileUrl
            $checksums = @()  + $vi['Checksum']
            
            For ($i = 0; $i -lt $fileUrls.length; $i++) {
                If ($checksums.length -le $i) {
                    $checksums += $null
                }
                $csum = $checksums[$i]
                
                
                # Replace missing checksums only
                If (-not $csum) {
                    $furl         = $fileUrls[$i]
                    $fname        = Split-Path -Leaf $furl
                    $fnameEscaped = [Regex]::Escape($fname)
                    
                    $checksums[$i] = & $GetChecksumHook `
                        $vi.GithubRelease $fname $fnameEscaped $furl
                    
                    If (-not $checksums[$i]) {
                        Write-Error "Failed to retrieve checksum for $furl!"
                    }
                }
            }
                        
            If ($checksums.length -eq 1) {
                $vi.Checksum = $checksums[0]
            } Else {
                $vi.Checksum = $checksums
            }
            
            Write-Output $vi
        }
    } End {
    
    }
}