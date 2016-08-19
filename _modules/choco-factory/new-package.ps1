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
$ErrorActionPreference = "Stop"

Import-Module get-webfile
Import-Module format-razor
. $PSScriptRoot/_utils.ps1

$msDefenderCommand       = "$env:ProgramFiles/Windows Defender/MpCmdRun.exe"
$msDefenderDirScanArgs   = @(
    '-Scan',                              # Configure a scan operation
    '-DisableRemediation',                # Don't attempt to quarantine matches
    '-ScanType', '3', '-File')            # Custom Directory / File scan

<#
.SYNOPSIS
    Create a binary chocolatey package using the latest version of a software.

.DESCRIPTION
    This function determines the latest version of a software and builds a
    chocolatey package using a nuspec template.
   
    A user-defined hook is used to query the latest software version. See
    also parameter QueryReleaseHook.
    
    The nuspec template uses the razor language [1]. For a syntax reference
    look here: https://docs.asp.net/en/latest/mvc/views/razor.html
    
    Within the template the following package information is available:
        @Package.Id            : The id of the package to be build.
        @Package.Version       : The version of the latest software release.
        @Package.NuspecTemplate: The current nuspec template file (FileInfo).
        @Package.Nuspec        : Full path of the final nuspec file.
        @Package.TemplateDir   : Path containing the package template.
        @Package.BuildDir      : "$BuildRoot/<id>-<version>"
        Additional items returned by the QueryReleaseHook are also available.
        
    The build is performed in "$BuildDir/<id>-<version>". Files and directories
    from the template are copied over prior to building. The nuspec template and
    all items beginning with an underline are skipped.
        
.PARAMETER VersionInfo
    A hash containing information about the latest software release available.
    The hash must at least include version information:
        Version: The version of the latest software release. Must conform to
                 chocolatey's/nuget's versioning rules. See
                 https://docs.nuget.org/create/versioning
                 
    Furthermore, the following information is consumed by the default 
    $PrepareFilesHook:
        FileUrl  : The default ExtractHook downloads the file pointed to by this
                   url to the tools directory prior to building the package. If
                   the file ends with 'zip' it is extracted to the tools folder,
                   instead. If this item is an array, all urls are downloaded.
        Checksum : [Optional] A string of the form <md5|sha1|sha256>:<hash value>
                   that is interpreted as hash value to check the integrity of
                   the file pointed to by Url. If an array of urls has been
                   provided, the i-th file is checked against the i-th hash (if 
                   available).
               
.PARAMETER PrepareFilesHook
    A anonymous powershell function for preparing the files required to build
    the package. The hook is executed with the working directory being 
    "$BuildRoot/<id>-<version>". Within the working directory, the hook may
    freely create and delete files. 
    
    This hook is executed after all applicable files from the template directory
    (that is the folder containing the nuspec template) have been copied to the
    hook's working directory. See DESCRIPTION for details.
    
    The hook is passed a hash map as first argument, that contains all items
    retrieved by the $QueryReleaseHook (see above) supplemented by the items
    available within the nuspec template (see DESCRIPTION).
    
    The default hook implementation is passed as second argument. It can be
    optionally be invoked within a custom hook: & $defaultHook $pkgData 
    
    If no hook is provided, the file at the url retrieved by
    $QueryReleaseHook is downloaded to the package's tools folder. If the file
    extension is '.zip', the file is extracted and deleted afterwards.
    
    If the global variable $global:CFApiKey is set, the default hook queries
    VirusTotal.com prior to downloading a file.
    
.PARAMETER TemplateDir
    Directory containing the package template. Defaults to the current 
    directory.
    
.PARAMETER BuildRoot
    A working directory "$BuildRoot/<id>-<version>" for performing the build is
    created below the $BuildRoot. The working directory is deleted after the
    package have been build. 
    
    The directory $BuildRoot is created if it does not yet exist. If so, it is
    also deleted after the package has been built.
    
    This parameter defaults to $global:CFBuildRoot if defined, or otherwise 
    './_build'.
    
