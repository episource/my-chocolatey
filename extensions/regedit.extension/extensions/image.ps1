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
    
.OUTPUT
    A flat registry image (see description of the Import-Registry cmdlet).
    
#>
function ConvertTo-FlatRegistryImage {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [Alias("Data","KeyValuePairs")]
        [System.Collections.IDictionary] $Image,
        
        [Parameter(Mandatory=$false)]
        [String] $ParentKey = $null
    )
       
    $isAbsolute = $null
    $flatImage  = `
        [System.Collections.Generic.SortedDictionary[String, Object]]::new(
            [RegistryPathComparer]::new())
    function Add-RegEntry($fullPath, $value) {
        If (-not (Test-RegistryPathValidity $fullPath)) {
            Write-Error "Illegal registry path: $fullPath"
            return
        }
        If ($isAbsolute -eq $null) {
            Set-Variable -Scope 1 -Name "isAbsolute" `
                -Value $fullPath.Contains(":")
        }
        If ($isAbsolute -ne $fullPath.Contains(":")) {
            If ($isAbsolute) {
                Write-Error (
                    "The registry image already contains absolute paths. " +
                    "Can't add relative path:`n$fullPath")
            } Else {
                Write-Error (
                    "The registry image already contains relative paths. " +
                    "Can't add absolute path:`n$fullPath")
            }
            return
        }
    
        # Ensure that a registry entry is not defined twice (see
        # Import-Registry, General Rules: 1). However, values and subkeys with
        # the same name are supported side by side:
        # Bad : Key\Item\Value = 1
        #       Key\Item\Value = 2
        #       => a value shall not be specified twice (causes more confusion 
        #          than help)
        # Good: Key\Item\Value = 1
        #       Key\Item       = 2
        #       => Item is both a value of Key and a subkey of Key. This is
        #          supported by the windows registry.
        If ($flatImage.ContainsKey($fullPath)) {
            $currentValue = $flatImage.$fullPath
            Write-Error (
                "Registry entry $fullPath has conflicting definitions:`n" +
                "Conflict: $([PowershellExpression]::Get($value))`n" +
                "     Was: $([PowershellExpression]::Get($currentValue))")
        } Else {
            $flatImage.$fullPath = $value
        }
    }
    
    ForEach ($key in $Image.Keys) {
        $path = $key
        If ($ParentKey) {
            $path = Join-Path $ParentKey $key
        }
    
        Try {
            $regValue = [RegistryValue]$Image.$key
        } Catch {
            $rawValue = $Image.$key
            $typeName = $rawValue.GetType().FullName
            Write-Error "Unsupported value <$path=$rawValue> ($typeName).`n$_"
        }
        
        If ($regValue.isKey) { # Expand subkey
            $subtree = ConvertTo-FlatRegistryImage `
                -Image $regValue.value -ParentKey $path
            ForEach ($path in $subtree.Keys) {
                Add-RegEntry $path $subtree.$path
            }
        } Else { # Append property
            Add-RegEntry $path $regValue.value
        }
    }
    
    return $flatImage
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
        [Parameter(Mandatory=$true)]
        [Alias("Data","KeyValuePairs")]
        [System.Collections.IDictionary] $Image,
        
        [Parameter(Mandatory=$false)]
        [Switch] $Compress = $false
    )
    
    # Normalize and check registry image by converting it to a flat image first!
    $flatImage = ConvertTo-FlatRegistryImage $Image
    
    # keep order of normalized flatImage => OrderedDictionary
    $nestedImage = `
        [System.Collections.Specialized.OrderedDictionary]::new()
        
        
    ForEach ($fullPath in $flatImage.Keys) {
        If (-not ($fullPath -match "^(?<PROVIDER>(?:[^:]+::)?)(?<PATH>.+)$")) {
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
                        "Nested images do not support a subkey and a value " + `
                        "with the same name side by side.`n" +
                        "Conflicting value: $fullPath = $conflictValue`n" +
                        "   Existing value: $existingPath = $existingValue")
                    break
                }
                $node = $nextNode
            } Else {
                # No need to check for an existing entry first: The underlying
                # flat image is sorted such that values come before subkeys.
                # Therefore conflicts between subkeys and values with the same
                # name can only happen when a subkey is added. This is handled
                # above.
                $node.$nodeName = $flatImage.$fullPath
            }
            
        }
    }    
    
    return $nestedImage
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
        [Parameter(Mandatory=$true)]
        [Alias("Data","KeyValuePairs")]
        [System.Collections.IDictionary] $Image,
        
        [Parameter(Mandatory=$false)]
        [Switch] $OneLine = $false,
        
        [Parameter(Mandatory=$false)]
        [Int] $Indent = 0,
        
        [Parameter(Mandatory=$false)]
        [Int] $FirstIndent = $null
    )
    
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


