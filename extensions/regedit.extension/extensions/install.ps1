#requires -version 5

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


<#
.SYNOPSIS
    Install a registry image with auto uninstallation support.
    
.DESCRIPTION
    This cmdlet wraps the Import-Registry cmdlet.adding an auto uninstall
    feature.
    
    See Import-Registry for details.

.PARAMETER Image
    The registry image to be imported (any type).
    
.PARAMETER ParentKey
    OPTIONAL - The registry is imported below the given parent key. The registry
    image must use relative paths if a parent key is specified.
    
.PARAMETER Force
    OPTIONAL - Overwrite existing values.
    
    If $Rebuild is used, $Force disables the confirmation dialog.
    
.PARAMETER Rebuild
    OPTIONAL - Each registry key contained in the image is rebuilt before
    importing its values and subkeys. THIS DELETES ALL EXISTING VALUES AND
    SUBKEYS! RECURSIVELY! USE WITH CARE!
    
.PARAMETER ForceAutoUninstall
    OPTIONAL - Peform uninstallation using the Force parameter. See
    Uninstall-RegistryImage for details.
    
.PARAMETER NoAutoUninstall
    OPTIONAL - Disable the auto uninstall feature. Uninstall-RegistryImage must
    then be added manually to chocolateyUninstall.ps1.
    
.OUTPUT
    None.

#>
function Install-RegistryImage {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [Alias("Data","KeyValuePairs")]
        [System.Collections.IDictionary] $Image,
        
        [Parameter(Mandatory=$false)] 
        [String] $ParentKey = $null,
        
        [Parameter(Mandatory=$false)]
        [Switch] $Force = $false,
        
        [Parameter(Mandatory=$false)]
        [Switch] $Rebuild = $false,
        
        [Parameter(Mandatory=$false)]
        [Switch] $ForceAutoUninstall=$false,
        
        [Parameter(Mandatory=$false)]
        [Switch] $NoAutoUninstall=$false
    )
    
    Try {
        $Image = ConvertTo-FlatRegistryImage -Image $Image
        Import-Registry -Image $Image -ParentKey $ParentKey `
            -Force:$Force -Rebuild:$Rebuild
    } Catch {
        Throw
    }
        
    If (-not $NoAutoUninstall) {
        $pkgFolder       = $env:chocolateyPackageFolder
        $uninstallScript = "$pkgFolder/tools/chocolateyUninstall.ps1"
        
        $imageCode = Format-PowershellRegistryImage -Image $Image -OneLine
        $parentKeyCode = _Format-AsCode $ParentKey
        $forceCode = _Format-AsCode $ForceAutoUninstall
        $uninstallCmd = "Uninstall-RegistryImage -Force:$forceCode " +
            "-ParentKey $parentKeyCode -Image $imageCode # autogenerated"
            
        Add-Content $uninstallScript -Value "`n$uninstallCmd"
    }
}


<#
.SYNOPSIS
    Uninstalls a registry image previously installed with Install-RegistryImage.
    
.DESCRIPTION
    Uninstalls a registry image.
    
.PARAMETER Image
    The registry image to be imported (any type).
    
.PARAMETER ParentKey
    OPTIONAL - The registry is imported below the given parent key. The registry
    image must use relative paths if a parent key is specified.
    
.PARAMETER Force
    OPTIONAL - Delete values that have different values than the image.
    
.PARAMETER KeepEmptyKeys
    OPTIONAL - Don't delete keys when there are no values left.
    
.OUTPUT None
    