.PARAMETER OutDir
    The final package "<id>.<version>.nupkg" is copied to this directory. Any
    existing file is silently overwritten.
    
    The directory $OutDir is created if it does not yet exist.
    
    This parameter defaults to $global:CFBuildRoot if defined, or otherwise '.'.
    
.PARAMETER IfNotInRepository
    No new package is exported if the file 
    "$IfNotInRepository/<id>.<version>.nupkg" exists.
    
    This parameter defaults to $global:CFRepository if defined. Otherwise no
    default is provided.
    
.PARAMETER NoScan
    Disable virus scan. By default the package files are scanned with windows
    defender. If a VtApikKey (VirusTotal.com API key) is provided, the default
    PrepareFilesHook hook also scans files to be fetched from http(s) sources
    using VirusTotal.com prior to downloading the files.
    
    This parameter defaults to $global:CFNoScan if defined. Otherwise to $false.
    
.PARAMETER VTApiKey
    VirusTotal.com API key: See $NoScan for details.
    
    This parameter defaults to $global:CFVtApiKey if defined. Otherwise no
    default is provided.
           
.PARAMETER Debug
    Don't delete the working directory "$BuildRoot/<id>-<version>" on exit. Also
    activates debug output going beyond Verbose mode.
           
.OUTPUT
    The path of the exported nupkg as FileInfo object. If new new package is
    build due to the IfNotInRepository option, the existing package is returned
    instead.
           
.EXAMPLE
    todo
