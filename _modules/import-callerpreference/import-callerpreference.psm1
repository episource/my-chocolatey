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
$ErrorActionPreference = "Stop"


# Variables copied from about_Preference_Variables (posh 5.0)
$preferenceVariables = @(
    'ConfirmPreference'             
    'DebugPreference'               
    'ErrorActionPreference'         
    'ErrorView'                     
    'FormatEnumerationLimit'        
    'InformationPreference'         
    'LogCommandHealthEvent'         
    'LogCommandLifecycleEvent'      
    'LogEngineHealthEvent'          
    'LogEngineLifecycleEvent'       
    'LogProviderLifecycleEvent'     
    'LogProviderHealthEvent'        
    'MaximumAliasCount'             
    'MaximumDriveCount'             
    'MaximumErrorCount'             
    'MaximumFunctionCount'          
    'MaximumHistoryCount'           
    'MaximumVariableCount'          
    'OFS'                           
    'OutputEncoding'                
    'ProgressPreference'            
    'PSDefaultParameterValues'      
    'PSEmailServer'                 
    'PSModuleAutoLoadingPreference' 
    'PSSessionApplicationName'      
    'PSSessionConfigurationName'    
    'PSSessionOption'               
    'VerbosePreference'             
    'WarningPreference'             
    'WhatIfPreference'              
)

<#
.SYNOPSYS
    Take over preference values from a caller's scope.

.DESCRIPTION
    This helper function can be used in script module functions to inherit the
    preference variables from their caller. This is the default behavior for
    compiled cmdlets, but script modules don't have this feature built-in.

.EXAMPLE
    function Receive-PreferencesExample {
        [CmdletBinding()]
        Param()
        
        Import-CallerPreference
        # ...
    }
    
.EXAMPLE
    None
    
.OUTPUTS
    None. No pipeline output is produced.
    
.LINK
    https://blogs.technet.microsoft.com/heyscriptingguy/2014/04/26/weekend-scripter-access-powershell-preference-variables/
#>
function Import-CallerPreference {
    [CmdletBinding()]
    Param()
    
    # Note: $PSCmdlet.SessionState gets information about "where the cmdlet
    #       is running" - that is information about the caller's context!
    $sessionState              = $PSCmdlet.SessionState
    $callingCmdlet             = $sessionState.PSVariable.GetValue("PSCmdlet")
    $callingCmdletSessionState = $callingCmdlet.SessionState
    
    If ($sessionState.Module -eq $null) {
        Write-Error "Import-CallerPreference not invoked from within a script module function."
    }
    If ($callingCmdlet -eq $null) {
        Write-Error "Import-CallerPreference not invoked by an advanced function ([CmdletBinding()])."
    }
    
    Foreach ($preference in $preferenceVariables) {
        # Only import a caller's preference if it has not been set explictly
        # (common parameter or local/script scope variable)
        If (-not $sessionState.PSVariable.Get($preference)) {
            $callerValue = $callingCmdletSessionState.PSVariable. `
                GetValue($preference)
            $sessionState.PSVariable.Set($preference, $callerValue)
        }
    }
}

Export-ModuleMember -Function Import-CallerPreference