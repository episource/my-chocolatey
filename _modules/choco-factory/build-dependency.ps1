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


<#
.SYNOPSIS
    Ensure that a build-time dependency is installed and return the path of it's
    package directory.

.DESCRIPTION
    This function is used to ensure that build-time dependencies (chocolatey
    packages) are installed. It also returns the associated package directory.
    
    An error is raised if the package isn't found.
        
.PARAMETER Version
    The version requirement following nuspec syntax:
    https://docs.microsoft.com/de-de/nuget/create-packages/dependency-versions
    
    Defaults to "[0.0.0,)"
    
    
           
.OUTPUT
    Without `-Detailed` switch: The package directory as FileSystemInfo object.
    With `-Detailed` switch: A map with the following properties
        Path - The package directory as FileSystemInfo object.
        Version - The installed version
           
.EXAMPLE
    TODO
#>
function Select-BuildDependency {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [String] $Name,
        
        [Parameter(Mandatory=$false,ValueFromPipeline=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [String] $Version = "[0.0.0,)",
        
        [Parameter(Mandatory=$false,ValueFromPipeline=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [Switch] $Detailed = $false
    ) 
    
    Begin {
        $chocoCmd = Get-Command choco
        $chocoDir = Get-Item "$($chocoCmd.Path)/../../"
        
        $versionComparer = [VersionComparer]::new()
    }
    Process {
        $pkgDir = "$chocoDir/lib/$Name"
        $pkgNuspec = "$pkgdir/$Name.nuspec"
        $versionRequirement = _Parse-NugetVersionSpec $Version
                
        If (-not (Test-Path -Type Leaf $pkgNuspec)) {
            Write-Error "Dependency $dependencyDesc not installed!"
            return
        }
    
        $versionOk = $true
        $actualVersion = $(_Get-NuspecIdAndVersion($pkgNuspec)).Version
        If ($versionRequirement.MinVersionInclusive) {
            $versionOk = $versionOk -and $versionComparer.Compare(
                $actualVersion, $versionRequirement.MinVersionInclusive) -ge 0 
        }
        If ($versionRequirement.MinVersionExclusive) {
            $versionOk = $versionOk -and $versionComparer.Compare(
                $actualVersion, $versionRequirement.MinVersionExclusive) -gt 0 
        }
        If ($versionRequirement.MaxVersionInclusive) {
            $versionOk = $versionOk -and $versionComparer.Compare(
                $actualVersion, $versionRequirement.MaxVersionInclusive) -le 0 
        }
        If ($versionRequirement.MaxVersionExclusive) {
            $versionOk = $versionOk -and $versionComparer.Compare(
                $actualVersion, $versionRequirement.MaxVersionExclusive) -lt 0 
        }
        
        If (-not $versionOk) {
            Write-Error "Found $Name=$actualVersion, but wanted $dependencyDesc!"
            return
        }        
        
        If ($Detailed) {
            Write-Output @{
                Path = $pkgDir
                Version = $actualVersion
            }
        } Else {
            Write-Output $(Get-Item $pkgDir)
        }
    }
}