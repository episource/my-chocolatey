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


# Represents a String of kind [Microsoft.Win32.RegistryValueKind]::ExpandString
# Use New-ExpandString to create an instance of this type (custom powershell
# classes are not directly available outside the script module)
class ExpandString {
    [String] $value
    
    ExpandString([String]$str) {
        $this.value = $str
    }
    
    [String] ToString() {
        return $this.value
    }
}

# Internal type used to determine the [Microsoft.Win32.RegistryValueKind] of
# a registry value
class RegistryValue {

    [Object]                            $value
    [Microsoft.Win32.RegistryValueKind] $valueKind
    [Bool]                              $isKey = $false
    
    RegistryValue([String]$string) {
        $this.value      = $string
        $this.valueKind  = [Microsoft.Win32.RegistryValueKind]::String
    }
    
    RegistryValue([String[]]$multiString) {
        $this.value     = $multiString
        $this.valueKind = [Microsoft.Win32.RegistryValueKind]::MultiString
    }
    
    RegistryValue([ExpandString]$expandString) {
        $this.value     = $expandString
        $this.valueKind = [Microsoft.Win32.RegistryValueKind]::ExpandString
    }
    
    RegistryValue([Int]$dword) {
        $this.value     = $dword
        $this.valueKind = [Microsoft.Win32.RegistryValueKind]::DWord
    }
    
    RegistryValue([Long]$qword) {
        $this.value     = $qword
        $this.valueKind = [Microsoft.Win32.RegistryValueKind]::QWord
    }
    
    RegistryValue([Byte[]]$binary) {
        $this.value     = $binary
        $this.valueKind = [Microsoft.Win32.RegistryValueKind]::Binary
    }
    
    RegistryValue([System.Collections.IDictionary]$key) {
        $this.value     = $key
        $this.valueKind = [Microsoft.Win32.RegistryValueKind]::None
        $this.isKey     = $true
    }
    
    RegistryValue([RegistryValue]$self) {
        $this.value     = $self.value
        $this.valueKind = $self.valueKind
        $this.isKey     = $self.isKey
    }
}

# Internal type used to get a powershell expression for a given value
class PowershellExpression {
    static [String] Get([String]$string) {
        return '"' + ($string -replace '"','""') + '"'
    }
    
    static [String] Get([String[]]$multiString) {
        return "[String[]]@(" +
            [String]::Join(",",
                ( $multiString | %{ [PowershellExpression]::Get($_) } ) 
            ) + ")"
    }
    
    static [String] Get([ExpandString]$expandString) {
        return "New-ExpandString " + `
            [PowershellExpression]::Get($expandString.value)
    }
    
    static [String] Get([Int]$dword) {
        return "0x{0:x8}" -f $dword
    }
    
    static [String] Get([Long]$qword) {
        return "[Long]0x{0:x16}" -f $qword
    }
    
    static [String] Get([Byte[]]$binary) {
        return "[Byte[]]@(" + [String]::Join(",", $binary) + ")"
    }
    
    static [String] Get([RegistryValue]$regValue) {
        return [PowershellExpression]::Get($regValue.value)
    }
}


# Sort registry keys, such that values come before subkeys at each level.
# The result of the sort operation is equal to visiting all keys in the windows
# registry editor in a depth-first manner. At each level, values are visited
# before subkeys.
# Example: /a/b/c < /a/b/d < /a/b/a/e
Add-Type @"
using System;
using System.Collections.Generic;

public class RegistryPathComparer : IComparer<string> {
    private static readonly char[] pathSeparators = @"/\".ToCharArray();
    private static readonly StringComparer stringComparer =
        StringComparer.InvariantCultureIgnoreCase;
        
    private IDictionary<Tuple<string, string>, int> cache =
        new Dictionary<Tuple<string, string>, int>();
    
    public int Compare(string s1, string s2) {
        Tuple<string, string> cacheKey = Tuple.Create(s1, s2);
        int order = 0;
        
        if (this.cache.TryGetValue(cacheKey, out order)) {
            return order;
        }
        
        order = CompareImpl(s1, s2);
        this.cache.Add(cacheKey, order);
        
        return order;
    }
    
    private int CompareImpl(string s1, string s2) {   
        int order = 0;
        string[] p1 = s1.Split(
            pathSeparators, StringSplitOptions.RemoveEmptyEntries);
        string[] p2 = s2.Split(
            pathSeparators, StringSplitOptions.RemoveEmptyEntries);
        
        // Compare common parent keys first
        int maxLevel = Math.Min(p1.Length, p2.Length) - 1;
        for (int i = 0; i < maxLevel; i++) {
            order = stringComparer.Compare(p1[i], p2[i]);
            if (order != 0) {
                return order;
            }
        }
        
        // Sort values before subkeys at level min(p1.Length, p2.Length)
        order = p1.Length.CompareTo(p2.Length);
        if (order != 0) {
            return order;
        }
        
        // Both paths are have the same level (number of parent keys), which
        // means they are values at the same level => sort alphabetically
        return stringComparer.Compare(p1[maxLevel], p2[maxLevel]);
        
        
    }
}
"@


<#
.SYNOPSIS
    Creates an object representing an REG_EXPAND_SZ registry value.
    
.PARAMETER Value
    The REG_EXPAND_SZ as String. Names of environment variables can be enclosed
    between %-characters. The variables will then be expanded when the value is
    read from the registry. Example: "Path: %PATH%"
    
.OUTPUT
    An object representing an REG_EXPAND_SZ registry value.
    
#>
function New-ExpandString {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [String] $Value
    )
    
    return [ExpandString]$Value
}