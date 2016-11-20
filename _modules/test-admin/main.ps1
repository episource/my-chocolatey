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

Import-Module import-callerpreference


<#
.SYNOPSIS
    Tests whether the current user has administrative privileges.

.DESCRIPTION
    Returns whether the current user has administrative privileges. Does not
    raise an error or throw.
    
.OUTPUT
    $true if the current user has administrative privileges, otherwhise $false.  
#>
function Test-Admin {
    [CmdletBinding()]
    param()

    Try {
        . $PSScriptRoot/_requires-admin.ps1
    } Catch {
        return $false
    }
    
    return $true
}

<#
.SYNOPSIS
    Throws if the current user does not have administrative privileges.
   
.OUTPUT
    None.
#>
function Assert-Admin {
    [CmdletBinding()]
    param()

    Try {
        . $PSScriptRoot/_requires-admin.ps1
    } Catch {
        Throw "The current user does not have administrative privileges."
    }
}