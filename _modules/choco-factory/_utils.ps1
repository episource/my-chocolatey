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

$_templateExtension       = '.nuspec'

# https://github.com/mojombo/semver.org/issues/59#issuecomment-57884619
# Note: - BUILD is currently not supported by chocolatey
#         => https://github.com/NuGet/NuGet2/pull/59
#       - The PKGRELEASE component is not part of the semver specification, but
#         has been added by nuget
$_semverRegex = @"
(?x)^
(?<MAJOR>(?:
    0|(?:[1-9]\d*)
))
\.
(?<MINOR>(?:
    0|(?:[1-9]\d*)
))
\.
(?<PATCH>(?:
    0|(?:[1-9]\d*)
))
(?:\.
(?<REVISION>(?:
    0|(?:[1-9]\d*)
)))?
(?:-(?<PRERELEASE>
    [0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*
))?
(?:\+(?<BUILD>
    [0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*
))?
$
"@

$_nupkgRegex = $_semverRegex -replace '\^','^(?<pkgId>[^\.]+(?:\.[^0-9]+)?)\.(?<pkgVersion>' -replace '\$',').nupkg$'

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

function _Set-Var($var, $value) {
    $name  = $var -replace "^[a-zA-Z0-9]+:"
    $scope = "local"
    If ($name -ne $var) {
        $scope = $var -replace ":.+$"
    }

    Set-Variable -Scope $scope -Name $name -Value $value
}

function _Get-AbsolutePath($path) {
    if( -not ( [System.IO.Path]::IsPathRooted($path) ) )
    {
        $path = Join-Path (Get-Location) $path
    }
    return [IO.Path]::GetFullPath($path)
}

function _Write-DbgNoConfirm($text) {
    $DebugPreference = $DebugPreference -replace "Inquire","Continue"
    
    # carriage return adds empty lines!?
    Write-Debug ($text -replace "`r")
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

function _Format-Hash($Hash) {
    $obj = New-Object psobject -Property $Hash
    return _Format-Object $obj
}

function _Format-Object($Obj) {
    $str = $Obj | Format-List | Out-String
    return $str.Trim()
}

function _Get-CallingScriptDirOrCurrentDir {
    $mi = Get-Variable -Scope 1 -Name "MyInvocation" -ValueOnly
    If (-not $mi.ScriptName) {
        return Get-Location
    } Else {
        return Split-Path -Parent $mi.ScriptName
    }
}

function _Get-StringHash($String, $Algorithm="MD5") {
    $sb       = New-Object System.Text.StringBuilder
    $bytes    = [System.Text.Encoding]::UTF8.GetBytes($String)
    $hashfunc = [System.Security.Cryptography.HashAlgorithm]::Create($Algorithm)
    
    ForEach ($byte in $hashfunc.ComputeHash($bytes)) {
        $sb.Append($byte.ToString("x2")) | Out-Null
    }
    
    return $sb.ToString()
}
