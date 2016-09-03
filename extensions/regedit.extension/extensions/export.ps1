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
    Exports a subtree of the windows registry to a flat registry image.
    
.DESCRIPTION
    Exports all values of a given registry key into a flat registry image. The
    export can be done recursively considering subkeys and the entries can be
    filtered prior to exporting. 
    
    By default the resulting image uses absolute paths. Optionally relative
    paths can be exported instead.
    
.PARAMETER Path
    Selects the registry key to be exported. Must be an absolute path. If the
    path does not start with a PSDrive or registry provider prefix, the provider
    prefix "Registry::" is prepended automatically.
    
.PARAMETER Filter
    OPTIONAL - A filter expression to select a subset of the values for export.
    See Get-ChildItem for details.
    
.PARAMETER Recurse
    OPTIONAL - Enable recursive exporting of subkeys.
    
.PARAMETER Relative
    OPTIONAL - If $true, the exported image contains path relative to $Path. By
    default paths are absolute.
    
.OUTPUT
    A flat registry image (see Import-Registry cmdlet).
    
#>
function Export-Registry {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [Alias("Root", "RootKey", "ParentKey")]
        [String] $Path,
        
        [Parameter(Mandatory=$false)] 
        [String] $Filter = $null,
        
        [Parameter(Mandatory=$false)]
        [Switch] $Recurse = $false,
        
        [Parameter(Mandatory=$false)]
        [Switch] $Relative = $false
    )
    If (-not $Path.Contains(":")) {
        $Path = "Registry::$Path"
    }
    Test-RegistryPathValidity $Path -Type Absolute -ErrorAction Stop
    
    $flatImage = `
        [System.Collections.Generic.SortedDictionary[String, Object]]::new(
            [RegistryPathComparer]::new())
           
    
    $rootEntry = Get-Item $Path
    $rootPath  = $rootEntry.PSPath
    $rootMask  = "^(?:Microsoft\.PowerShell\.Core\\)?"
    If ($Relative) {
        $rootMask = "^" + [Regex]::Escape($rootPath) + "\\?"
    }    
    
    $defaultValue = $null
    $noExpandVars = `
        [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
    
    function Add-Key($key) {
        $basePath  = $key.PSPath -replace $rootMask
        
        ForEach ($name in $key.GetValueNames()) {
            If ($basePath) {
                $path = Join-Path $basePath $name
            } Else {
                $path = $name
            }
            
            $kind  = $key.GetValueKind($name)
            $value = $key.GetValue($name, $defaultValue, $noExpandVars)
            If ($kind -eq [Microsoft.Win32.RegistryValueKind]::ExpandString) {
                $value = [ExpandString]$value
            }
            
            $flatImage.$path = $value
        }
    }
    
    Add-Key $rootEntry
    
    If ($Recurse) {
        Get-ChildItem -Path $rootPath -Filter $Filter -Recurse | % {
            Add-Key $_
        }
    }
    
    return $flatImage
}