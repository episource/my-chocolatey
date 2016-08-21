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
    Install a shim to the bin folder using Install-BinFile.

.DESCRIPTION
    Adds a shim to the bin folder using Install-BinFile and registers it for
    later uninstall. Per default uninstallation is done automatically, so
    there's no need to invoke Uninstall-Shim manually.
    
    This cmdlet shares most of its parameters with the
    Install-BinFile cmdlet that is included in chocolatey out of the
    box.
    
.PARAMETER Name
    Name of the shim to be generated. The file extension .exe is added
    automatically.
    
.PARAMETER Path
    The path to the original file. Usually this is an absolute path of an
    executable file, but can also be relative to
    "$($env:ChocolateyInstall)\bin".
    
.PARAMETER UseStart
    OPTIONAL - Don't wait for the shimed application to exit. Use with GUI
    applications.
    
.PARAMETER Command
    OPTIONAL - Arguments to be passed to the executable specified by
    $Path.
    
.PARAMETER NoAutoUninstall
    OPTIONAL - Disable the auto uninstall feature. Uninstall-Shim must
    then be added manually to chocolateyUninstall.ps1.
    
.OUTPUT
    The path to the generated shim.
    
.LINK
    https://chocolatey.org/docs/helpers-install-bin-file
#>
function Install-Shim {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [String] $Name,
    
        [Parameter(Mandatory=$true)] 
        [String] $Path,
        
        [Parameter(Mandatory=$false)]
        [Alias("Gui", "NoWait")]
        [Switch] $UseStart = $false,
        
        [Parameter(Mandatory=$false)]
        [String] $Arguments = $null,
        
        [Parameter(Mandatory=$false)]
        [Switch] $NoAutoUninstall=$false
    ) 
    
    $pkgFolder    = $env:chocolateyPackageFolder
    $binFolder    = "$($env:ChocolateyInstall)\bin"
    $uninstallLog = Join-Path $pkgFolder $uninstallLogName
    $shimPath     = Join-Path $binFolder "$Name.exe"
    
    Install-BinFile `
        -Name      $Name `
        -Path      $Path `
        -UseStart  $UseStart `
        -Arguments $Arguments

        
    If (Test-Path $shimPath) {
        # Remember path for Uninstall-Shim
        Add-Content $uninstallLog -Value "$Name;$Path;$shimPath"
        
        
        # Uninstall automatically
        If (-not $NoAutoUninstall) {
            $uninstallScript = "$pkgFolder/tools/chocolateyUninstall.ps1"
            $uninstallCmd    = "Uninstall-Shim"
        
            If (-not (Test-Path $uninstallScript) -or -not (Select-String `
                -Path $uninstallScript -List `
                "(^|;)\s*$uninstallCmd(\s*\|\s*Out-Null)?\s*(;|#|$)")
            ) {
                Add-Content  $uninstallScript -Value `
                    "`n$uninstallCmd | Out-Null # autogenerated"
            }
        }
    
        return $shimPath
    } Else {
        Write-Error "Failed to create shim $Name to $Path."
        return $null
    }
}