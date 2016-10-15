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
    Add a new ConEmu task configuration or replace an exiting configuration.
    
.DESCRIPTION
    Add a new ConEmu task configuration. An existing configuration with the same
    name is overwritten.
    
    The SortMode parameter specifies how to sort the expanded task list. By
    default tasks added with this cmdlet are sorted by the custom configuration
    option _SortKey and are placed before tasks configured via the the ConEmu 
    gui.
    
.PARAMETER Task
    The task to be added. Consider adding a custom _SortKey configuration option
    to control where the new task is added.
    
.PARAMETER SortMode
    OPTIONAL - By default the order of existing tasks without _SortKey 
    specified is preserved (SortMode = SortKeyFirst). Tasks with a _SortKey
    specified are sorted by 1) _SortKey 2) Name and come before tasks without
    _SortKey.
    
    Note: "the order of exisiting tasks is preserved" means that the list of
    all tasks is sorted by there Id first. However, the Id can be changed via
    the configuration Action. Tasks without Id (newly added tasks) and possibly
    also tasks defining a _SortKey (depending on the sort mode) are assigned a
    special $autoId (see Action). This $autoId is chosen such that (depending 
    on the sort mode) these tasks come before or after tasks with an explicit 
    Id.
    
    Other options are:
        Name:
            Reorder tasks by name (alphabetically ascending).
        Preserve:
            See PreserveOrPrependBySortKey:
        PreserveOrPrependBySortKey:
            The order of existing tasks (with or without _SortKey) is preserved.
            New tasks are prepended and sorted by 1) _SortKey 2) Name.
        PreserveOrAppendBySortKey:
            The order of existing tasks (with or without _SortKey) is preserved.
            New tasks are appended and sorted by 1) _SortKey 2) Name.
        PreserveOrPrependByName:
            The order of existing tasks (with or without _SortKey) is preserved.
            New tasks are prepended and sorted by their Name.
        PreserveOrAppendByName:
            The order of existing tasks (with or without _SortKey) is preserved.
            New tasks are appended and sorted by their Name.
        SortKeyFirst:
            See SortKeyFirstPreserveOthers
        SortKeyFirstPreserveOthers:
            The order of existing tasks without _SortKey is preserved. New tasks
            and tasks with _SortKey are prepended and sorted by 1) _SortKey 
            2) Name.
        SortKeyLast:
            See SortKeyLastPreserveOthers
        SortKeyLastPreserveOthers:
            The order of existing tasks without _SortKey is preserved. New tasks
            and tasks with _SortKey are appended and sorted by 1) _SortKey 
            2) Name.
        SortKeyFirstAndName:
            All tasks are sorted by 1) _SortKey 2) Name. Tasks without _SortKey
            come last.
        SortKeyLastAndName:
            All tasks are sorted by 1) _SortKey 2) Name. Tasks without _SortKey
            come first.
            
.PARAMETER OnlyCurrentUser
    OPTIONAL - Apply configuration to current user only. By default it is
    applied to all local user profiles.
    
.OUTPUT
    None.
    
#>   
function Add-ConEmuTask {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [System.Collections.IDictionary] $Task,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Name", "Preserve", "PreserveOrPrependBySortKey",
                "PreserveOrAppendBySortKey", "PreserveOrPrependByName",
                "PreserveOrAppendByName", "SortKeyFirst",
                "SortKeyFirstPreserveOthers", "SortKeyLast", 
                "SortKeyLastPreserveOthers", "SortKeyFirstAndName",
                "SortKeyLastAndName")]
        [String] $SortMode = "SortKeyFirstPreserveOthers",
    
        [Parameter(Mandatory=$false)]
        [Switch] $OnlyCurrentUser = $false
    )
    End {
        $newTasks = $Input
        If ($newTasks.Count -eq 0) {
            $newTasks = @() + $Task
        }
        
        $updateAction = {
            ForEach ($task in $newTasks) {
                $_[$task.Name] = @{
                    Config = $task
                }
            }
        }
        
        _Update-TaskConfigurationImpl -Action $updateAction `
                -SortMode $SortMode -OnlyCurrentUser:$OnlyCurrentUser
    }
}