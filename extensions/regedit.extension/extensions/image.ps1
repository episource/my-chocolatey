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


<#
.SYNOPSIS
    Flattens a registry image by collapsing nested hash tables.
    
.DESCRIPTION
    Converts any supported registry image in a flat registry image. The
    definition of a flat registry image and all other types of registry image
    can be found in the description of the Import-Registry cmdlet.
    
    Besides converting the registry image, this cmdlet also checks if all value
    types are supported by Import-Registry and if any registry entry has two 
    conflicting definitions. 
    
    The result is returned as SortedDictionary: Each subkey level is sorted
    alphabetically with values coming before subkeys.
    
    An optional ParentKey path can be passed to the cmdlet. This path is 
    prepended to every registry path in the image.
    
.PARAMETER Image
    The registry image to be converted (any type).
    
.PARAMETER ParentKey
    OPTIONAL - This path is prepended to every registry path in the resulting
    image.
    
.PARAMETER

    
.OUTPUT
    A flat registry image (see description of the Import-Registry cmdlet).
    
#>
function ConvertTo-FlatRegistryImage {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Alias("Data","KeyValuePairs")]
        [System.Collections.IDictionary] $Image,
        
        [Parameter(Mandatory=$false)]
        [String] $ParentKey = $null
    )
    Begin {
        # Use an up-to-date list of registry drives when validating registry
        # paths => See also Test-RegistryPathValidity
        Sync-KnownRegistryDrives
    }
    Process {
        # Performance is better when adding values to an unsorted dictionary
        # first and sorting them add the end
        $flatImage   = `
            [System.Collections.Generic.Dictionary[String, Object]]::new()
            
        $imgPathType = 'Relative'
        If ($ParentKey) {
            $ParentKey = $ParentKey.TrimEnd('/\') + '\'
        
            If ($ParentKey.Contains(':')) {
                $imgPathType = 'Absolute'
            }
        } ElseIf ($Image.Count -gt 0) {
            $firstKey = $Image.Keys | Select-Object -First 1
            If ($firstKey.Contains(':')) {
                $imgPathType = 'Absolute'
            }
        }
        
        $inputQueue = [System.Collections.Queue]::new()
        $inputQueue.Enqueue(@{ image = $Image; parentKey = $ParentKey})
            
        While ($inputQueue.Count -gt 0) {
            $input = $inputQueue.Dequeue()
            
            ForEach ($entry in $input.image.GetEnumerator()) {
                If ($input.ParentKey) {
                    $path = $input.ParentKey + $entry.Key
                } Else {
                    $path = $entry.Key
                }
            
                Try {
                    $regValue = [RegistryValue]$entry.Value
                } Catch {
                    $rawValue = $entry.Value
                    $typeName = $rawValue.GetType().FullName
                    Write-Error `
                        "Unsupported value <$path=$rawValue> ($typeName).`n$_"
                }
                
                If ($regValue.isKey) { # Expand subkey
                    $inputQueue.Enqueue(@{
                        image     = $regValue.value
                        parentKey = $path.TrimEnd('/\') + '\'
                    })
                } Else { # Append property
                    If (-not (Test-RegistryPathValidity $path `
                            -Type $imgPathType)) {
                        Write-Error "Illegal registry path: $path"
                        return
                    }
                    If ($flatImage.ContainsKey($path)) {
                        $curValueExpression = [PowershellExpression]::Get( `
                            $flatImage[$path])
                        $newValueExpression = [PowershellExpression]::Get( `
                            $regValue.value)
                        Write-Error (
                            "Registry entry $path has conflicting " + 
                                "definitions:`n" +
                            "Conflict: $newValueExpression`n" +
                            "     Was: $curValueExpression")
                    } Else {
                       $flatImage[$path] = $regValue.value
                    }
                }
            }
        }
        
        $flatImage = `
            [System.Collections.Generic.SortedDictionary[String, Object]]::new(
                $flatImage,
                [RegistryPathComparer]::new())
        return $flatImage
    }
} 


<#
.SYNOPSIS 
    Converts a registry image to a nested registry image.
    
.DESCRIPTION
    Converts any type of registry image to a nested registry image. The
    resulting registry image can be either compressed or uncompressed depending
    on the $Compress parameter.
    
    See the description of the Import-Registry cmdlet for a detailed description
    of the different registry image types.
    
.PARAMETER Image
    The registry image (any type) to be converted.
    
.PARAMETER Compress
    OPTIONAL - Select whether the nested image is to be compressed. See the
    description of the Import-Registry cmdlet for details.
    
.OUTPUT
    A nested registry image (see description of the Import-Registry cmdlet).
    
#>
function ConvertTo-NestedRegistryImage {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [Alias("Data","KeyValuePairs")]
        [System.Collections.IDictionary] $Image,
        
        [Parameter(Mandatory=$false)]
        [Switch] $Compress = $false
    )
    Process {
        # Normalize and check registry image by converting it to a flat image
        # first!
        $flatImage = ConvertTo-FlatRegistryImage $Image
        
        # keep order of normalized flatImage => OrderedDictionary
        $nestedImage = `
            [System.Collections.Specialized.OrderedDictionary]::new()
            
            
        ForEach ($fullPath in $flatImage.Keys) {
            If (-not ($fullPath -match `
                    "^(?<PROVIDER>(?:[^:]+::)?)(?<PATH>.+)$")) {
                Write-Error "Unsupported path: $fullPath"
            }
            $provider = $Matches.PROVIDER
            $path = $Matches.PATH
        
            If ($Compress) {
                $nodeName = Split-Path -Parent $path
                $leafName = Split-Path -Leaf $path
                If ($nodeName) {
                    $path = @( $nodeName, $leafName )
                } Else {
                    $path = @( $leafName )
                }
            } Else {
                $path = $path.Split('/\')
            }
            
            # Always merge the provider prefix with the first path component
            # => We want @{ "Registry::HKEY_LOCAL_MACHINE" = ... } instead of
            #    @{ "Registry::" = @{ "HKEY_LOCAL_MACHINE" = ...} }
            $path[0] = $provider + $path[0]
            
            $node = $nestedImage
            For ($i = 0; $i -lt $path.length; $i++) {
                $isInnerNode = $i -lt ($path.length - 1)
                $nodeName    = $path[$i]
                
                If ($isInnerNode) {
                    $nextNode = $node[$nodeName]
                    If (-not $nextNode) {
                        $nextNode = [System.Collections.Specialized.OrderedDictionary]::new()
                        $node.$nodeName = $nextNode
                    } ElseIf (-not [System.Collections.IDictionary]. `
                            IsInstanceOfType($nextNode)) {
                        $existingPath  = [String]::Join("\", $path[0..$i])
                        $existingValue = [PowershellExpression]::Get($nextNode)
                        $conflictValue = $flatImage.$fullPath
                        Write-Error (
                            "Nested images do not support a subkey and a " +
                            "value with the same name side by side.`n" +
                            "Conflicting value: $fullPath = $conflictValue`n" +
                            "   Existing value: $existingPath = $existingValue")
                        break
                    }
                    $node = $nextNode
                } Else {
                    # No need to check for an existing entry first: The 
                    # underlying flat image is sorted such that values come 
                    # before subkeys. Therefore conflicts between subkeys and 
                    # values with the same name can only happen when a subkey 
                    # is added. This is handled above.
                    $node.$nodeName = $flatImage.$fullPath
                }
                
            }
        }    
        
        return $nestedImage
    }
} 


