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
.DESCRIPTION
    This method imports a registry image to the windows registry.

    Values with relative paths are imported below $ParentKey. If no $ParentKey
    is given, relative paths are resolved against the provider prefix
    "Registry::". Therefore, without $ParentKey, the paths of the registry image
    must consist of at least two parts with the first part being the name of a 
    registry hive (e.g. "HKEY_LOCAL_MACHINE\SomeValue" is resolved as
    "Registry::HKEY_LOCAL_MACHINE\SomeValue"; in contrast "SomeValue" alone 
    wouldn't be a valid path).
    
    Values with absolute paths are imported to the absolute path defined in the
    registry image.
    
    This module supports registry values of the following kinds:
        Binary data (REG_BINARY):
            Any value of type Byte[] is converted to the registry data type
            REG_BINARY.
            Example: @{ "BinaryValue" = [Byte[]]@(1,2,3,4) }
        32-Bit Number (REG_DWORD):
            Any value of type Int is converted to the registry data type
            REG_DWORD.
            Example: @{ "DwordA" = 0x00000001; "DwordB" = [Int]0x10000000 }
        64-Bit Number (REG_QWORD):
            Any value of type Long is converted to the registry data type
            REG_QWORD.
            Example: @{ "Qword" = [Long]0x0000000000000001 }
        String:
            Any String is converted to the registry data type REG_SZ.
            Example: @{ "String" = "Hello World!" }
        Array of Strings:
            Any String[] is converted to the registry data type REG_MULTI_SZ.
            Example: @{ "MultiString" = [String[]]@("Hello","World","!") }
        String with references to environment variables (REG_EXPAND_SZ):
            A String with references to environment variables that are expanded
            when the value is retrieved can be created with the New-ExpandString
            cmdlet.
            Example: @{ "ExpandString" = New-ExpandString "The path: %PATH%" }
                    

    There are four types of registry images supported by this powershell 
    module:
        - Flat images
        - Nested images (non-compressed)
        - Nested images (compressed)
        - Mixed images
        
    All image types must obey general rules listed at the end of this section.
        
    The purpose of a registry image is to define a set of registry values. Any
    type of registry image can be converted to either a flat image or one of the
    nested image flavors. Empty keys might not be preserved during these
    conversions and may be ignored the cmdlets Import-Registry and
    Export-Registry.
        
    The windows registry consists of keys and values. A key is a container
    object that can contain other (sub)keys or values. A value is a named
    property of a key that stores content of several types (no subkeys - see
    below for a list of types supported by this module). A value can't exist
    without a parent key. The registry is organized in so called hives 
    (HKEY_LOCAL_MACHINE, HKEY_USERS, ...) which are predefined root keys. All
    other keys and values live below one of these hives.
    
    In the context of this module a value is identified by a "path" (comparable
    to a file system path). A path is a string consisting of parts, that are
    separated by the characters "\" "/". Each part is the name of either a value
    or a (sub)key. All parts of a path but the last are names of (sub)keys.
    Depending on the type of registry image and the content assigned to a path,
    the last part of a path is either the name of a value or a (sub)key. A path
    consisting of only a single part is called "simple name". If a path starts
    with either a provider prefix (Registry::,
    Microsoft.PowerShell.Core\Registry::) or a registry PSDrive (HKLM:\, ...)
    it is called an absolute path. Other paths are considered relative.
    
    
    FLAT IMAGE
    A flat image is represented by an IDictionary instances. The key of each
    item is the path of a registry value, while the dictionary value specifies 
    the value's content (that is no subkeys!). All paths must be either absolute
    or relative to a common parent. Absolute and relative paths cannot be mixed.
    There is no supported way to define empty keys in a flat image.
    
    Example (relative paths with implicit parent):
    @{
        "SomeValue"             = 0x00000001
        "Key\SubKey\OtherValue" = 0x10000000
    }
    Example (absolute paths):
    @{
        "Registry::HKEY_LOCAL_MACHINE\SomeValue" = 0x00000001
        "HKLM:\Key\SubKey\OtherValue"            = 0x10000000
    }
    
    
    NESTED IMAGE (Non-Compressed)
    A nested image is represented by nested IDictionary instances. The key of
    each dictionary item must be a simple name. If the dictionary value is a
    nested IDictionary instance, the dictionary item represents a subkey. The
    dictionary key is then the name of a subkey, which in turn is the parent key
    of all items in the nested IDictionary which can be either values or
    subkeys. The path of a value consists of all of its parent keys' names
    followed by the name of the value (e.g. value "SomeValue" in the nested
    image @{ Key = @{ SubKey = @{ SomeValue = "REG_SZ" } } } is identified by
    the path "Key\SubKey\SomeValue"). To represent absolute paths, the keys in
    the topmost IDictionary instance must be a registry provider Prefix followed
    by a name of a registry hive (e.g. "Registry::HKEY_LOCAL_MACHINE") or a
    registry PSDrive prefix (e.g. "HKLM:"). If so, the topmost IDictionary may
    only contain subkey items ( @{ "Registry::HKEY_LOCAL_MACHINE" = @{ ... };
    "HKCU:" = @{ ... } }), no value items ( @{ "HKLM:" = @{ ... };
    "SomeValue" = 2 } is illegal).
    
    Example (relative paths with implicit parent):
    @{
        "SomeValue"          = 0x00000001
        "Key" = @{
            "SubKey" = @{
                "OtherValue" = 0x10000000
            }
        }
    }
    Example (absolute paths):
    @{
        "Registry::HKEY_LOCAL_MACHINE" = @{
            "SomeValue"          = 0x00000001
        }
        "HKLM:" = @{
            "Key" = @{
                "SubKey" = @{
                    "OtherValue" = 0x10000000
                }
            }
        }
    }
    
    
    NESTED IMAGE (Compressed)
    A nested image is represented by at most two layers of nested IDictionary
    instances. The topmost IDictionary represents all values of the implicit
    parent key (if any) and all subkeys. Subkeys are identified by their full
    path. Their dictionary value is a nested IDictionary defining the values of
    the subkey. The nested dictionary may not define subkeys. The subkeys in the
    toplevel dictionary may use absolute or relative paths. In case of absolute
    paths, no values can be defined at the toplevel as there's no parent key.
   
    Example (relative paths with implicit parent):
    @{
        "SomeValue"      = 0x00000001
        "Key\SubKey" = @{
            "OtherValue" = 0x10000000
        }
    }
    Example (absolute paths):
    @{
        "Registry::HKEY_LOCAL_MACHINE" = @{
            "SomeValue"  = 0x00000001
        }
        "HKLM:\Key\SubKey" = @{
            "OtherValue" = 0x10000000
        }
    }
    
    
    MIXED IMAGE
    A mixed image combines any of the three image types explained above. It is
    especially suited for manually creating memory images. The general rules 
    defined below are of special importance when creating mixed images.
    
    
    GENERAL RULES
    These rules must be obeyed by all types of registry images. The rules are of
    special importance for mixed images, as the other image types enforce most
    of these rules. Compliance with these rules is checked by
    ConvertTo-FlatRegistryImage.
        1. Each value must be defined uniquely. That is, there must more than
           one defintion for a single (expanded) path.
        2. After converting any image to a flat image, all entries must have 
           either absolute paths or relative paths. Absolute and relative paths
           must not be mixed.   
    Note, that it is possible to have a value and a subkey with the same name
    side by side. However, this is feature of the windows registry is supported
    by flat images only. Such a image might not be convertable to a nested
    image.
    Example: @{ "Key\Item\Value" = 0; "Key\Item" = 1 }
           
    
    CREATE REGISTRY IMAGES MANUALLY
    It's good to start with an export of an existing registry subtree. The
    export can be converted to the form that's best suited for manual editing
    (probably NESTED) and finally exported to powershell code using
    Format-PowershellRegistryImage.
    
.PARAMETER Image
    The registry image to be imported (any type).
    
.PARAMETER ParentKey
    OPTIONAL - The registry is imported below the given parent key. The registry
    image must use relative paths if a parent key is specified.

.PARAMETER Force
    OPTIONAL - Overwrite existing values.
    
    If $Rebuild is used, $Force disables the confirmation dialog.
    
.PARAMETER Rebuild
    OPTIONAL - Each registry key contained in the image is rebuilt before
    importing its values and subkeys. THIS DELETES ALL EXISTING VALUES AND
    SUBKEYS! RECURSIVELY! USE WITH CARE!
    
.OUTPUT
    None.
    
#>
function Import-Registry {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Alias("Data","KeyValuePairs")]
        [System.Collections.IDictionary] $Image,
    
        [Parameter(Mandatory=$false)] 
        [String] $ParentKey = $null,
        
        [Parameter(Mandatory=$false)]
        [Switch] $Force = $false,
        
        [Parameter(Mandatory=$false)]
        [Switch] $Rebuild = $false
    )
    Process {
        $flatImage    = ConvertTo-FlatRegistryImage $Image
        _Import-RegistryImpl -FlatImage $flatImage -ParentKey $ParentKey `
            -Force:$Force -Rebuild:$Rebuild
    }
}

<#
.SYNOPSIS
    Private implemenation of the Import-Registry cmdlet.
    
.DESCRIPTION
    See Import-Registry.
    
.PARAMETER FlatImage
    A flat registry image preprocessed with ConvertTo-FlatRegistryImage. All
    paths must be absolute if no $ParentKey is given, or relative otherwise.
    
.OUTPUT
    None.
#>
function _Import-RegistryImpl {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [System.Collections.IDictionary] $FlatImage,
    
        [Parameter(Mandatory=$false)] 
        [String] $ParentKey = $null,
        
        [Parameter(Mandatory=$false)]
        [Switch] $Force = $false,
        
        [Parameter(Mandatory=$false)]
        [Switch] $Rebuild = $false
    )
    
    $defaultValue = $null
    $noExpandVars = `
        [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
        
    # Use an up-to-date list of registry drives when validating registry paths.
    # => See also Test-RegistryPathValidity
    Sync-KnownRegistryDrives
        
    If ($ParentKey) {
        $imgPathType = 'Relative'
    
        $ParentKey = $ParentKey.TrimEnd('/\') + '\'
        If (-not (Test-RegistryPathValidity $ParentKey -Type Absolute)) {
            # Test-RegistryPathValidity uses Write-Error internally
            return
        }
    } Else {
        $imgPathType = 'AbsoluteNoHive'
    }
    
    # Test first entry only - ConvertTo-FlatRegistryImage ensures all entries
    # use the same path type
    If ($Image.Count -gt 0) {
        $firstKey = $Image.Keys | Select-Object -First 1
        If (-not (Test-RegistryPathValidity $firstKey -Type $imgPathType)) {
            # Test-RegistryPathValidity uses Write-Error internally
            return
        }
    }
    
    $lastKeyPath  = $null
    ForEach ($entry in $FlatImage.GetEnumerator()) {
        If ($ParentKey) {
            $path = $ParentKey + $entry.Key
        } Else {
            $path = $entry.Key
        }
        If (-not $path.Contains(":")) {
            $path = "Registry::$path"
        }
        
        $splitPathResult = Split-RegistryPath $path
        If (-not $splitPathResult) {
            # Split-RegistryPath uses Write-Error internally
            continue
        } Else {
            $keyPath       = $splitPathResult.Key
            
            # Both PowerShell and .Net API are used below: Both expect different
            # names for the default value.
            # PowerShell - $poshValueName: "(Default)"
            # .Net       - $netValueName : ""
            $poshValueName = $splitPathResult.Value
            $netValueName  = $poshValueName
            If ($netValueName -eq "(Default)") {
                $netValueName = ""
            }
        }
        
        If ($lastKeyPath -ne $keyPath) {
            $key = New-RegistryKey $keyPath -Force:$Force -Rebuild:$Rebuild 
        } Else {
            $key = New-RegistryKey $keyPath
        }
        
        $lastKeyPath = $keyPath
        $newRegValue = [RegistryValue]$entry.Value
        $curValue    = $key.GetValue( `
            $netValueName, $defaultValue, $noExpandVars)
        If (-not $Force -and $curValue -ne $defaultValue) {
            $curKind            = $key.GetValueKind($netValueName)
            If ($curKind -eq `
                    [Microsoft.Win32.RegistryValueKind]::ExpandString) {
                $curValue = [ExpandString]$curValue
            }
            
            $curValueExpression = [PowershellExpression]::Get($curValue)
            $newValueExpression = [PowershellExpression]::Get($newRegValue)
            
            If (($curKind -ne $newRegValue.valueKind) `
                -or (Compare-Object $curValue $newRegValue.value)
            ) {
               
                Write-Error ( 
                    "A value with the same name already exists " +
                    "and has a different content or value kind.`n" +
                    "New: $path=$newValueExpression`nWas: $curValueExpression")
            } Else {
                Write-Verbose (
                    "A value with the same name already exists, but has the " +
                    "same content and value kind.`n" +
                    "Value: $path=$newValueExpression")
            }
        } Else {
            $key | New-ItemProperty -Force -Name $poshValueName `
                -Value $newRegValue.value -PropertyType $newRegValue.valueKind |
            Out-Null
        }
    }
}


<#
.SYNOPSIS
    Imports the given registry image into every local user's registry hive.
    
.DESCRIPTION
    For every local user profile, the cmdlet loads the corresponding user
    registry hive (if necessary) and imports the registry image within that
    hive.
    
    The registry image may contain relative paths only.
    
.PARAMETER Image
    The registry image to be imported (any type).
    
.PARAMETER ParentKey
    OPTIONAL - The registry is imported below the given parent key.
    
.PARAMETER SkipDefaultProfile
    OPTIONAL - Don't import the registry image to the default user profile's
    registry hive. The default user profile's registry hive is used to
    initialize the registry of a new local user.

.PARAMETER AlsoHklm
    OPTIONAL - Also import the registry image below HKEY_LOCAL_MACHINE.

.PARAMETER Force
    OPTIONAL - See Import-Registry.
    
.PARAMETER Rebuild
    OPTIONAL - See Import-Registry.
    THIS DELETES ALL EXISTING VALUES AND SUBKEYS! RECURSIVELY! USE WITH CARE!

.OUTPUT
    None.

#>
function Import-UserRegistry {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Alias("Data","KeyValuePairs")]
        [System.Collections.IDictionary] $Image,
        
        [Parameter(Mandatory=$false)] 
        [String] $ParentKey = $null,
        
        [Parameter(Mandatory=$false)]
        [Alias("NoDefault", "NoDefaultProfile", "SkipDefault")]
        [Switch] $SkipDefaultProfile = $false,
        
        [Parameter(Mandatory=$false)]
        [Alias("AlsoHKEY_LOCAL_MACHINE")]
        [Switch] $AlsoHklm = $false,
        
        [Parameter(Mandatory=$false)]
        [Switch] $Force = $false,
        
        [Parameter(Mandatory=$false)]
        [Switch] $Rebuild = $false
    )
    Process {
        $flatImage = ConvertTo-FlatRegistryImage $Image
        _Import-UserRegistryImpl -FlatImage $flatImage -ParentKey $ParentKey `
            -SkipDefaultProfile:$SkipDefaultProfile -AlsoHklm:$AlsoHklm `
            -Force:$Force -Rebuild:$Rebuild
    }
}


<#
.SYNOPSIS
    Private implemenation of the Import-UserRegistry cmdlet.
    
.DESCRIPTION
    See Import-Registry.
    
.PARAMETER FlatImage
    A flat registry image preprocessed with ConvertTo-FlatRegistryImage. All
    paths must be relative.
    
.OUTPUT
    None.
#>
function _Import-UserRegistryImpl {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [System.Collections.IDictionary] $FlatImage,
        
        [Parameter(Mandatory=$false)] 
        [String] $ParentKey = $null,
        
        [Parameter(Mandatory=$false)]
        [Alias("NoDefault", "NoDefaultProfile", "SkipDefault")]
        [Switch] $SkipDefaultProfile = $false,
        
        [Parameter(Mandatory=$false)]
        [Alias("AlsoHKEY_LOCAL_MACHINE")]
        [Switch] $AlsoHklm = $false,
        
        [Parameter(Mandatory=$false)]
        [Switch] $Force = $false,
        
        [Parameter(Mandatory=$false)]
        [Switch] $Rebuild = $false
    )
       
    Edit-AllLocalUserProfileHives -SkipDefaultProfile:$SkipDefaultProfile `
        -AlsoHklm:$AlsoHklm -Action {
        If ($ParentKey) {
            $ParentKey = $hkuPath + '\' + $ParentKey
        } Else {
            $ParentKey = $hkuPath
        }
        
        _Import-RegistryImpl -ParentKey $ParentKey -FlatImage $FlatImage `
            -Force:$Force -Rebuild:$Rebuild
    }
}


<#
.SYNOPSIS
    Create a registry key and all missing parent keys.
    
.DESCRIPTION
    New-RegistryKey creates a registry key and all missing parent keys in a safe
    manner. This is similiar to "New-Item -Force", but an existing subtree or
    value won't be replaced.
    
    Note about New-Item -Force:
    The powershell built-in cmdlet New-Item with the -Force parameter also
    creates any missing parent key. However, if path points to an existing key,
    it is replaced by an empty key. All subkeys and values will be gone. Note
    however, that the registry supports values and subkeys with the same name
    side by side.
    
.PARAMETER Path
    The absolute path of a registry key to be created. If the path does not
    start with a PSDrive or registry provider prefix, the provider prefix
    "Registry::" is prepended automatically.
    
.PARAMETER Rebuild
    OPTIONAL - Replace $Path with an empty key if it already exists. USE WITH
    CARE! ALL SUBKEYS AND VALUES WILL BE LOST! RECURSIVELY!
    
.PARAMETER Force
    OPTIONAL - Don't ask for confirmation when recreating the registry key (see
    $Rebuild).
    
.OUTPUT
    An object representing the newly created registry key. Null in case of an
    error (ErrorAction=*Continue or cancelled confirmation dialog).
    
#>
function New-RegistryKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [String] $Path,
        
        [Parameter(Mandatory=$false)]
        [Switch] $Rebuild = $false,
        
        [Parameter(Mandatory=$false)]
        [Switch] $Force = $false
    )
    Process {
        If (-not $Path.Contains(":")) {
            $Path = "Registry::$Path"
        }
        If (-not (Test-RegistryPathValidity $Path -Type AbsoluteNoHive)) {
            # Test-RegistryPathValidity uses Write-Error internally
            return $null
        }
        
        If (Test-Path $Path) {
            If ($Rebuild -and -not $Force) {
                $confirmation = _Read-Confirmation -ErrorAction Stop `
                    -Message `
                         "Rebuild $Path, deleting all subkeys and values?" `
                    -YesMessage `
                        "Rebuild the registry key!" `
                    -NoMessage `
                        "Stop it! Don't do anything!"
                        
                If (-not $confirmation) {
                    return $null
                }           
            }
        
            If (-not $Rebuild) {
                return Get-Item -LiteralPath $Path
            }
        }
        
        return New-Item -Force $Path
    }
}