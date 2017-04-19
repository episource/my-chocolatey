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


# Export functions matching the $publicFuncs pattern, others are private
# Note: The list of exported functions might be further restricted by a module
# manifest file (*.psd1)

# functions that start with a capital letter are exported
$publicFuncs = '^[A-Z]+'

$builtins = Get-ChildItem Function:\*
Get-ChildItem "$PSScriptRoot\*.ps1" | % { . $_  }
$all = Get-ChildItem Function:\*

$funcs = Compare-Object $builtins $all |
    Select-Object -ExpandProperty InputObject |
    Select-Object -ExpandProperty Name
$funcs | ? { $_ -cmatch $publicFuncs } | % { Export-ModuleMember -Function $_ }

# Export all aliases (if any)
Export-ModuleMember -Alias *