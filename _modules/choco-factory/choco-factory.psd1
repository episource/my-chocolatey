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


@{

# Script module or binary module file associated with this manifest.
RootModule = 'choco-factory.psm1'

# Version number of this module.
ModuleVersion = '2016.10.01'

# ID used to uniquely identify this module
GUID = 'ff3deb25-4873-4bd2-9bfc-71fdddd7df14'

# Author of this module
Author = 'Philipp Serr'

# Company or vendor of this module
CompanyName = 'episource'

# Copyright statement for this module
Copyright = ''

# Description of the functionality provided by this module
Description = @"
A collection of cmdlets that build self-contained chcolatey packages based on
templates and the latest software version available.
"@

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing
# this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to
# importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
#FormatsToProcess = @()

# Modules to import as nested modules of the module specified in
# RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module
FunctionsToExport = '*'

# Cmdlets to export from this module
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = @()

# Aliases to export from this module
AliasesToExport = '*'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess.
# This may also contain a PSData hashtable with additional module metadata used
# by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in
        # online galleries.
        Tags = @('chocolatey', 'update')

        # A URL to the license for this module.
        LicenseUri = 'https://opensource.org/licenses/MIT'

        # A URL to the main website for this project.
        # ProjectUri = ''

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = @"
v2016.10.01 - Make New-Package's VersionString parameter optional.
            - Add support for static nuspec templates without accompanying 
              _build.ps1 script
            - Fix New-Package's progress bar when VirusTotal.com virus scanning
              has been disabled
            - Make default PrepareFilesHook behavior available via a new 
              Import-PackageResource cmdlet
v2016.09.02 - Don't fail if the checksum has been set to $null or an array with
              fewer checksums than the number of provided file urls. A verbose
              message is written instead if no checksum has been provided for a
              file.
v2016.09.01 - Fix ConvertTo-SortedByVersion, so that input passed as argument
              instead of via the pipeline is received properly
v2016.08.01 - Initial version
"@

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default
# prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