<#
.SYNOPSIS
    Formats the registry image as powershell source code.
    
.DESCRIPTION
    Formats the registry image as powershell source code for manual editing
    or reading with Invoke-Expression.
    
.PARAMETER Image
    The image to be formated as powershell source code.
    
.PARAMETER OneLine
    OPTIONAL - Limit the source code to one line. Do not add line breaks and
    indentation.
    
.PARAMETER Indent
    OPTIONAL - Internal usage only.
    
.PARAMETER FirstIndent
    OPTIONAL - Internal usage only.
    
.OUTPUT
    Powershell source code.
    
#>
function Format-PowershellRegistryImage {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Alias("Data","KeyValuePairs")]
        [System.Collections.IDictionary] $Image,
        
        [Parameter(Mandatory=$false)]
        [Switch] $OneLine = $false,
        
        [Parameter(Mandatory=$false)]
        [Int] $Indent = 0,
        
        [Parameter(Mandatory=$false)]
        [Int] $FirstIndent = $null
    )
    Begin {
        function Format-Line($str, $myIndent = $Indent, $lastLine = $false) {
            If ($lastLine) {
                $linesep = ""
            } ElseIf ($OneLine -and $str.EndsWith('{')) {
                $linesep = $linesep.Trim(";")
            }
        
            $indent = ""
            For ($i = 0; $i -lt $myIndent; $i++) {
                $indent += " "
            }
            
            return $indent + $str + $linesep
        }
        
        $linesep = "`n"
        If ($OneLine) {
            $linesep = "; "
        }
        If (-not $FirstIndent -and $FirstIndent -ne 0) {
            $FirstIndent = $Indent
        }
    }
    Process {
        $outString  = Format-Line "@{" $FirstIndent
        
        If (-not $OneLine) {
            $Indent    += 4     
        }
        
        $expressions  = [System.Collections.Specialized.OrderedDictionary]::new()
        $maxKeyLength = 0
        ForEach ($entry in $Image.GetEnumerator()) {
            $key     = [PowershellExpression]::Get($entry.Key)
            $value   = [RegistryValue]$entry.Value
            
            If ($value.isKey) {
                $expression = Format-PowershellRegistryImage `
                    -Image $value.Value -FirstIndent 0 -Indent $Indent `
                    -OneLine:$OneLine
            } Else {
                $expression = [PowershellExpression]::Get($value)
            }
            
            $expressions.$key = $expression
            
            If (-not $OneLine) {
                $maxKeyLength     = [Math]::Max($maxKeyLength, $key.length) 
            }
        }
        
        ForEach ($exp in $expressions.GetEnumerator()) {
            $outString += Format-Line ("{0,-$maxKeyLength} = {1}" -f @(
                $exp.Key, $exp.Value ) )
        }
        
        If (-not $OneLine) {
            $Indent -= 4     
        }
        $outString += Format-Line "}" -lastLine $true
        
        return $outString
    }
}