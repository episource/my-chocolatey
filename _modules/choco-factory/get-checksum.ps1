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


enum ChecksumType
{
    Any
    Md5
    Sha1
    Sha256
}


<#
.SYNOPSIS
    Retrieves a file's checksum from a checksum file found at some url.

.DESCRIPTION
    Downloads a checksum file from a given url and extracts the checksums for
    one or many file names.
    
    A checksum file is expected to have the following format:
    {checksum/hash} SPACE* ASTERISK? {filename}
    
.PARAMETER Url
    Url pointing to one or many checksum files. If more than one $Url is given,
    the files are appended.
    
.PARAMETER Filename
    The name of the file whose checksum is extracted. Can be an array if
    multiple checksums are to be extracted. The first matching checksum entry is
    being returned.
    
.PARAMETER EnableRegex
    Interpret $Filename as regular expression. Per default $Filename-s are
    matched as literal strings.
    
.OUTPUT
    One or many hex strings representing the checksums of the given $Filename-s.
#>
function Get-ChecksumFromWeb {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]  [String[]] $Url,
        [Parameter(Mandatory=$true)]  [String[]] $Filename,
        [Parameter(Mandatory=$false)] [Switch]   $EnableRegex
            = $false,
        [Parameter(Mandatory=$false)] [Switch]   $ValueOnly
            = $false,
        [Parameter(Mandatory=$false)] [ChecksumType] $ChecksumType
            = [ChecksumType]::Any
    )
    Import-CallerPreference
    If (-not (Get-Variable -Scope script -Name lastFileContent `
            -ErrorAction SilentlyContinue)
    ) {
        $script:lastFileContent = @{
            Url     = $null
            Content = $null
        }
    }

    $Filename = @() + $Filename
    $Url      = @() + $Url
    
    
    If (-not $EnableRegex) {
        $Filename = $Filename | %{
            return [Regex]::Escape($_) }
    }

    # Cache last web request to accomodate Add-ChecksumFromWeb which might
    # perform repeated requests for the same set of urls
    If ($script:lastFileContent.Url -eq $Url.ToString()) {
        Write-Verbose "Using cached checksum file!"
        $checksumFileContent = $script:lastFileContent.Content
    } Else {
        $checksumFileContent = ""
    
        ForEach ($u in $Url) {
            $checksumWebResponse  = Invoke-WebRequest -UseBasicParsing -Uri $u
            
            # The content property might consist of a byte[] only (depending on the
            # content type header) => ToString() gives the expected plain text
            # result
            $checksumFileContent += "`n" + $checksumWebResponse.ToString()
        }
        
        $script:lastFileContent.Url     = $Url.ToString()
        $script:lastFileContent.Content = $checksumFileContent
    }
    
    
    return $Filename | %{
        $fileName = $_
        $checksumRegex = "(?m)^(?<CHECKSUM>[a-zA-Z0-9]+)\s+\*?(?<FILENAME>$fileName)"
        switch ($ChecksumType) {
            Md5 {
                $checksumRegex = "(?m)^(?<CHECKSUM>[a-zA-Z0-9]{32})\s+\*?(?<FILENAME>$fileName)"
            }
            
            Sha1 {
                $checksumRegex = "(?m)^(?<CHECKSUM>[a-zA-Z0-9]{40})\s+\*?(?<FILENAME>$fileName)"
            }
            
            Sha256 {
                $checksumRegex = "(?m)^(?<CHECKSUM>[a-zA-Z0-9]{64})\s+\*?(?<FILENAME>$fileName)"
            }
        }
        
        If (-not ($checksumFileContent -match $checksumRegex)) {
            Write-Error "Failed to retrieve checksum of $_!"
            return $null
        }
        
        If ($ValueOnly) {
            return $Matches.CHECKSUM
        } Else {
            return @{
                Checksum = $Matches.CHECKSUM
                Filename = $Matches.FILENAME
            }
        }
    }
}