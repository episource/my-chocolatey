# Copyright 2019 Philipp Serr (episource)
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

function _Format-Hash($Hash) {
    $obj = New-Object psobject -Property $Hash
    return _Format-Object $obj
}

function _Format-Object($Obj) {
    $str = $Obj | Format-List | Out-String
    return $str.Trim()
}

function _Get-PropExists($obj,$prop) {
    # requires strict mode
    try {
        $x = $obj.$prop
        return $true
    } catch {
        return $false
    }
}

function _Get-ContentLength($url) {
    try {
        $res = (Invoke-WebRequest $url -Method Head).Headers.'Content-Length'
        return [int]$res
    } catch {
        return $null
    }
}

function _Get-Field($data, $query) {
    try {
        &$query $data
    } catch {
        write-debug "an error occured: $_"
        return $null
    }
}