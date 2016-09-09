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

$registryPathRegex = [Regex]::new( 
    "^(?<PROVIDERORDRIVE>(?:(?<PROVIDER>[^:]+)::)|(?:(?<DRIVE>[^:]+):))?(?<PATH>(?:(?<KEY>[^:]+)[/\\])?(?<VALUE>[^:/\\]+)?)$",
    [System.Text.RegularExpressions.RegexOptions]::Compiled)

$knownRegistryHives = [System.Collections.Generic.HashSet[Object]]::new( `
    [System.Collections.Generic.IEnumerable[Object]]( `
        Get-ChildItem Registry:: | %{ $_.Name }))

<#
.SYNOPSIS
    Update the cached list of known registry drives.
    
.DESCRIPTION
    Updates the cached list of known registry drives used by
    Test-RegistryPathValidity.
    
.OUTPUT
    None.
#>
function Sync-KnownRegistryDrives {
    [CmdletBinding()]
    Param()
    
    $script:knownRegistryDrives = `
        [System.Collections.Generic.HashSet[Object]]::new( `
        [System.Collections.Generic.IEnumerable[Object]]( `
            Get-PSDrive | ?{ $_.Provider.Name -eq "Registry" } |
                Select-Object -Expand Name))
}
Sync-KnownRegistryDrives
        
<#
.SYNOPSIS
    Tests whether a registry path is a valid absolute or relative path.

.DESCRIPTION
    Tests whether a registry path is a valid absolute or relative path.
    
    Set the ErrorAction parameter to SilentlyContinue if only a boolean result
    should be returned without any error messages.
    
    Note: You might want to refresh the cached list of known registry drives
    before using this cmdlet. See Sync-KnownRegistryDrives.
    
.OUTPUT
    $true if the path was found to be valid -or- otherwise $false.
    
#>
function Test-RegistryPathValidity {
	[CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [String] $Path,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Any", "Absolute", "Relative")]
        [String] $Type = "Any"
    )
    
    $regexResult = $registryPathRegex.Match($Path)
    If (-not $regexResult.Success) {
        Write-Error "Illegal path: $Path"
        return $false
    } 
    
    
    $provider   = $regexResult.Groups['PROVIDER']
    $drive      = $regexResult.Groups['DRIVE']
    $pathspec   = $regexResult.Groups['PATH'].Value
    $isAbsolute = $provider.Success -or $drive.Success
    If (-not $isAbsolute -and ($Type -eq "Absolute")) {
        Write-Error "Wanted absolute path, but is relative: $Path"
        return $false
    }
    
    If ($provider.Success) {
        $provider = $provider.Value
        
        $providerRegex = "^(Microsoft\.PowerShell\.Core\\)?Registry"
        If (-not ($provider -match $providerRegex)) {
            Write-Error ( 
                "Unsupported provider ""$provider"" in path ""$Path"".`n" +
                "Must be either ""Microsoft.PowerShell.Core\Registry"" " +
                "or ""Registry"".")
            return $false
        } 
        
        $maxParts  = 2
        $pathParts = $pathspec.Split(`
            '/\', $maxParts, [StringSplitOptions]::RemoveEmptyEntries)
        If ($pathParts.length -lt 2) {
            Write-Error (
                "The given absolute does not specify at least a registry " +
                "hive and the name of a value.`nPath: $Path"
            )
            return $false
        }
        
        $actualHive = $pathParts[0]
        If (-not ($script:knownRegistryHives -contains $actualHive)) {
            Write-Error (
                "Unknown registry hive ""$actualHive"" in absolute path " +
                "specification: $Path")
            return $false
        }
        
    } ElseIf ($drive.Success) {
        $drive = $drive.Value
    
        If (-not ($script:knownRegistryDrives -contains $drive)) {
            $supportedDrivesString = [String]::Join(', ', $supportedDrives)
            Write-Error (
                "Unsupported PSDrive ""$drive"" in path ""$Path"".`n" +
                "Valid drives are: $supportedDrivesString. " +
                "See New-PSDrive for for details."
            )
            return $false
        }
        
        If (-not $pathspec.StartsWith("\") -and -not $pathspec.StartsWith("/")) {
            Write-Error (
                "PSDrive not followed by directory separator:`n" +
                "Should be: ${drive}:\$pathspec`n" +
                "Was      : $pathspec")
            return $false
        }
    }
    
    If ($isAbsolute -and ($Type -eq "Relative")) {
        Write-Error "Wanted relative path, but is absolute: $Path"
        return $false
    }
    
    return $true
}


<#
.SYNOPSIS
    Splits a registry path into its key and value part.
    
.OUTPUT
    An object with properties "Key" and "Value" if the path is valid, or $null
    otherwise.
