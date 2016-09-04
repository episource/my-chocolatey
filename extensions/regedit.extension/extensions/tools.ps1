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
function _ForEach-HKU {
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
    
    ForEach ($p in $profiles) {
        $hkuPath  = "Registry::\HKEY_USERS\$($p.SID)"
        $loadPath = $null
        
        Try {
            If (-not (Test-Path $hkuPath)) {
                $ntuserFile  = Join-Path $p.LocalPath "ntuser.dat"
                $hkuPath    += ".tmp"
                $loadPath    = $hkuPath -replace "^Registry::\\HKEY_USERS","HKU"
                
                Write-Verbose "Loading $ntuserFile as $loadPath."
                $result = & reg.exe load $loadPath $ntuserFile | Out-String
            }
            
            Write-Verbose "Processing user profile registry: $hkuPath"
            & $Action
        } Finally {
            If ($loadPath) {
                $lastError = "dummy"
                For ($retry = 0; $retry -lt 10 -and $lastError; $retry++) {
                    $lastError = $null
                    Write-Verbose "Trying to unload $loadPath."
                    
                    # Ensure that there are no pending references that could fail
                    # the unload operation
                    [GC]::Collect()
                    [GC]::WaitForPendingFinalizers()
                    
                    Try {
                        $result = & reg.exe unload $loadPath | Out-String
                    } Catch {
                        Write-Verbose "Retrying: $_"
                        $lastError = $_
                        Start-Sleep -Milliseconds 50
                    }
                }
                
                If ($lastError) {
                    Write-Error (
                        "Failed to unload user profile registry:`n" +
                        "$result`n$lastError")
                }
            }
        }
    }
    
    If ($AlsoHklm) {
        $hkuPath = "Registry::HKEY_LOCAL_MACHINE\"
        & $Action
    }
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