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
    Install a link to the start menu.

.DESCRIPTION
    Adds a link to Programs/Chocolatey in the common start menu (all users). All
    links created are recorded for later uninstall by the
    Uninstall-StartMenuLink cmdlet.
    
    This cmdlet shares most of its parameters with the
    Install-ChocolateyShortcut cmdlet that is included in chocolatey out of the
    box.
    
.PARAMETER LinkName
    Name of the shortcut to be created. Only characters allowed by the
    filesystem are supported.
    
.PARAMETER TargetPath
    The link target. Usually this is an absolute path of an executable file.
    
.PARAMETER WorkingDirectory
    OPTIONAL - The working directory where $TargetPath is executed.
    
.PARAMETER Arguments
    OPTIONAL - Arguments to be passed to the executable specified by
    $TargetPath.

.PARAMETER IconLocation
    OPTIONAL - Icon file to be used for the new shortcut. Icons can be extracted
    from executables, too.

.PARAMETER Description
    OPTIONAL - Sets the comment property for the new shortcut.

.PARAMETER WindowStyle
    OPTIONAL - Configures startup behavior of the linked application's main
    window.
    
    0 = Hidden, 1 = Normal Size, 3 = Maximized, 7 = Minimized

.PARAMETER RunAsAdmin
    OPTIONAL - Execute $TargetPath executable with administrative priviledges.
    
.OUTPUT
    The path to the shortcut file.
    
.LINK
    https://chocolatey.org/docs/helpers-install-chocolatey-shortcut
#>
function Install-StartMenuLink {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [String] $LinkName,
    
        [Parameter(Mandatory=$true)] 
        [String] $TargetPath,
        
        [Parameter(Mandatory=$false)]
        [String] $WorkingDirectory = $null,
        
        [Parameter(Mandatory=$false)]
        [String] $Arguments = $null,
        
        [Parameter(Mandatory=$false)]
        [String] $IconLocation = $null,
        
        [Parameter(Mandatory=$false)]
        [String] $Description = $null,
        
        [Parameter(Mandatory=$false)]
        [Int32]  $WindowStyle = $null,
        
        [Parameter(Mandatory=$false)]
        [Switch] $RunAsAdmin=$false
    ) 
    
    $pkgFolder    = $env:chocolateyPackageFolder
    $uninstallLog = Join-Path $pkgFolder $uninstallLogName
    $linkPath     = Join-Path $startPath "$LinkName.lnk"
    
    Install-ChocolateyShortcut `
        -ShortCutFilePath $linkPath `
        -TargetPath       $TargetPath `
        -WorkingDirectory $WorkingDirectory `
        -Arguments        $Arguments `
        -IconLocation     $IconLocation `
        -Description      $Description `
        -WindowStyle      $WindowStyle `
        -RunAsAdmin       $RunAsAdmin

        
    # Remember path for Uninstall-StartMenuLink
    Add-Content $uninstallLog -Value $linkPath
    
    
    return $linkPath
}