#>
function New-Package {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
                                      [Hashtable]   $VersionInfo,
        [Parameter(Mandatory=$false)] [ScriptBlock] $PrepareFilesHook
            = $defaultPrepareFilesHook,
        [Parameter(Mandatory=$false)] [String]      $TemplateDir 
            = '.',
        [Parameter(Mandatory=$false)] [String]      $BuildRoot   
            = (_Get-Var 'global:CFBuildRoot'            './_build'),
        [Parameter(Mandatory=$false)] [String]      $OutDir      
            = (_Get-Var 'global:CFBuildRoot'            '.'),
        [Parameter(Mandatory=$false)] [String]      $IfNotInRepository
            = (_Get-Var 'global:CFRepository'           $null),
        [Parameter(Mandatory=$false)] [Switch]      $NoScan
            = (_Get-Var 'global:CFNoScan'               $false),
        [Parameter(Mandatory=$false)] [String]      $VTApiKey
            = (_Get-Var 'global:CFVtApiKey'             $null)
    )   
    Import-CallerPreference -AdditionalPreferences @{ ProgressBarId = 0 }
    
    
    # store current location to restore it later
    $location               = Get-Location
    
    
    # retrieve & clone VersionInfo: items are added later on!
    $pkgData                = $VersionInfo.Clone()
    If (-not ($pkgData.Version -match $_semverRegex)) {
        Write-Error `
            "$($pkgData.Version) does not comply with semver specification"
        return
    }

    # collect template/package information
    $pkgData.NuspecTemplate = Get-ChildItem `
        -Path "$TemplateDir/*$_templateExtension" | Select-Object -First 1
    $pkgData.TemplateDir    = $pkgData.NuspecTemplate.Directory
    $pkgData.Id             = $pkgData.NuspecTemplate.BaseName
    $pkgData.BuildDir       = _Get-AbsolutePath `
        -Path "$BuildRoot/$($pkgData.Id)-$($pkgData.Version)"
    $pkgData.Nuspec         = Join-Path `
        $pkgData.BuildDir $pkgData.NuspecTemplate.Name
    
    Write-Verbose "PkgData`n$(_Format-Hash $pkgData)"
    
    
    # prepare progress bar
    $ProgressBarId          = $ProgressBarId + 1
    $ProgressBarState       = @{
        activity = "Building $($pkgData.Id)-$($pkgData.Version)..."
        status   = "Initializing..."
        current  = 0
        max      = 8
    }
    _Update-Progress $ProgressBarState -noIncrease
    
    # prepare other information
    $debug                  = $DebugPreference -ne 'SilentlyContinue'
    $verbose                = $VerbosePreference -ne 'SilentlyContinue' `
        -or $debug
    $deleteBuildRoot        = -not (Test-Path -Path $BuildRoot)
    $nupkgName              = "$($pkgData.Id).$($pkgData.Version).nupkg"
    $nupkgTmpFile           = _Get-AbsolutePath ( `
        Join-Path $pkgData.BuildDir $nupkgName )
    $nupkgOutFile           = _Get-AbsolutePath ( `
        Join-Path $OutDir $nupkgName )
    
    # Disable VirusTotal+Defender scan if NoScan has been specified
    If ($NoScan) { 
        Write-Warning "Virus scanning has been disabled!"
    
        $VTApiKey           = $null
        $numberOfSteps      = 7
    }
    
    If ($IfNotInRepository) {
        $queryPath   = Join-Path $IfNotInRepository $nupkgName
        $existingPkg = Get-Item -Path $queryPath -ErrorAction SilentlyContinue
        If ($existingPkg) {
            Write-Verbose "Existing package found: $existingPkg"
            return $existingPkg
        }
    }
    
    
    Write-Verbose "Building package $($pkgData.Id)-$($pkgData.Version) from $($pkgData.NuspecTemplate)"
    
    
    # prepare build directory: 
    #  - delete if already existing
    #  - populate with files from the template directory
    if (Test-Path -Path $pkgData.BuildDir) {
        $ProgressBarState.max++; _Update-Progress $ProgressBarState -NoIncrease
    
        Remove-Item -Path $pkgData.BuildDir -Recurse -Confirm
        If (Test-Path -Path $pkgData.BuildDir) {
            Write-Error "Build directory already exists: $($pkgData.BuildDir)"
            return
        }
    }
    
    $ProgressBarState.status = "Creating workign directory."
    _Update-Progress $ProgressBarState
    Write-Verbose "Preparing build directory $($pkgData.BuildDir)"
    New-Item -Path $pkgData.BuildDir -ItemType Directory | Out-Null
        
        
    Try {
        Set-Location -Path $pkgData.BuildDir
        
        $ProgressBarState.status = "Copy template files to working directory..."
        _Update-Progress $ProgressBarState
        
        Copy-Item -Exclude @("*$_templateExtension";"_*") `
                  -Path "$($pkgData.TemplateDir)/*" `
                  -Destination $pkgData.BuildDir `
                  -Recurse
                  
        # more files need to be downloaded or prepared by other means
        $ProgressBarState.status = "Prepare/download package content..."
        _Update-Progress $ProgressBarState
        
        & $PrepareFilesHook $pkgData $defaultPrepareFilesHook
             
             
        # process nuspec template
        $ProgressBarState.status = "Process nuspec template."
        _Update-Progress $ProgressBarState
        
        $templateText    = Get-Content `
            -Encoding UTF8 -Raw -Path $pkgData.NuspecTemplate
        $razorModel         = New-Object psobject -Property $pkgData
        $nuspec             = Format-Razor `
            -ModelName "Package" -Model $razorModel  -TemplateText $templateText
        
        _Write-DbgNoConfirm $nuspec
        $utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($False)
        [IO.File]::WriteAllLines($pkgData.Nuspec, $nuspec, $utf8NoBomEncoding)
        
        
        # Virus scan package files prior to building it
        If (-not $NoScan) {
            $ProgressBarState.status = "Virus scanning (MS Defender)..."
            _Update-Progress $ProgressBarState
            
            $args = $msDefenderDirScanArgs.Clone()
            $args += $pkgData.BuildDir
            
            Write-Verbose "Virus Scanning`n$msDefenderCommand $args"
            $cout = & $msDefenderCommand $args | Out-String
            
            If ($LASTEXITCODE -eq 0) {
                Write-Verbose "MS Defender did not find any threats!`n$cout"
            } Else {
                Write-Warning -WarningAction Inquire (
                    "MS Defender found potential threats!`n" +
                    "Exit code: $LASTEXITCODE`n$cout" +
                    "Press [H] if unsure."
                )
            }
        }
        
        
        # build nupkg
        $ProgressBarState.status = "Executing choco pack..."
        _Update-Progress $ProgressBarState
        
        $chocoArgs = @('pack', '--yes')
        If ($debug -or $verbose) {
            If ($debug) {
                $chocoArgs += '--debug'
            } 
            If ($verbose) {
                $chocoArgs += '--verbose'
            }
            
            & choco $chocoArgs
        } Else {
            $chocoArgs += '--limit-output'
            $chocoOut = & choco $chocoArgs | Out-String
        }
        
        If ($LASTEXITCODE -ne 0) {
            Write-Error "Choco returned exit code $LASTEXITCODE.`n$chocoOut"
            return
        }
            
        
        # prepare output
        If (-not (Test-Path $nupkgTmpFile)) {
            Write-Error "Nupkg has not been built: $nupkgTmpFile"
            return
        }
        If (-not (Test-Path $OutDir)) {
            New-Item -Path $OutDir -ItemType Directory | Out-Null
        }
        
        Move-Item -Path $nupkgTmpFile -Destination $nupkgOutFile -Force
    } Finally {
        $ProgressBarState.status = "Cleaning up..."
        _Update-Progress $ProgressBarState
        
        Set-Location -Path $location
    
        If (!$debug) {
            Write-Verbose "Cleaning up build directory $($pkgData.BuildDir)"
            Remove-Item -Path $pkgData.BuildDir -Recurse
            
            # delete $BuildRoot if empty and created by this cmdlet
            If ($deleteBuildRoot -and -not (Test-Path -Path "$BuildRoot/*")) {
                Remove-Item -Path $BuildRoot
            }
        }
    }
    
    _Update-Progress $ProgressBarState -completed
    return Get-Item -Path $nupkgOutFile
}