#>
function Uninstall-RegistryImage {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [Alias("Data","KeyValuePairs")]
        [System.Collections.IDictionary] $Image,
        
        [Parameter(Mandatory=$false)] 
        [String] $ParentKey = $null,
        
        [Parameter(Mandatory=$false)]
        [Switch] $Force = $false,
        
        [Parameter(Mandatory=$false)]
        [Alias("KeepEmptyKeys")]
        [Switch] $PreserveEmptyKeys = $false
    )
    
    $defaultValue = $null
    $noExpandVars = `
        [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
        
    $lastKeyPath  = $null
    $flatImage    = ConvertTo-FlatRegistryImage $Image
    ForEach ($entry in $flatImage.GetEnumerator()) {
        $path = $entry.Key
        If ($ParentKey) {
            $path = Join-Path $ParentKey $path
        } 
        If (-not $path.Contains(":")) {
            $path = "Registry::$path"
        }
        If (-not (Test-RegistryPathValidity $Path -Type Absolute)) {
            # Test-RegistryPathValidity uses Write-Error internally
            continue
        }
        
        If (-not ($path -match "(?<KEY>.+)[/\\](?<VALUE>[^/\\]+)")) {
            Write-Error "A value cannot be created without parent key: $path"
            continue
        } Else {
            $keyPath   = $Matches.KEY
            
            # Both PowerShell and .Net API are used below: Both expect different
            # names for the default value.
            # PowerShell - $poshValueName: "(Default)"
            # .Net       - $netValueName : ""
            $poshValueName = $Matches.VALUE
            $netValueName  = $poshValueName
            If ($netValueName -eq "(Default)") {
                $netValueName = ""
            }
        }
        
        If (-not (Test-Path $keyPath)) {
            Write-Verbose "Skipping non-existing value: $path"
        } Else {
            $skip     = $true
            $key      = Get-Item $keyPath
            $curValue = $key.GetValue( `
                $netValueName, $defaultValue, $noExpandVars)
            If ($curValue -eq $defaultValue) {
                Write-Verbose "Skipping non existing value: $path"
            } ElseIf ($Force) {
                $skip = $false
            } Else {
                $curKind = $key.GetValueKind($netValueName)
                If ($curKind -eq `
                        [Microsoft.Win32.RegistryValueKind]::ExpandString) {
                    $curValue = [ExpandString]$curValue
                }
                
                $curValueExpression = [PowershellExpression]::Get($curValue)
                $imgRegValue        = [RegistryValue]$entry.Value
                $imgValueExpression = [PowershellExpression]::Get($imgRegValue)
                
                If (($curKind -ne $imgRegValue.valueKind) `
                    -or (Compare-Object $curValue $imgRegValue.value)
                ) {
                    Write-Warning ( 
                        "Preserving modified value`n" +
                        "Expected value: $path=$imgValueExpression`n" +
                        "Actual value  : $curValueExpression")
                } Else {
                    $skip = $false
                } 
            }  
            
            If (-not $skip) {
                # Note: - Remove-ItemProperty cannot delete the default value
                #       - RegistryKey.DeleteValue requires the key to be opened with
                #         writable = $true
            
                Write-Verbose "Deleting value $path"
                
                $parentKeyItem = Get-Item $key.PSParentPath
                $writableKey   = `
                    $parentKeyItem.OpenSubKey($key.PSChildName, $true)
                
                Try {
                    $writableKey.DeleteValue($netValueName)
                } Finally {
                    $writableKey.Close()
                }
            }
        }
        
        If (-not $PreserveEmptyKeys) {
            # Delete key and all parent keys if empty
            For (
                $curKeyPath = $keyPath;
                $curKeyPath -and -not $curkeyPath.EndsWith(":\"); 
                $curKeyPath = Split-Path -Parent $curKeyPath
            ) {
                If (Test-Path $curKeyPath) {
                    $curKey = Get-Item $curKeyPath
                    If ($curKey.ValueCount -eq 0 `
                            -and $curKey.SubKeyCount -eq 0) {
                        Write-Verbose "Deleting empty key: $curKey"
                        Remove-Item $curKeyPath
                    }
                }
            }
        }
    }
}


<#
.SYNOPSIS
    Install a registry image to all local user profiles' registry hives with
    auto uninstall support.
    
.DESCRIPTION
    This cmdlet wraps the Import-Registry cmdlet.adding an auto uninstall
    feature.
    
    See Import-UserRegistry for details.
    
.PARAMETER Image
    The registry image to be imported (any type).
    
.PARAMETER ParentKey
    OPTIONAL - The registry is imported below the given parent key.
    
.PARAMETER SkipDefaultProfile
    OPTIONAL - Don't import the registry image to the default user profile's
    registry hive. The default user profile's registry hive is used to
    initialize the registry of a new local user.

.PARAMETER AlsoHklm
    OPTIONAL - Also import the registry image below HKEY_LOCAL_MACHINE.

.PARAMETER Force
    OPTIONAL - Overwrite existing values.
    
    If $Rebuild is used, $Force disables the confirmation dialog.
    
.PARAMETER Rebuild
    OPTIONAL - Each registry key contained in the image is rebuilt before
    importing its values and subkeys. THIS DELETES ALL EXISTING VALUES AND
    SUBKEYS! RECURSIVELY! USE WITH CARE!
    
.PARAMETER ForceAutoUninstall
    OPTIONAL - Peform uninstallation using the Force parameter. See
    Uninstall-RegistryImage for details.
    
.PARAMETER NoAutoUninstall
    OPTIONAL - Disable the auto uninstall feature. Uninstall-RegistryImage must
    then be added manually to chocolateyUninstall.ps1.
    
.OUTPUT
    None.
  
