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
# The MaximumXxxCount preference variables have been omited, as they should
# always be set in global scope.
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
    
.PARAMETER AdditionalPreferences
    A list of additional (custom) preference variables to be imported. The key
    is the name of the variable, the value is the default value to be used if
    the variable is not found within the caller's scope.

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
    Param(
        [Parameter(Mandatory=$false)] [HashTable] $AdditionalPreferences = @{}
    )
    
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
    
    Foreach ($preference in ($preferenceVariables + $AdditionalPreferences.Keys)) {
        # Only import a caller's preference if it has not been set explictly
        # (common parameter or local/script scope variable)
        If (-not (_Get-LocalDefinition $sessionState $preference)) {
            $callerVar = _Get-LocalDefinition `
                $callingCmdletSessionState $preference
            
            If ($callerVar) {
                $sessionState.PSVariable.Set($callerVar.Name, $callerVar.Value)
                
                Write-Verbose "Imported: $($callerVar.Name)"
            } ElseIf($AdditionalPreferences.ContainsKey($preference)) {
                $sessionState.PSVariable.Set($preference,
                    $AdditionalPreferences.$preference)
            }
        }
    }
}

# Retrieves the PSVariable with name $varName if defined locally or in script
# scope (relative to $sessionState). Otherwise a falselike value is returned.
function _Get-LocalDefinition($sessionState, $varName) {
    # A script cmdlet inherits variables from global and script scope only.
    # To test whether a variable has been overwritten in local or script scope,
    # it is removed temporarily from the global scope. If it vanishes from the
    # calling cmdlet's scope, too, it has not been overwritten. Otherwise the
    # variable was defined in local or script scope.
    
    Try {
        $globalValue = Get-Variable -Scope global -Name $varName -ValueOnly `
            -ErrorAction Stop
    } Catch {
        # Return the local variable's description
        return $sessionState.PSVariable.Get($varName)
    }
    
    Remove-Variable -Scope global -Name $varName
    $localVar  = $sessionState.PSVariable.Get($varName)
    Set-Variable -Scope global -Name $varName -Value $globalValue
    
    return $localVar    
}

Export-ModuleMember -Function Import-CallerPreference