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
        
.PARAMETER Name
    The name of the chocolatey package the calling build script depends on.
           
.OUTPUT
    The package directory as FileSystemInfo object.
           
.EXAMPLE
    TODO
#>
function Select-BuildDependency {
    [CmdletBinding()]
    Param(
        [Parameter(ParameterSetName="MinVersion", Mandatory=$true,
                   ValueFromPipeline=$true
                   ,ValueFromPipelineByPropertyName=$true)]
        [Parameter(ParameterSetName="ExactVersion", Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [String] $Name,
        
        [Parameter(ParameterSetName="MinVersion", Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [String] $MinVersion = $null,
        
        [Parameter(ParameterSetName="ExactVersion", Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [String] $ExactVersion = $null
    ) 
    
    Begin {
        $chocoCmd = Get-Command choco
        $chocoDir = Get-Item "$($chocoCmd.Path)/../../"
        
        $versionComparer = [VersionComparer]::new()
    }
    Process {
        $pkgDir = "$chocoDir/lib/$Name"
        $pkgNuspec = "$pkgdir/$Name.nuspec"
        switch ($PsCmdlet.ParameterSetName) {
            "MinVersion" { $dependencyDesc = "$Name>=$MinVersion" }
            "ExactVersion" { $dependencyDesc = "$Name=$ExactVersion" }
        }
                
        If (-not (Test-Path -Type Leaf $pkgNuspec)) {
            Write-Error "Dependency $dependencyDesc not installed!"
            return
        }
        
        $actualVersion = $(_Get-NuspecIdAndVersion($pkgNuspec)).Version
        switch ($PsCmdlet.ParameterSetName) {
            "MinVersion" { 
                $versionOk = $versionComparer.Compare(
                    $actualVersion, $MinVersion) -ge 0 
            }
            "ExactVersion" {
                $versionOk = $versionComparer.Compare(
                    $actualVersion, $ExactVersion) -eq 0 
            }
        }
        
        
        If (-not $versionOk) {
            Write-Error "Found $Name=$actualVersion, but wanted $dependencyDesc!"
            return
        }        
        
        Write-Output $(Get-Item $pkgDir)
    }
}