#>
function Install-UserProfileRegistryImage {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [Alias("Data","KeyValuePairs")]
        [System.Collections.IDictionary] $Image,
        
        [Parameter(Mandatory=$false)] 
        [String] $ParentKey = $null,
        
        [Parameter(Mandatory=$false)]
        [Alias("NoDefault", "NoDefaultProfile", "SkipDefault")]
        [Switch] $SkipDefaultProfile = $false,
        
        [Parameter(Mandatory=$false)]
        [Alias("AlsoHKEY_LOCAL_MACHINE")]
        [Switch] $AlsoHklm = $false,
        
        [Parameter(Mandatory=$false)]
        [Switch] $Force = $false,
        
        [Parameter(Mandatory=$false)]
        [Switch] $Rebuild = $false,
        
        [Parameter(Mandatory=$false)]
        [Switch] $ForceAutoUninstall=$false,
        
        [Parameter(Mandatory=$false)]
        [Switch] $NoAutoUninstall=$false
    )
    
    Try {
        $Image = ConvertTo-FlatRegistryImage -Image $Image
        Import-UserRegistry -Image $Image -ParentKey $ParentKey `
            -SkipDefaultProfile:$SkipDefaultProfile -AlsoHklm:$AlsoHklm `
            -Force:$Force -Rebuild:$Rebuild
    } Catch {
        Throw
    }
        
    If (-not $NoAutoUninstall) {
        $pkgFolder       = $env:chocolateyPackageFolder
        $uninstallScript = "$pkgFolder/tools/chocolateyUninstall.ps1"
        
        $imageCode = Format-PowershellRegistryImage -Image $Image -OneLine
        $parentKeyCode = _Format-AsCode $ParentKey
        $skipDefaultCode = _Format-AsCode $SkipDefaultProfile
        $alsoHklmCode = _Format-AsCode $AlsoHklm
        $forceCode = _Format-AsCode $ForceAutoUninstall
        $uninstallCmd = "Uninstall-UserProfileRegistryImage " +
            "-Force:$forceCode -ParentKey $parentKeyCode -Image $imageCode " +
            "-SkipDefaultProfile:$skipDefaultCode -AlsoHklm:$alsoHklmCode " +
            "# autogenerated"
            
        Add-Content $uninstallScript -Value "`n$uninstallCmd"
    }
}


<#
.SYNOPSIS
    Uninstalls a registry image previously installed with 
    Install-UserProfileRegistryImage.
    
.DESCRIPTION
    Uninstalls a registry image.
    
.PARAMETER Image
    The registry image to be imported (any type).
    
.PARAMETER ParentKey
    OPTIONAL - The registry is imported below the given parent key.
    
.PARAMETER SkipDefaultProfile
    OPTIONAL - Don't import the registry image to the default user profile's
    registry hive. The default user profile's registry hive is used to
    initialize the registry of a new local user.

.PARAMETER AlsoHklm
    OPTIONAL - Also import the registry image below HKEY_LOCAL_MACHINE.
    
.PARAMETER Force
    OPTIONAL - Delete values that have different values than the image.
    
.PARAMETER KeepEmptyKeys
    OPTIONAL - Don't delete keys when there are no values left.
    
.OUTPUT
    None.
    
#>
function Uninstall-UserProfileRegistryImage {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [Alias("Data","KeyValuePairs")]
        [System.Collections.IDictionary] $Image,
        
        [Parameter(Mandatory=$false)] 
        [String] $ParentKey = $null,
        
        [Parameter(Mandatory=$false)]
        [Alias("NoDefault", "NoDefaultProfile", "SkipDefault")]
        [Switch] $SkipDefaultProfile = $false,
        
        [Parameter(Mandatory=$false)]
        [Alias("AlsoHKEY_LOCAL_MACHINE")]
        [Switch] $AlsoHklm = $false,
        
        [Parameter(Mandatory=$false)]
        [Switch] $Force = $false,
        
        [Parameter(Mandatory=$false)]
        [Switch] $KeepEmptyKeys = $false
    )
    
    _ForEach-HKU -SkipDefaultProfile:$SkipDefaultProfile -AlsoHklm:$AlsoHklm `
            -Action {
        If ($ParentKey) {
            $ParentKey = Join-Path $hkuPath $ParentKey
        } Else {
            $ParentKey = $hkuPath
        }
            
        Uninstall-RegistryImage -ParentKey $ParentKey -Image $Image `
            -Force:$Force
    }
}

<#
.SYNOPSIS
    Format a string or boolean as powershell code.
    
.DESCRIPTION
    Converts a string or boolean into a string that can converted back with
    the Invoke-Expression cmdlet.
    
.OUTPUT
    A string that can be passed to the Invoke-Expression cmdlet.
    
#>
function _Format-AsCode {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [Object] $Value
    )
    
    If ($Value -eq $null) {
        return '$null'
    } ElseIf ($Value -eq $true) {
        return '$true'
    } ElseIf ($Value -eq $false) {
        return '$false'
    } ElseIf ($Value.GetType() -eq [String]) {
        return $Value
    }
    
    Write-Error "Unknown value: $Value"
}