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
    Set ConEmu task flags.
    
.DESCRIPTION
    Updates the flags of matching ConEmu tasks.
    
.PARAMETER TaskName
    Name of the task to be removed.
    
.PARAMETER EnableRegex
    OPTIONAL - By default the TaskName is matched literally. This switch enables
    regular expression matching.
    
.PARAMETER SetDefaultTask
    OPTIONAL - Sets ($true) or unsets ($false) the "Default task for new 
    console" option. Note however, that there can be only one default task!

.PARAMETER SetDefaultShell
    OPTIONAL - Sets ($true) or unsets ($false) the "Default shell (Win+X)" 
    option. Note however, that there can be only one default shell!

.PARAMETER SetJumpList
    OPTIONAL - Sets ($true) or unsets ($false) the "Taskbar jump lists" option.
    (If set, the task appears in the taskbar jump list)

.PARAMETER SetToolbar
    OPTIONAL - Selects ($true) or deselects ($false) the task for inclusion in
    ConEmu's shortcut menu located in the toolbar.    
            
.PARAMETER OnlyCurrentUser
    OPTIONAL - Apply configuration to current user only. By default it is
    applied to all local user profiles.
    
.OUTPUT
    None.
    
#> 
function Set-ConEmuTaskFlags {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [String] $TaskName,
        
        [Parameter(Mandatory=$false)]
        [Switch] $EnableRegex = $false,
        
        [Parameter(Mandatory=$false)]
        [Object] $SetDefaultTask = $null,
        
        [Parameter(Mandatory=$false)]
        [Object] $SetDefaultShell = $null,
        
        [Parameter(Mandatory=$false)]
        [Object] $SetJumpList = $null,
        
        [Parameter(Mandatory=$false)]
        [Object] $SetToolbar = $null,
    
        [Parameter(Mandatory=$false)]
        [Switch] $OnlyCurrentUser = $false
    )
    End {
        $filters = $Input
        If ($filters.Count -eq 0) {
            $filters = @() + $TaskName
        }
        If (-not $EnableRegex) {
            $filters = @($filters | %{ "^" + [Regex]::Escape($_) + "$"})
        }
        
        # https://github.com/Maximus5/ConEmu/blob/v16.09.14/src/ConEmu/SetCmdTask.h#L33-L43
        $setDefaultTaskFlag  = 0x0001
        $setDefaultShellFlag = 0x0002
        $unsetJumpListFlag   = 0x0004
        $setToolbarFlag      = 0x0008
        
        $updateAction = {
            $isMatch = $false
            
            ForEach ($taskName in $_.Clone().Keys) {
                $config   = $_[$taskName].Config
                $oldFlags = $config.Flags 
            
                ForEach ($f in $filters) {
                    If ($taskName -match $f) {
                        $isMatch = $true
                    
                        If ($SetDefaultTask) {
                            $config.Flags = `
                                $config.Flags -bor $setDefaultTaskFlag
                        } ElseIf ($SetDefaultTask -eq $false) {
                            $config.Flags = `
                                $config.Flags -band -bnot $setDefaultTaskFlag
                        }
                        
                        If ($SetDefaultShell) {
                            $config.Flags = `
                                $config.Flags -bor $setDefaultShellFlag
                        } ElseIf ($SetDefaultShell -eq $false) {
                            $config.Flags = `
                                $config.Flags -band -bnot $setDefaultShellFlag
                        }
                        
                        If ($SetJumpList) {
                            $config.Flags = `
                                $config.Flags -band -bnot $unsetJumpListFlag
                        } ElseIf ($SetJumpList -eq $false) {
                            $config.Flags = `
                                $config.Flags -bor $unsetJumpListFlag
                        }
                        
                        If ($SetToolbar) {
                            $config.Flags = `
                                $config.Flags -bor $setToolbarFlag
                        } ElseIf ($SetToolbar -eq $false) {
                            $config.Flags = `
                                $config.Flags -band -bnot $setToolbarFlag
                        }
                        
                        Continue
                    } Else {
                        # Note: Only one task can be default task/shell
                        If ($SetDefaultTask) {
                            $config.Flags = `
                                $config.Flags -band -bnot $setDefaultTaskFlag
                        }
                        If ($SetDefaultShell) {
                            $config.Flags = `
                                $config.Flags -band -bnot $setDefaultShellFlag
                        }
                    }
                }
                
                If ($oldFlags -ne $config.Flags) {
                    Write-Verbose ( `
                        "The flags of task '$taskName' have been changed: " + `
                        "$oldFlags -> $($config.Flags)")
                }
            }
            
            If (-not $isMatch) {
                Write-Warning "No task with matching name was found!"
            }
        }
        
        _Update-TaskConfigurationImpl -Action $updateAction `
                -SortMode "Preserve" -OnlyCurrentUser:$OnlyCurrentUser
    }
}