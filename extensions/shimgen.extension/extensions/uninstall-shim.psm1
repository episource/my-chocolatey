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
    Uninstall all shims created with Install-Shim.

.DESCRIPTION
    Uninstalls all shims that have been previously created for the current
    package using the Install-Shim cmdlet.
    
.OUTPUT
    Uninstalled shims.
#>
function Uninstall-Shim {
    [CmdletBinding()]
    Param() 
    
    $pkgFolder    = $env:chocolateyPackageFolder
    $uninstallLog = Join-Path $pkgFolder $uninstallLogName  
    $uninstalled  = @()
    
    If (Test-Path $uninstallLog) {
        Get-Content $uninstallLog | %{
            If ($_) {
                $item = $_.Split(";")
                $name = $item[0]
                $path = $item[1]
                $shim = $item[2]

                If (Test-Path $shim) {
                    Try {
                        Uninstall-BinFile -Name $name -Path $path `
                            -ErrorAction Stop
                        $uninstalled += $shim
                    } Catch {
                        Write-Warning "Failed to uninstall ${shim}:`n$_"
                    }
                } Else {
                    Write-Warning "Shim $shim not found. Nothing to do."
                }
            }
        }
        
        Remove-Item $uninstallLog
    } Else {
        Write-Verbose "No uninstall log found. Nothing to do."
    }
    
    return $uninstalled
}