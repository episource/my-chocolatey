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

import-module -force -name $PSScriptRoot/extensions/regedit.psm1



$image =@{
    A = @{ B = @{ BV1 = 10 } }
    C = @{ CV1 = 11 }
    X = @{ XV1 = 12 }
    Temp = @{
        Demo = @{
            DwordA = 1
            DwordB = [Int]2
            DwordC = [Int32]3
            QwordA = [Long]4
            QwordB = [Int64]5
            String = "Hallo Welt!"
            Binary = [Byte[]]@(1,2,3,4)
            MultiString = [String[]]@("string1", "string2", "string3")
            ExpandString = New-ExpandString "string-with-%variable%"
        }
        "(Default)" = "Ein String"
        Level = "Temp"
    }
    "(Default)" = 1
    Level = "Top level"
    Dword = 1
    TempDemo = 3
    #"Temp\Demo" = 4
}

$testImage = @{
    "test" = $image
}


$flatImage = ConvertTo-FlatRegistryImage $image
$nestedImage = ConvertTo-NestedRegistryImage $image
$nnImage = ConvertTo-NestedRegistryImage $image -Compress
$ffImage = ConvertTo-FlatRegistryImage $flatImage

#$export = Export-Registry "HKEY_CURRENT_USER\Test"  -recurse 
#ConvertTo-NestedRegistryImage $export -compress
