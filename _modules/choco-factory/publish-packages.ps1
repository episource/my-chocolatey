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


Import-Module import-callerpreference
Import-Module test-admin

<#
.SYNOPSIS
    Test and publish all nupkg packages found below $BuildRoot to $Repository.
    
.DESCRIPTION
    This function searches recursivly for nupkg package files below $BuildRoot.
    Any package found is tested by installing it locally. On success it is
    published to $Repository.
    
    Important: This cmdlet should be run in a VM - all packages to be published
    are installed locally to ensure their functionality. This might harm your
    system!
    
.PARAMETER BuildRoot
    Search for nupkg files starts in this directory.
    
    This parameter defaults to $global:CFBuildRoot if defined, or otherwise 
    './_build'.
    
.PARAMETER Repository
    Defines the repository folder to which the packages are to be published.
    
    This parameter defaults to $global:CFRepository.
    
.PARAMETER NoTest
    Skip test installation of packages to be published.
    
.PARAMETER AssumeVm
    Don't ask before doing a test installation. Assume the cmdlet is being run
    in a VM that can be easily resetted in case of something unexpected is
    happening.
    
#>
function Publish-Packages {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)] [String] $BuildRoot
            = (_Get-Var 'global:CFBuildRoot'            '.'),
        [Parameter(Mandatory=$false)] [String] $Repository
            = $global:CFRepository,
        [Parameter(Mandatory=$false)] [Switch] $NoTest
            = (_Get-Var 'global:CFNoTest'               $false),
        [Parameter(Mandatory=$false)] [Switch] $AssumeVm 
            = $false
    )
    Import-CallerPreference -AdditionalPreferences @{ ProgressBarId = 0 }
    
    # prepare progress bar
    $ProgressBarId          = $ProgressBarId + 1
    $ProgressBarState       = @{
        activity = "Test and publish chocolatey packages..."
        status   = "Initializing..."
        current  = 0
        max      = 1
    }
    _Update-Progress $ProgressBarState -noIncrease
    
    If (-not $BuildRoot -or -not `
            (Test-Path -Path $BuildRoot -PathType Container)) {
        Write-Warning "Build root directory does not exist: $BuildRoot"
        return
    }
    If (-not $Repository -or -not `
            (Test-Path -Path $Repository -PathType Container)) {
        Write-Warning (
            "Repository directory does not exist: $Repository`n" +
            "Press [Y] to create or [H] to abort."
        )
        New-Item -Path $Repository -ItemType Directory
    }
    
    $pkgsUntested  = @()
    $pkgsUntested += Get-ChildItem -Path $BuildRoot -Filter *.nupkg -Recurse | 
        Select-Object -ExpandProperty FullName
    $pkgsPassed    = @()
    
    If (-not $NoTest -and $pkgsUntested.length -gt 0) {
        Assert-Admin
    
        If (-not $AssumeVm) {
            Write-Warning -WarningAction Inquire (
                "About to test package installation. This might harm your " +
                "system. Continue only in a VM created for that purpose.`n" +
                "Packages to be tested:`n$pkgsUntested"
            )
        }
        
        $ProgressBarState.max = 2 * $pkgsUntested.length
        _Update-Progress $ProgressBarState -noIncrease
        
        ForEach ($pkg in $pkgsUntested) {
            $nupkg = $pkg |Split-Path -Leaf
            $nupkg -match $_nupkgRegex |
                Out-Null
            
            $pkgId      = $Matches.pkgId
            $pkgVersion = $Matches.pkgVersion
            $pkgDir     = $pkg | Split-Path -Parent
            
            Try {
                $ProgressBarState.status = `
                    "Test installation: $pkgId-$pkgVersion"
                _Update-Progress $ProgressBarState
            
                $chocoArgs = @('install', $pkgId, '--version', $pkgVersion,
                    '--force', '--yes', '--debug', '--verbose',
                    "--source=$Repository;$pkgDir")
                $chocoOutput = & choco $chocoArgs | Out-String
                
                If ($LastExitCode -ne 0) {
                    Write-Warning `
                        "Failed to install nupkg: $pkg`n$chocoOutput"
                } Else {
                    $pkgsPassed += $pkg
                    $ProgressBarState.max++
                    
                    Write-Verbose `
                        "Test installation succeeded: $pkg`n$chocoOutput"                
                }
            } Finally {
                $ProgressBarState.status = `
                    "Cleanup test installation: $pkgId-$pkgVersion"
                _Update-Progress $ProgressBarState
            
                $chocoArgs = @('uninstall', $pkgId, '--force',
                    '--removedependencies', '--yes')
                $chocoOutput = & choco $chocoArgs | Out-String
                
                If ($LastExitCode -ne 0) {
                    Write-Warning -WarningAction Inquire `
                        "Failed cleanup test installation of $pkg`n$chocoOutput"
                }
            }
        }
    } Else {   
        $pkgsPassed = $pkgsUntested
        $ProgressBarState.max += $pkgsPassed.length
    }
    
    $pkgsPublished = @()
    ForEach ($pkg in $pkgsPassed) {
        $ProgressBarState.status = "Moving packages to repository..."
        _Update-Progress $ProgressBarState
        
        $pkgsPublished += Move-Item -Path $pkg -Destination $Repository `
            -PassThru
    }
    
    If ($pkgsPublished.length -eq 0) {
        Write-Host "No packages were published."
    } Else {
        Write-Host (
            "Published packages:`n" +
            "$($pkgsPublished | Split-Path -Leaf | Format-List | Out-String)"
        )
    }
    return $pkgsPublished
}