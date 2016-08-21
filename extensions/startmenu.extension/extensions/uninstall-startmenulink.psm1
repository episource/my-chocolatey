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
    Uninstall all start menu shortcuts created with Install-StartMenuLink

.DESCRIPTION
    Uninstalls all start menu shortcuts that have been previously created for
    the current package using the Install-StartMenuLink cmdlet.
    
.OUTPUT
    None.
#>
function Uninstall-StartMenuLink {
    [CmdletBinding()]
    Param() 
    
    $pkgFolder    = $env:chocolateyPackageFolder
    $uninstallLog = Join-Path $pkgFolder $uninstallLogName  
    $uninstalled  = @()
    
    If (Test-Path $uninstallLog) {
        Get-Content $uninstallLog | %{
            $lnk = $_
            
            If ($lnk) {
                Try {
                    Remove-Item $lnk -ErrorAction Stop
                    $uninstalled += $lnk
                } Catch {
                    Write-Warning "Failed to uninstall ${lnk}:`n$_"
                }
            }
        }
        
        Remove-Item $uninstallLog
    } Else {
        Write-Verbose "No uninstall log found. Nothing to do."
    }
    
    If ((Get-ChildItem $startPath | Measure-Object) -eq 0) {
        Remove-Item $startPath
    }
    
    return $uninstalled
}