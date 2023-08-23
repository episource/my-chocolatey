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


<#
.SYNOPSIS
    Locate all templates and build them using the new-package cmdlet.

.DESCRIPTION
    This cmdlet recursively locates all chocolatey templates below the given
    $Path and builds them using the new-package cmdlet.
    
    Defaults to the current location.
        
.PARAMETER Path
    Where to search for packages. Subdirectories are searched recursively.
    
.PARAMETER Exclude
    Array of filter patterns matched against nuspec directory path relative
    to Path. Matching packages are excluded.
    
.OUTPUT
    The paths of the nupkgs that have been built.
           
#>
function Invoke-NewPackage {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)] [String]      $Path = $(Get-Location),
        [Parameter(Mandatory=$false)] [String[]]    $Exclude = @()
    )   
    Import-CallerPreference -AdditionalPreferences @{ ProgressBarId = 0 }
    
    # prepare progress bar
    $ProgressBarId          = $ProgressBarId + 1
    $ProgressBarState       = @{
        activity = "Building all chocolatey templates found in $Path"
        status   = "Initializing..."
        current  = 0
        max      = 1
    }
    _Update-Progress $ProgressBarState -noIncrease
    
    $absPath = _Get-AbsolutePath $Path
    $templates = Get-ChildItem -Path $absPath -Filter "*.nuspec" -Recurse | ? {
        $p = $(_Get-AbsolutePath $_.FullName)
        if ($p.StartsWith($absPath)) {
            $p = $p.Substring($absPath.length).TrimStart("\")
        }
        ForEach ($ex in $Exclude) {
            if ($p -like $ex) {
                return $false
            }
        }
        return $true
    }
    $ProgressBarState.max = $templates | Measure-Object | 
        Select-Object -ExpandProperty Count
    
    
    $FailedPkgList = @()
    ForEach ($nuspec in $templates) {
        $ProgressBarState.status = "Building $($nuspec.FullName)"
        _Update-Progress $ProgressBarState
    
        $scriptPath  = Join-Path $nuspec.DirectoryName "_build.ps1"
        $templateDir = Split-Path -Parent $scriptPath
        
        Write-Host "Building package: $templateDir"
        If (Test-Path $scriptPath) {
            # Invoke accompanying build script
            Try {
                & $scriptPath | Out-Null
            } Catch {
                Write-Warning "Failed to build nuspec: $templateDir`n$_"
                $FailedPkgList += $templateDir
            }
        } Else {
            # Build stand-alone nuspec template
            Write-Verbose "Building stand-alone nuspec template: $nuspec"
            New-Package -TemplateDir $templateDir | Out-Null
        }
    }
    
    If ($FailedPkgList) {
        Write-Warning `
            "The following packages failed to build:`n`t$([String]::Join("`n`t", $FailedPkgList)))"
    }
}