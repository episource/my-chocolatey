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
    Reorders existing ConEmu tasks.
    
.DESCRIPTION
    Reorders existing ConEmu tasks.
    
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
        SortKeyFirst:
            See SortKeyFirstPreserveOthers
        SortKeyFirstPreserveOthers:
            The order of tasks without _SortKey is preserved. Tasks with
            _SortKey come first and are sorted by 1) _SortKey 2) Name.
        SortKeyLast:
            See SortKeyLastPreserveOthers
        SortKeyLastPreserveOthers:
            The order of tasks without _SortKey is preserved. Tasks with
            _SortKey come last and are sorted by 1) _SortKey 2) Name.
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
function Update-ConEmuTaskOrder {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)]
        [ValidateSet("Name", "SortKeyFirst", "SortKeyFirstPreserveOthers",
                "SortKeyLast", "SortKeyLastPreserveOthers", 
                "SortKeyFirstAndName", "SortKeyLastAndName")]
        [String] $SortMode = "SortKeyFirstAndName",
    
        [Parameter(Mandatory=$false)]
        [Switch] $OnlyCurrentUser = $false
    )
    End {       
        # No need to add or remove tasks
        $noop = { }
        
        _Update-TaskConfigurationImpl -SortMode $SortMode `
                -Action $noop -OnlyCurrentUser:$OnlyCurrentUser
    }
}