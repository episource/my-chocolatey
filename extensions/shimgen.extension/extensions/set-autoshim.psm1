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
. $PSScriptRoot/config.ps1

<#
.SYNOPSIS
    Configure automatich shim generation.

.DESCRIPTION
    Per default, chocolatey installs shims for every executable found in the
    package installation folder. The shim generation can be configured on
    a file-to-file basis by creating appropriate *.ignore and *.gui files. This
    cmdlet simplifies this task.
    
    See also https://chocolatey.org/docs/features-shim.
    
.PARAMETER Pattern
    Pattern identifiying executables to be configured. Can be an array, too.
    
    A pattern is matched against the end of an executable's path relative to the
    target directory of the package being installed (e.g.
    C:\ProgramData\chocolatey\lib\shimgen.extension - this does not include the
    tools subdirectory!).
    Wildcards *, **, ? are supported:
        *  : matching 0 to n characters, but not path separators
        ** : matching 0 to n characters, including path separators
        ?  : matching a single character, but not path separators
    
.PARAMETER Mode
    Shim generation mode: 
        - Ignore  : Don't generate a shim for matching files
        - Default : Restore default shim generation behavior for matching files.
                    That is: Generate a shim for matching executable, 
                    autodetecting gui applications. If a gui application is
                    found, the shim does not wait for the application to exit.
                    Otherwise the shim keeps running.
        - Gui     : Generate a shim for matching files, that does not wait for
                    the shimed application to exit.
                    
.PARAMETER Invert
    OPTIONAL - Match iall executables not matched by any of the $Pattern-s.
    
.OUTPUT
    All matching executables.
    
.LINK
    https://chocolatey.org/docs/features-shim
#>
function Set-AutoShim {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [String[]] $Pattern,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("Default", "Ignore", "Gui")]
        [String] $Mode,
        
        [Parameter(Mandatory=$false)]
        [Switch] $Invert = $false
    ) 
    
    $pkgFolder   = $env:chocolateyPackageFolder
    $executables = Get-ChildItem $pkgFolder -Filter "*.exe" -Recurse
    $processed   = @()
    
    $regexPattern = $Pattern | %{
        $r = [Regex]::Escape($_) `
            -replace "(\\\\|/)" , "[/\\]" `
            -replace "\\\*\\\*" , ".*" `
            -replace "\\\*"     , "[^/\\]*" `
            -replace "\\\?"     , "[^/\\]"
        return $r + "$"
    }
    
    ForEach ($exe in $executables) {
        $absPath = $exe.FullName
        
        Try {
            Push-Location
            Set-Location $pkgFolder
            
            $relPath = Resolve-Path -LiteralPath $absPath -Relative
        } Finally {
            Pop-Location
        }
        
        $isMatch = $Invert
        ForEach ($r in $regexPattern) {
            If ($relPath -match $r) {
                $isMatch = -not $Invert
                break
            }
        }
        
        If ($isMatch) {
            If ($Mode -eq "Ignore") {
                New-Item -Force "$absPath.ignore" | Out-Null
            } Else {
                Remove-Item -Force -LiteralPath "$absPath.ignore" -ErrorAction SilentlyContinue
            }
            
            If ($Mode -eq "Gui") {
                New-Item -Force "$absPath.gui" | Out-Null
            } Else {
                Remove-Item -Force -LiteralPath "$absPath.gui" -ErrorAction SilentlyContinue
            }
            
            $processed += $absPath
        }
    }
    
    return $processed
}