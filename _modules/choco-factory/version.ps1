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


# See ConvertTo-SortedByVersion
class VersionComparer : System.Collections.Generic.IComparer[Object] {
    Static $stringComparer = [StringComparer]::InvariantCultureIgnoreCase
    [Object] $property = $null
    
    VersionComparer() {
    }
    
    VersionComparer([Object] $property) {
        $this.property = $property
    }
    
    [Int] Compare([Object]$in1, [Object]$in2) {
        If ($this.property) {
            Try {
                [ScriptBlock]$versionSelector = [ScriptBlock]$this.property
                $v1 = $in1 |% $versionSelector
                $v2 = $in2 |% $versionSelector
            } Catch {
                $p = [String]$this.property
                $v1 = $in1.$p
                $v2 = $in2.$p
            }
        } Else {
            $v1 = [String] $in1
            $v2 = [String] $in2
        }
        
        return $this.CompareImpl($v1, $v2)
    }
    
    [Int] CompareImpl([String]$v1, [String]$v2) {
        function tokenize-semver($version) {
            If ($version -match $_semverRegex) {
                $tokens = @(
                    $Matches.MAJOR,
                    $Matches.MINOR,
                    $Matches.PATCH 
                )
                
                # Might not exist -> bracket operator!
                $tokens += $Matches['REVISION']
                If ($Matches['PRERELEASE']) {
                    $tokens += $Matches['PRERELEASE']
                } Else {
                    # version without prerelease string has higher priority
                    # example: 1.0.0-SNAPSHOT < 1.0.0
                    # U+10FFFF = 0xdbffdfff is the highest UTF-16 code point
                    # see also https://en.wikipedia.org/wiki/UTF-16
                    $tokens += "$([char]0xdbff)$([char]0xdfff)"
                }
                
                $tokens += $Matches['BUILD']
                return $tokens
            }
            
            return $null
        }
        
        $v1Tokens  = tokenize-semver $v1
        $v2Tokens  = tokenize-semver $v2
        If (-not ($v1Tokens -and $v2Tokens)) {
            $v1Tokens = $v1.Split(".-+")
            $v2Tokens = $v2.Split(".-+")
        }

        $order     = 0
        $minLength = [Math]::Min($v1Tokens.length, $v2Tokens.length)
        For ($i = 0; $i -lt $minLength; $i++) {
            Try {
                $order = ([Int]$v1Tokens[$i]).CompareTo([Int]$v2Tokens[$i])
            } Catch {
                $order = [VersionComparer]::stringComparer.Compare(
                    $v1Tokens[$i], $v2Tokens[$i])
            }
            
            If ($order -ne 0) {
                return $order
            }
        }
        
        return $v1Tokens.length.CompareTo($v2Tokens.length)
    }
}


Add-Type @"
using System;
using System.Collections.Generic;
using System.Linq;

public static class StableSort {
    public static IEnumerable<object> SortAsc(
            IEnumerable<object> input, IComparer<object> comparer) {
        return input.OrderBy(obj => obj, comparer);
    }
    
    public static IEnumerable<object> SortDesc(
            IEnumerable<object> input, IComparer<object> comparer) {
        return input.OrderByDescending(obj => obj, comparer);
    }
}
"@


<#
.SYNOPSIS
    Sort by version information.
    
.Descending
    Sorts a list of version strings or a list of objects with associated version
    information. The default sort order is ascending.
    
    If possible, the version string is sorted according to the semver
    specification with additional support for an optional fourth version
    number (revision). Otherwise the version string is splitted into tokens at
    the characters ([.-+]). If a token is a number string (\d+), its numerical
    value is used for comparison. Other tokens are compared as string ignoring
    case and using the invariant culture. Tokens with lower index are compared
    first (higher priority). Tokens missing in one of the version strings are
    considered empty.
    
    A property or script block can be provided to extract the version
    information associated with an input object. By default, the input object
    is expected to be a string-like object (that is, it can be casted to a
    string).
    
.PARAMETER Input
    The list of input objects or version strings. Can be passed in using the
    pipeline.
    
.PARAMETER Property
    OPTIONAL - A name of a property containing version information associated to
    the input object or a script block that retrieves this version information.
    The input object is available to the script block as $_.
    
.PARAMETER Descending
    OPTIONAL - Sort the input objects in descending order.
    
.OUTPUT
    The input objects as sorted enumeration.
    
#>
function ConvertTo-SortedByVersion {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [Alias("VersionString")]
        [Object[]] $Input,
        
        [Parameter(Mandatory=$false)]
        [Object] $Property,
        
        [Parameter(Mandatory=$false)]
        [Switch] $Descending = $false
    )
    Begin {
        Import-CallerPreference
    }
    End {
        $comparer = [VersionComparer]::new($Property)
        
        If ($Descending) {
            [StableSort]::SortDesc($Input, $comparer) | Write-Output
        } Else {
            [StableSort]::SortAsc($Input, $comparer) | Write-Output
        }
    }
}