$defaultPrepareFilesHook = {
    param($pkgData, $defaultHook=$null)

    If (-not (Test-Path -Path "tools")) {
        New-Item -Path "tools" -ItemType Directory | Out-Null
    }

    $targetFolder = "tools"
    $urlList      = @() + $pkgData.FileUrl
    $hashList     = @() + $pkgData['Checksum'] # optional property
    
    For ($i = 0; $i -lt $urlList.length; $i++) {
        $url = $urlList[$i]
        $hash = $hashList[$i]            
        
        $file = Get-WebFile -Uri $url -OutFile $targetFolder `
            -VtApiKey $VTApiKey -Debug:$false
        if ($hash -and ($hash -match "^(?<algorithm>[a-zA-Z0-9]+):(?<hash>.+)$")) {
            $algorithm = $Matches.algorithm
            $expected  = $Matches.hash.ToLower()
            $actual    = (Get-FileHash -Path $file -Algorithm $algorithm).Hash.ToLower()
            
            if ($actual -ine $expected) {
                Write-Error "File hash validation failed. File: $file; Algorithm: $algorithm; Expected: $expected; Actual: $actual"
                return
            }
        } ElseIf ($hash -eq $null) {
            Write-Verbose "No checksum provided for file: $file"
        } Else {
            Write-Error "Malformed checksum specification. File: $file; Hash: $hash"
            return
        }
        
        If ($file.Extension -ieq '.zip') {
            Write-Verbose "Expanding archive: $file"
            Expand-Archive -Path $file -DestinationPath $targetFolder
            Remove-Item -Path $file -Force
        }
    }
}

Set-Alias cf-export Export-Package