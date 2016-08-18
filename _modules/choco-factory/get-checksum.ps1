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
    Retrieves a file's checksum from a checksum file found at some url.

.DESCRIPTION
    Downloads a checksum file from a given url and extracts the checksums for
    one or many file names.
    
    A checksum file is expected to have the following format:
    {checksum/hash} SPACE* ASTERISK? {filename}
    
.PARAMETER Url
    Url pointing to a checksum file.
    
.PARAMETER Filename
    The name of the file whose checksum is extracted. Can be an array if
    multiple checksums are to be extracted.               
    
.PARAMETER EnableRegex
    Interpret $Filename as regular expression. Per default $Filename-s are
    matched as literal strings.
    
.OUTPUT
    One or many hex strings representing the checksums of the given $Filename-s.
#>
function Get-ChecksumFromWeb {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]  [String]   $Url,
        [Parameter(Mandatory=$true)]  [String[]] $Filename,
        [Parameter(Mandatory=$false)] [Switch]   $EnableRegex
            = $false
    )
    Import-CallerPreference

    $normalizedFilename = @() + $Filename
    If (-not $EnableRegex) {
        $normalizedFilename = $normalizedFilename | %{
            return [Regex]::Escape($_) }
    }
    
    $checksumWebResponse = Invoke-WebRequest -UseBasicParsing -Uri $Url
    
    # The content property might consist of a byte[] only (depending on the
    # content type header) => ToString() gives the expected plain text result
    $checksumFileContent = $checksumWebResponse.ToString()
    
    return $normalizedFilename | %{
        $checksumRegex = "(?m)^(?<CHECKSUM>[a-zA-Z0-9]+)\s+\*?$_"

        If (-not ($checksumFileContent -match $checksumRegex)) {
            Write-Error "Failed to retrieve checksum of $_!"
        }
        
        return $Matches.CHECKSUM
    }
}