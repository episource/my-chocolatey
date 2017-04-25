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

#IMPORTANT: this script must be saved as UTF-8 with BOM byte-order-mark!
#(powershell treats the file as ascii without BOM)
Set-StrictMode -Version latest
$ErrorActionPreference = "Stop"


<#
.SYNOPSIS
    Re-package a pip package from pypi as chocolatey package compatible with 
    the python packages from repository my-chocolatey.

.DESCRIPTION
    This function prepares the nuspec package description and all related
    content based on a pip package from pypi.
        
.PARAMETER PythonName
    Name of the python dependency for which the package is to be created.
    
.PARAMETER PythonVersion
    Required python version in the format of a nuspec dependency node:
    https://docs.microsoft.com/de-de/nuget/create-packages/dependency-versions
               
.PARAMETER PypiPackageName
    Pypi package name.
    
.PARAMETER ChocoPackageMaintainer
    The package maintainer
       
.PARAMETER PostInstallScript
    OPTIONAL - Powershell code to be executed after successful installation.
    
    The variables $pythonToolsDir and $pythonExe are available to the script
    code.
    
.PARAMETER PreUninstallScript
    OPTIONAL - Powershell code to be executed prior to uninstall.
    
    The variables $pythonToolsDir and $pythonExe are available to the script
    code.
    
.PARAMETER AdditionalDependencies
    OPTIONAL - Additional dependencies as list of maps with items  Id, Version.
       
.PARAMETER BuildRoot
    OPTIONAL - A temporary working directory is created below the build rooThis
    directory. This parameter is also passed to the New-Package cmdlet from the
    choco-factory module. See New-Package for details.
       
    This parameter defaults to $global:CFBuildRoot if defined. Otherwise, if the
    cmdlet is invoked by a script, the default value is 
    "$(Directory with script)/_build". If invoked from the command line, the
    default is "$(Get-Location)/_build".
    
.PARAMETER OutDir
    OPTIONAL - This parameter is passed to the New-Package cmdlet from the
    choco-factory module. See New-Package for details.
    
.PARAMETER IfNotInRepository
    OPTIONAL - This parameter is passed to the New-Package cmdlet from the
    choco-factory module. See New-Package for details.
    
.PARAMETER NoScan
    OPTIONAL - This parameter is passed to the New-Package cmdlet from the
    choco-factory module. See New-Package for details.
    
.PARAMETER VTApiKey
    OPTIONAL - This parameter is passed to the New-Package cmdlet from the
    choco-factory module. See New-Package for details.
           
.PARAMETER Debug
    OPTIONAL - Don't delete the working directory "$BuildRoot/<id>-<version>" on
    exit. Also activates debug output going beyond Verbose mode.
           
.OUTPUT
    The path of the exported nupkg as FileInfo object. If new new package is
    build due to the IfNotInRepository option, the existing package is returned
    instead.
           
.EXAMPLE
    TODO
