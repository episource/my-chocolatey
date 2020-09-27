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
    Extracts version tokens of a semver version string.
    
.DESCRIPTION
    Parses semver version string and extracts the following tokens:
      - MAJOR
      - MINOR
      - PATCH
      - REVISION
      - PRERELEASE
      - BUILD

    
.PARAMETER Version
    Semver version string.
    
.PARAMETER SortablePrerelease
    Set `PRERELEASE` to U+10FFFF = 0xdbffdfff (highest UTF-16 code point) if
    no PRERELEASE information is available. This simplifies sorting:
    Versions without prerelease string have higher priority!
    
.PARAMETER OmitMissing
    Omit missing components from the returned hash table instead of setting them
    to $null. MAJOR/MINOR/PATCH are not omited if `DefaultMajorMinorPatch` is
    used as well.
    
.PARAMETER DefaultMajorMinorPatch
    Set MAJOR/MINOR/PATCH to `0` instead of `$null` if missing.
    
.PARAMETER TolerantParsing
    Tolerate missing minor and patch versions.
.OUTPUT
    Ordered dictionary with values of the tokens listed above. Omited tokens
    are returned as `$null`.
    
#>
function Get-SemverTokens {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [String] $version,
        
        [Parameter(Mandatory=$false)]
        [Switch] $sortablePrerelease = $false,
        
        [Parameter(Mandatory=$false)]
        [Switch] $omitMissing = $false,
        
        [Parameter(Mandatory=$false)]
        [Switch] $defaultMajorMinorPatch = $false,
        
        [Parameter(Mandatory=$false)]
        [Switch] $tolerantParsing = $false
    )
    Import-CallerPreference
    
    # version without prerelease string has higher priority
    # example: 1.0.0-SNAPSHOT < 1.0.0
    # U+10FFFF = 0xdbffdfff is the highest UTF-16 code point
    # see also https://en.wikipedia.org/wiki/UTF-16
    $tokens = [ordered]@{ 
        "MAJOR"      = $null
        "MINOR"      = $null
        "PATCH"      = $null
        "REVISION"   = $null
        "PRERELEASE" = $null
        "BUILD"      = $null
    }
    $keyList = @() + $tokens.Keys
    
    if ($sortablePrerelease) {
        $tokens["PRERELEASE"] = "$([char]0xdbff)$([char]0xdfff)"
    }
    if ($defaultMajorMinorPatch) {
        $tokens["MAJOR"] = 0
        $tokens["MINOR"] = 0
        $tokens["PATCH"] = 0
    }
    
    $regex = $_semverRegex
    if ($tolerantParsing) {
        $regex = $_semverRegexOptionalMinorPatch
    }
    
    if ($version -match $regex) {
        $keyList | %{
            if ($Matches[$_]) {
                $tokens[$_] = $Matches[$_]
            }
        }
    } else {
        write-error "Failed to parse version string: $version"
    }
    
    if ($omitMissing) {
        $keyList | ?{ $tokens[$_] -eq $null } | %{ $tokens.Remove($_) }
    }
    
    return $tokens
}


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
        try {    
            $v1Tokens = Get-SemverTokens $v1 -SortablePrerelease -TolerantParsing -ErrorAction "Stop"
            $v1Tokens = @() + $v1Tokens.Values
        } catch {
            $v1Tokens = $v1.Split(".-+")
        }
        
        try {    
            $v2Tokens = Get-SemverTokens $v2 -SortablePrerelease -TolerantParsing -ErrorAction "Stop"
            $v2Tokens = @() + $v2Tokens.Values
        } catch {
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
    
.DESCRIPTION
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
        [Object[]] $VersionString,
        
        [Parameter(Mandatory=$false)]
        [Object] $Property,
        
        [Parameter(Mandatory=$false)]
        [Switch] $Descending = $false
    )
    Begin {
        Import-CallerPreference
    }
    End {
        If ($Input.Count -eq 0) {
            $Input = $VersionString
        }
    
        $comparer = [VersionComparer]::new($Property)
        
        If ($Descending) {
            [StableSort]::SortDesc($Input, $comparer) | Write-Output
        } Else {
            [StableSort]::SortAsc($Input, $comparer) | Write-Output
        }
    }
}