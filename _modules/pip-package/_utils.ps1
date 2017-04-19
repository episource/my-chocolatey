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

function _Get-CallingScriptDirOrCurrentDir {
    $mi = Get-Variable -Scope 1 -Name "MyInvocation" -ValueOnly
    If (-not $mi.ScriptName) {
        return Get-Location
    } Else {
        return Split-Path -Parent $mi.ScriptName
    }
}

function _Get-Var($var, $default) {
    $name  = $var -replace "^[a-zA-Z0-9]+:"
    $scope = "local"
    If ($name -ne $var) {
        $scope = $var -replace ":.+$"
    }

    If (Test-Path "variable:${scope}:${name}") {
        $val = Get-Variable -Scope $scope -ValueOnly $name
        if ($val -ne $null) {
            return $val
        }
    }
    
    return $default
}

function _Normalize-Version($version) {
    $versionParts = $version.Split(".")
    while ($versionParts.Length -lt 3) {
        $versionParts += "0"
    }
    return [String]::Join(".", $versionParts)
}

function _Update-Progress($pState, [switch]$noIncrease, [switch]$completed) {
    If (-not $noIncrease) {
        $pState.current++
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