#>
function Split-RegistryPath {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [String] $Path
    )
    $regexResult = $registryPathRegex.Match($Path)
    If (-not $regexResult.Success) {
        Write-Error "Illegal path: $Path"
        return $null
    }
    
    return @{
        Key   = $regexResult.Groups['PROVIDERORDRIVE'].Value + `
            $regexResult.Groups['KEY'].Value
        Value = $regexResult.Groups['VALUE'].Value
    }    
}


<#
.SYNOPSIS
    Mounts all local users' registry hives and invokes a callback for each of
    them.
    
.DESCRIPTION
    Invokes a callback for each of the local users' registry hives. The registry
    hives are loaded and unloaded if necessary.
    
.PARAMETER action
    The callback to be invoked for each user registry hive visited. The variable
    $hkuPath points to the root key of the current registry hive.
    
.OUTPUT
    None.
#>
function Edit-AllLocalUserProfileHives {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [ScriptBlock] $Action,
        
        [Parameter(Mandatory=$false)]
        [Alias("NoDefault", "NoDefaultProfile", "SkipDefault")]
        [Switch] $SkipDefaultProfile = $false,
        
        [Parameter(Mandatory=$false)]
        [Alias("AlsoHKEY_LOCAL_MACHINE")]
        [Switch] $AlsoHklm = $false
    )
    # List of profiles for which the sessions are to be imported
    $machineSidPrefix = "S-1-5-21"
    $profiles = Get-WmiObject win32_userprofile | ?{
        -not $_.Special -and $_.SID.StartsWith($machineSidPrefix) -and $_.LocalPath
    } 
    If (-not $SkipDefaultProfile) {
        $profiles +=  @{ SID=".DEFAULT" }
    }    
    
    _Init-ProgressBarId
    $ProgressBarState       = @{
        activity = "Importing registry image to user profile hives..."
        status   = "Initializing..."
        current  = 0
        max      = $profiles.Count
    }
    If ($AlsoHklm) {
        $ProgressBarState.max++
    }
    
    ForEach ($p in $profiles) {
        $hkuPath  = "Registry::\HKEY_USERS\$($p.SID)"
        $loadPath = $null
        
        Try {
            If (-not (Test-Path $hkuPath)) {
                $ntuserFile  = Join-Path $p.LocalPath "ntuser.dat"
                $hkuPath    += ".tmp"
                $loadPath    = $hkuPath -replace "^Registry::\\HKEY_USERS","HKU"
                
                $ProgressBarState.status = `
                    "Loading $ntuserFile as $loadPath."
                _Update-Progress $ProgressBarState -noIncrease
                
                Try {
                    $lastError = $null
                
                    # http://stackoverflow.com/a/35980675
                    $result = & cmd /c reg.exe load $loadPath $ntuserFile '2>&1' | Out-String
                    
                    If ($LASTEXITCODE -ne 0) {
                        $lastError = $result
                    }
                } Catch {
                    $lastError = "$_ - $result"
                }

                If ($lastError) {
                     Write-Error (
                        "Failed to load user profile registry hive: " +
                        "$loadPath`n$lastError")
                }
            }
            
            $ProgressBarState.status = `
                "Processing user profile hive: $hkuPath"
            _Update-Progress $ProgressBarState -noIncrease
            
            & $Action | Out-Null
            
            _Update-Progress $ProgressBarState
        } Finally {
            If ($loadPath) {
                $maxRetries = 10
                $lastError  = "dummy"
                
                For ($retry = 0; $retry -lt $maxRetries -and $lastError; $retry++) {
                    $lastError = $null
                    
                    $ProgressBarState.status = `
                        "Trying to unload $loadPath ($($retry+1)/$maxRetries)."
                    _Update-Progress $ProgressBarState -noIncrease
                    
                    # Ensure that there are no pending references that could fail
                    # the unload operation
                    [GC]::Collect()
                    [GC]::WaitForPendingFinalizers()
                    
                    Try {
                        # http://stackoverflow.com/a/35980675
                        $result = & cmd /c reg.exe unload $loadPath '2>&1' | Out-String
                        If ($LASTEXITCODE -ne 0) {
                            $lastError = $result
                        }
                    } Catch {
                        $lastError = "$_ - $result"
                    }

                    If ($lastError) {
                        Write-Verbose `
                            "Retrying ($($retry+2)/$maxRetries): $lastError"
                        Start-Sleep -Milliseconds 100
                    }
                }
            }
        }
    }
    
    If ($AlsoHklm) {
        $hkuPath = "Registry::HKEY_LOCAL_MACHINE\"
        
        $ProgressBarState.status = `
                "Processing local machine hive: $hkuPath"
        _Update-Progress $ProgressBarState -NoIncrease
        
        & $Action | Out-Null
    }
    
    $ProgressBarState.status = `
        "Done processing user profile hives."
    _Update-Progress $ProgressBarState
}
Set-Alias Edit-HKU Edit-AllLocalUserProfileHives


<#
.SYNOPSIS
    Format a string or boolean as powershell code.
    
.DESCRIPTION
    Converts a string or boolean into a string that can converted back with
    the Invoke-Expression cmdlet.
    
.OUTPUT
    A string that can be passed to the Invoke-Expression cmdlet.
    
#>
function _Format-ValueAsCode {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        [Object] $Value
    )
    
    If ($Value -eq $null) {
        return '$null'
    } ElseIf ($Value -eq $true) {
        return '$true'
    } ElseIf ($Value -eq $false) {
        return '$false'
    } ElseIf ($Value.GetType() -eq [String]) {
        return """$Value"""
    }
    
    Write-Error "Unknown value: $Value"
}


<#
.SYNOPSIS
    Ask for confirmation.

.DESCRIPTION
    Shows an interactive confirmation prompt asking the user to confirm the
    current operation.
    
    By default, the user can choose between yes and no. When $SkipMessage is
    defined, the user can also choose to skip the operation.
    
    These actions are performed depending on the user's choice:
        Yes : $true is returned
        No  : Depending on the $ErrorActionPreference an error is raised. $false
              is returned independently. No is the preselected choice.
        Skip: $null is returned
        
.PARAMETER Message
    The confirmation message to be printed.
    
.PARAMETER Title
    OPTIONAL - An optional title for the confirmation dialog.
    
.PARAMETER YesMessage
    OPTIONAL - Changes the default description of the "yes" choice.
    
.PARAMETER NoMessage
    OPTIONAL - Changes the default description of the "no" choice.
    
.PARAMETER SkipMessage
    OPTIONAL - If set, a skip choice with the given description is added to the
    confirmation dialog.
    
.PARAMETER DefaultChoice
    OPTIONAL - Change the preselected default choice. By default "No" is
    preselected.
    
.OUTPUT
    $true if "Yes" has been chosen. $false if "No" has been chosen. $null if
    "Skip" has been chosen.
    
#>
function _Read-Confirmation {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [String] $Message,
        
        [Parameter(Mandatory=$false)]
        [String] $Title = "Please confirm:",
        
        [Parameter(Mandatory=$false)]
        [String] $YesMessage = "Continue with the requested operation.",
        
        [Parameter(Mandatory=$false)]
        [String] $NoMessage = "Abort the requested operation.",
        
        [Parameter(Mandatory=$false)]
        [String] $SkipMessage = $null,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Yes", "No", "Skip")]
        [String] $DefaultChoice = "No"
    )
    
    $yes = [System.Management.Automation.Host.ChoiceDescription]::new(
        "&Yes", $YesMessage)
    $no  = [System.Management.Automation.Host.ChoiceDescription]::new(
        "&No", $NoMessage)
    $options = @( $yes, $no )
    
    $defaultIdx = 1
    If ($defaultChoice -eq "Yes") {
        $defaultIdx = 0
    }
    
    If ($SkipMessage) {
        $options += [System.Management.Automation.Host.ChoiceDescription]::new(
            "&Skip", $SkipMessage)
            
        If ($defaultChoice -eq "Skip") {
            $defaultIdx = 2
        }
    }
    
    $options = [System.Management.Automation.Host.ChoiceDescription[]]$options
    $result = $host.ui.PromptForChoice($Title, $Message, $Options, $defaultIdx)

    Switch ($result)
    {
        0 { return $true }
        1 { 
            Write-Error "The requested operation has not been confirmed."
            return $false 
        }
        2 { return $null }
    }
}

function _Init-ProgressBarId() {
    $pId = Get-Variable -Scope 1 -Name ProgressBarId `
        -ErrorAction SilentlyContinue
    If (-not $pId) {
        Set-Variable -Scope 1 -Name ProgressBarId -Value 0
    }
}

function _Update-Progress($pState, [switch]$noIncrease, [switch]$completed) {
    If (-not $noIncrease) {
        $pState.current++
    }
    If ($pState.current -gt $pState.max) {
        $pState.max = $pState.current
    }
    
    $percent = $pState.current / $pState.max * 100
    
    If ($pState.status) {
        Write-Progress -Activity $pState.Activity `
            -Id $ProgressBarId -ParentId ($ProgressBarId - 1) `
            -PercentComplete $percent `
            -Status $pState.status -Completed:$completed
    } Else {
        Write-Progress -Activity $pState.Activity `
            -Id $ProgressBarId -ParentId ($ProgressBarId - 1) `
            -PercentComplete $percent -Completed:$completed
    }
}