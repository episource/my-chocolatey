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
    Remove ConEmu tasks.
    
.DESCRIPTION
    Removes ConEmu task configurations matching the given name or regular
    rexpression.
    
.PARAMETER TaskName
    Name of the task to be removed.
    
.PARAMETER EnableRegex
    OPTIONAL - By default the TaskName is matched literally. This switch enables
    regular expression matching.
            
.PARAMETER OnlyCurrentUser
    OPTIONAL - Apply configuration to current user only. By default it is
    applied to all local user profiles.
    
.OUTPUT
    None.
    
#> 
function Remove-ConEmuTask {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [String] $TaskName,
        
        [Parameter(Mandatory=$false)]
        [Switch] $EnableRegex = $false,
    
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
        
        $updateAction = {
            $isMatch = $false
            
            ForEach ($taskName in $_.Clone().Keys) {
                ForEach ($f in $filters) {
                    If ($taskName -match $f) {
                        Write-Verbose "Removing task: $taskName"
                        $isMatch = $true
                        
                        $_.Remove($taskName)
                        
                        Continue
                    }
                }
            }
            
            If (-not $isMatch) {
                $filterNames = `
                    "'" + [String]::Join("', '", $filters) + "'"
                Write-Warning ( 
                    "No task with matching name ($filterNames) was found! " + `
                    "No task has been deleted.")
            }
        }
        
        _Update-TaskConfigurationImpl -Action $updateAction `
                -SortMode "Preserve" -OnlyCurrentUser:$OnlyCurrentUser
    }
}