#>
function New-PypiPackage {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [String] $PythonName,
        
        [Parameter(Mandatory=$True)]
        [String] $PythonVersion,
    
        [Parameter(Mandatory=$True)]
        [String] $PypiPackage,
        
        [Parameter(Mandatory=$True)]
        [String] $ChocoPackageMaintainer,
        
        [Parameter(Mandatory=$false)]
        [String] $PostInstallScript = "",
        
        [Parameter(Mandatory=$false)]
        [String] $PreUninstallScript = "",
        
        [Parameter(Mandatory=$false)]
        [HashTable[]] $AdditionalDependencies = @(), 
        
        [Parameter(Mandatory=$false)]
        [String] $BuildRoot = (_Get-Var 'global:CFBuildRoot' `
            '$(_Get-CallingScriptDirOrCurrentDir)/_build'),
                
        [Parameter(Mandatory=$false)]
        [String] $OutDir = $null,
            
        [Parameter(Mandatory=$false)]
        [String] $IfNotInRepository = (_Get-Var 'global:CFRepository' $null),
        
        [Parameter(Mandatory=$false)]
        [Switch] $NoScan = $null,
        
        [Parameter(Mandatory=$false)]
        [String] $VTApiKey = $null
    )   
    Import-CallerPreference -AdditionalPreferences @{ ProgressBarId = 0 }
    $debug = $DebugPreference -ne 'SilentlyContinue'
    
    # prepare progress bar
    $ProgressBarId          = $ProgressBarId + 1
    $ProgressBarState       = @{
        activity = "Preparing python-pip package '$PypiPackage for $PythonName'"
        status   = "Initializing..."
        current  = 0
        max      = 6
    }
    _Update-Progress $ProgressBarState -noIncrease
    
    
    #
    # Determine context
    $pythonDir = Select-BuildDependency -Name "$PythonName" -Version $PythonVersion
    $pythonExe = "$pythonDir/tools/python.exe"
    
    $pypiJsonUrl = "https://pypi.python.org/pypi/$PypiPackage/json"
    $pypiJsonRaw = Invoke-WebRequest -UseBasicParsing $pypiJsonUrl
    $pypiJson = ConvertFrom-Json $pypiJsonRaw

    $pkgName = "$PythonName-pip-$($PypiPackage.ToLowerInvariant())"
    $templateDir = "$BuildRoot/$pkgName.template"
    
    $pipCacheDir = _Get-Var 'global:CFCacheDir' $null
    $deletePipCache = -not $debug -and -not $pipCacheDir
    If ($pipCacheDir) {
        $pipCacheDir = Join-Path $pipCacheDir "pip"
    } Else {
        $pipCacheDir = Join-Path $BuildRoot "pip.tmp"
    }
    
    #
    # Abort early if package has already been built
    # Note: Check if the newest available version has already been built
    # Note: This might not be the version that would be build due to platform
    # Note: => heuristic
    $existingPkgPath = "$IfNotInRepository/$pkgName.$($pypiJson.info.version).nupkg"
    If (Test-Path $existingPkgPath) {
        _Update-Progress $ProgressBarState -completed
        return Get-Item $existingPkgPath
    }
    
    Try {
        #
        # Prepare working area
        _Update-Progress $ProgressBarState
        
        If (-not (Test-Path $pipCacheDir)) {
            New-Item -Path $pipCacheDir -ItemType Directory | Out-Null
        }
    
        If (Test-Path $templateDir) {
            Remove-Item -Path $templateDir -Recurse -Confirm
        }
        New-Item -Path $templateDir -ItemType Directory | Out-Null
        
        #
        # Run pip to figure out dependencies and package version
        $ProgressBarState.status = "Running 'pip download $PypiPackage'"
        _Update-Progress $ProgressBarState
        
        $pipInfo = & $pythonExe -m pip download $PypiPackage -d $pipCacheDir -v --isolated
        If ($LastExitCode -ne 0) {
            Write-Error "Downloading pip package $PypiPackage failed!`n$([String]::Join("`n", $pipInfo))"
            return
        }
        
        $ProgressBarState.status = "Parsing pip output..."
        _Update-Progress $ProgressBarState
        
        $version = $null
        $files = @()
        $dependencies = @()
        ForEach ($line in $pipInfo) {
            Write-Verbose $line
            
            If (-not $version) {
                If ($line.StartsWith("Collecting") -and -not $line.StartsWith("Collecting $PypiPackage")) {
                    Write-Error "Failed to extract pypi package version from pip's output!`n$([String]::Join("`n", $pipInfo))"
                    return
                }
                
                If ($line -match "Using version (?<VERSION>(?:\d+\.){1,3}\d+) \(newest of versions:") {
                    $version = _Normalize-Version $Matches.VERSION
                }
            } ElseIf ($line -match "Collecting (?<PIPNAME>[a-zA-Z0-9\-_\.]+)(?:,?(?:(?:<(?<MAXVEREX>(?:\d+\.){1,3}\d+))|(?:<=(?<MAXVERIN>(?:\d+\.){1,3}\d+))|(?:>(?<MINVEREX>(?:\d+\.){1,3}\d+))|(?:>=(?<MINVERIN>(?:\d+\.){1,3}\d+))))*.*\(from $PypiPackage\)") {
                $depVer = ""
            
                If ($Matches['MINVERIN']) {
                    $depVer += "[" + $(_Normalize-Version $Matches.MINVERIN)
                } ElseIf ($Matches['MINVEREX']) {
                    $depVer += "(" + $(_Normalize-Version $Matches.MINVEREX)
                } Else {
                    $depVer += "["
                }
                
                $depVer += ","
                
                If ($Matches['MAXVERIN']) {
                    $depVer += $(_Normalize-Version $Matches.MAXVERIN) + "]"
                } ElseIf ($Matches['MAXVEREX']) {
                    $depVer += $(_Normalize-Version $Matches.MAXVEREX) + ")"
                } Else {
                    $depVer += "]"
                }
                
                If ($depVer -eq "[,]") {
                    $depVer = "[0.0.0,)"
                }
                $dependencies += "<dependency id=""$PythonName-pip-$($Matches.PIPNAME.ToLowerInvariant())"" version=""$depVer""/>"
            } ElseIf ($dependencies.Length -eq 0) {
                If ($line -match "Saved (?<FILEPATH>.+)$") {
                    $files += $Matches.FILEPATH
                } ElseIf ($line -match "File was already downloaded (?<FILEPATH>.+)$") {
                    $files += $Matches.FILEPATH
                }
            }
        }
        ForEach ($dep in $AdditionalDependencies) {
            $dependencies += "<dependency id=""$($dep.Id)"" version=""$($dep.Version)""/>"
        }
        
        $ProgressBarState.status = "Generating chocolatey template..."
        _Update-Progress $ProgressBarState
    
        #
        # Build nuspec
        $nuspec = @"
<?xml version="1.0"?>
<!-- Do not remove this test for UTF-8: if “Ω” doesn’t appear as greek uppercase omega letter enclosed in quotation marks, you should use an editor that supports UTF-8, not this one. -->
<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
  <metadata>
    <id>$pkgName</id>
    <version>$version</version>
    <authors>$($pypiJson.info.author)</authors>
    <owners>$ChocoPackageMaintainer</owners>
    
    <title>$PypiPackage for $PythonName</title>
    <summary>$($pypiJson.info.summary)</summary>
    <tags>admin python pip pypi</tags>
    
    <projectUrl>$($pypiJson.info.home_page)</projectUrl>
    $(If ($pypiJson.info.bugtrack_url) { "<bugTrackerUrl>" + $pypiJson.info.bugtrack_url + "</bugTrackerUrl>" })
    $(If ($pypiJson.info.docs_url) { "<docsUrl>" + $pypiJson.info.docs_url + "</docsUrl>" })
    
    <requireLicenseAcceptance>false</requireLicenseAcceptance>
    <description><![CDATA[$($pypiJson.info.description + "`nLicense:" + $pypiJson.info.license)]]></description>

    <dependencies>
      <dependency id="$PythonName" version="$PythonVersion"/>
      $([String]::Join("`n      ", $dependencies))
    </dependencies>
  </metadata>
  <files>
    <file src="tools\**" target="tools" />
  </files>
</package>
"@.Replace("@", "@@") # escape razor!

        # Important: utf-8 without bom!
        $utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($False)
        [IO.File]::WriteAllLines("$templateDir/$pkgName.nuspec", $nuspec, $utf8NoBomEncoding)
        
        #
        # Copy pip files to package
        $toolsDir = New-Item -Path "$templateDir/tools" -ItemType Directory
        $files | %{ Copy-Item -Path $_ -Destination $toolsDir }
        
        #
        # Build install+uninstall scripts
        $install = @"
Set-StrictMode -Version latest
`$ErrorAction = "Stop"
`$toolsDir = "`$(Split-Path -Parent `$MyInvocation.MyCommand.Definition)"

`$pythonName = "$PythonName"
`$pythonToolsDir = "`$toolsDir/../../$PythonName/tools/"
`$pythonExe = "`$pythonToolsDir/python.exe"

@( @{ VAR="VS90COMNTOOLS"; PATH="`$toolsDir/../../vcpython27/tools/common/tools" } ) | %{
    If (Test-Path -Type Container `$_.PATH) {
        `$absPath = [IO.Path]::GetFullPath(`$_.Path)
        [Environment]::SetEnvironmentVariable(`$_.VAR, `$absPath, [EnvironmentVariableTarget]::Process)
    }
}

& `$pythonExe -m pip install $PypiPackage -f `$toolsDir -U --force-reinstall --no-index --no-deps
If ($LastExitCode -ne 0) {
    Write-Error "pip did not succeed!"
}

$PostInstallScript
"@
        Add-Content -Path "$toolsDir/chocolateyInstall.ps1" -Value $install
        
        $unistall = @"
Set-StrictMode -Version latest
`$ErrorAction = "Stop"
`$toolsDir = "`$(Split-Path -Parent `$MyInvocation.MyCommand.Definition)"

`$pythonName = "$PythonName"
`$pythonToolsDir = "`$toolsDir/../../$PythonName/tools/"
`$pythonExe = "`$pythonToolsDir/python.exe"

$PreUninstallScript

& `$pythonExe -m pip uninstall $PypiPackage -y
If ($LastExitCode -ne 0) {
    Write-Error "pip did not succeed!"
}
"@
        Add-Content -Path "$toolsDir/chocolateyUninstall.ps1" -Value $unistall
        
        #
        # Build the nupkg
        $ProgressBarState.activity = "Finalizing python-pip package '$PypiPackage for $PythonName'"
        $ProgressBarState.status = "Building chocolatey package"
        _Update-Progress $ProgressBarState
        
        $newPackageArgs = @{
            TemplateDir = $templateDir
        }
        If ($BuildRoot) {
            $newPackageArgs['BuildRoot'] = $BuildRoot
        }
        If ($OutDir) {
            $newPackageArgs['OutDir'] = $OutDir
        }
        If ($IfNotInRepository) {
            $newPackageArgs['IfNotInRepository'] = $IfNotInRepository
        }
        If ($NoScan) {
            $newPackageArgs['NoScan'] = $NoScan
        }
        If ($VTApiKey) {
            $newPackageArgs['VTApiKey'] = $VTApiKey
        }
        New-Package @newPackageArgs
    } Finally {
        _Update-Progress $ProgressBarState -completed
        
        If (-not $debug) {
            Remove-Item -Recurse $templateDir
        }
    }
}