<#
.SYNOPSIS
    Tests whether a registry path is a valid absolute or relative path.

.DESCRIPTION
    Tests whether a registry path is a valid absolute or relative path.
    
    Set the ErrorAction parameter to SilentlyContinue if only a boolean result
    should be returned without any error messages.
    
.OUTPUT
    $true if the path was found to be valid -or- otherwise $false.
    
#>
function Test-RegistryPathValidity {
	[CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [String] $Path,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Any", "Absolute", "Relative")]
        [String] $Type = "Any"
    )
    
    $pathRegex  = `
        "^(?:(?:(?<PROVIDER>[^:]+)::)|(?:(?<DRIVE>[^:]+):))?(?<PATH>[^:]+)$"
    If (-not ($Path -match $pathRegex)) {
        Write-Error "Illegal path: $Path"
        return $false
    } 
    
    $provider   = $Matches['PROVIDER']
    $drive      = $Matches['DRIVE']
    $pathspec   = $Matches['PATH']
    $isAbsolute = $provider -or $drive
    If (-not $isAbsolute -and ($Type -eq "Absolute")) {
        Write-Error "Wanted absolute path, but is relative: $Path"
        return $false
    }
    
    If ($provider) {
        $providerRegex = "^(Microsoft\.PowerShell\.Core\\)?Registry"
        If (-not ($provider -match $providerRegex)) {
            Write-Error ( 
                "Unsupported provider ""$provider"" in path ""$Path"".`n" +
                "Must be either ""Microsoft.PowerShell.Core\Registry"" " +
                "or ""Registry"".")
            return $false
        } 
        
        $pathParts = $pathspec.Trim('/\').Split('/\')
        If ($pathParts.length -lt 2) {
            Write-Error (
                "The given absolute does not specify at least a registry " +
                "hive and the name of a value.`nPath: $Path"
            )
            return $false
        }
        
        $knownHives = Get-ChildItem Registry:: | %{ $_.Name }
        $actualHive = $pathParts[0]
        If (-not ($knownHives -contains $actualHive)) {
            Write-Error (
                "Unknown registry hive ""$actualHive"" in absolute path " +
                "specification: $Path")
            return $false
        }
        
    } ElseIf ($drive) {
        $supportedDrives = Get-PSDrive | ?{ $_.Provider.Name -eq "Registry" } |
            Select-Object -Expand Name
        If (-not ($supportedDrives -contains $drive)) {
            $supportedDrivesString = [String]::Join(', ', $supportedDrives)
            Write-Error (
                "Unsupported PSDrive ""$drive"" in path ""$Path"".`n" +
                "Valid drives are: $supportedDrivesString. " +
                "See New-PSDrive for for details."
            )
            return $false
        }
        
        If (-not $pathspec.StartsWith("\") -and -not $pathspec.StartsWith("/")) {
            Write-Error (
                "PSDrive not followed by directory separator:`n" +
                "Should be: ${drive}:\$pathspec`n" +
                "Was      : $pathspec")
            return $false
        }
    }
    
    If ($isAbsolute -and ($Type -eq "Relative")) {
        Write-Error "Wanted relative path, but is absolute: $Path"
        return $false
    }
    
    return $true
}