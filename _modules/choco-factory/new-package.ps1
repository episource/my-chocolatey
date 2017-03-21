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
    
$defaultPrepareFilesHook = {
    If (-not $_.ContainsKey('FileUrl')) {
        Write-Verbose "There are no resources to be downloaded."
        return
    }
    
    $urlList     = @() + $_['FileUrl']
    $cookiesList = @() + $_['Cookies']
    $csumList    = @() + $_['Checksum']
    
    For ($i = 0; $i -lt $urlList.Length; $i++) {
        $params = @{ Url = $urlList[$i]; AutoUnzip = $true }
        
        If ($i -lt $cookiesList.Length -and $cookiesList[$i]) {
            $params.Cookies = $cookiesList[$i]
        }
        
        Import-PackageResource @params
    }
}

<#
.SYNOPSIS
    Create a binary chocolatey package using information about the latest
    version of a software.

.DESCRIPTION
    This function uses the provided version information to build builds a
    chocolatey package from a nuspec template.
      
    The nuspec template uses the razor language [1]. For a syntax reference
    look here: https://docs.asp.net/en/latest/mvc/views/razor.html
    
    Within the template the following package information is available:
        @Package.Id            : The id of the package to be build.
        @Package.Version       : The version of the latest software release.
        @Package.NuspecTemplate: The current nuspec template file (FileInfo).
        @Package.Nuspec        : Full path of the final nuspec file.
        @Package.TemplateDir   : Path containing the package template.
        @Package.BuildDir      : "$BuildRoot/<id>-<version>"
        Additional entries from the VersionInfo passed to this cmdlet are also
        available.
        
    The build is performed in "$BuildDir/<id>-<version>". Files and directories
    from the template are copied over prior to building. The nuspec template and
    all items beginning with an underline are skipped.
        
.PARAMETER VersionInfo
    OPTIONAL - A hash containing information about the latest software release
    available. All hash entries are made available to the nuspec template (see
    above).
    
    The hash usually contains at least a version number:
        Version: The version of the latest software release. Must conform to
                 chocolatey's/nuget's versioning rules. See
                 https://docs.nuget.org/create/versioning
                 It is also possible to use "file:tools/file.exe" as version
                 specification. If so, the product version of file.exe is used
                 as package version. The path must be relative to the build
                 directory.
                 
    If the version might also be hard coded in the nuspec template. This can be
    useful when building static nuspec files.
                 
    Furthermore, the following information is consumed by the default 
    $PrepareFilesHook:
        FileUrl  : The default ExtractHook downloads the file pointed to by this
                   url to the tools directory prior to building the package. If
                   the file ends with 'zip' it is extracted to the tools folder,
                   instead. If this item is an array, all urls are downloaded.
        FileUrlCookies :
                   [Optional] An list (hashtable of key value pairs) of cookies
                   to be passed to the download server. If an array of urls has
                   been provided, this must be an array of hashtables, too. The
                   i-th file is downloaded using the i-th cookie list.
        Checksum : [Optional] A string of the form <md5|sha1|sha256>:<hash value>
                   that is interpreted as hash value to check the integrity of
                   the file pointed to by Url. If an array of urls has been
                   provided, the i-th file is checked against the i-th hash (if 
                   available).
               
.PARAMETER PrepareFilesHook
    OPTIONAL - A anonymous powershell function for preparing the files required
    to build the package. The hook is executed with the working directory being 
    "$BuildRoot/<id>-<version>". Within the working directory, the hook may
    freely create and delete files. 
    
    This hook is executed after all applicable files from the template directory
    (that is the folder containing the nuspec template) have been copied to the
    hook's working directory. See DESCRIPTION for details.
    
    From within the hook, all PkgData available to the nuspec template (see
    description above) is available via the variables $_ and $PkgData. 
        $_, $PkgData: All PkgData also available within the nuspec template
                      (see Description above).
    
    The behavior of the default hook (see below) is made available as cmdlet
    Import-PackageResource.
    
    If no hook is provided, all files specified by the $PkgData.FileUrl array
    are downloaded to the package's tools folder. If the file extension is
    '.zip', the file is extracted and deleted afterwards.
    
    If the global variable $global:CFApiKey is set, the default hook queries
    VirusTotal.com prior to downloading a file.
    
.PARAMETER TemplateDir
    OPTIONAL - Directory containing the package template. If invoked by a
    script, the default value is the directory containing the calling script. If
    invoked from the command line, this parameter defaults to $(Get-Location), 
    that is the current working directory.
    
.PARAMETER BuildRoot
    OPTIONAL - A working directory "$BuildRoot/<id>-<version>" for performing
    the build is created below the $BuildRoot. The working directory is deleted
    after the package have been build. 
    
    The directory $BuildRoot is created if it does not yet exist. If so, it is
    also deleted after the package has been built.
    
    This parameter defaults to $global:CFBuildRoot if defined. Otherwise, if the
    cmdlet is invoked by a script, the default value is 
    "$(Directory with script)/_build". If invoked from the command line, the
    default is "$(Get-Location)/_build".
    
.PARAMETER OutDir
    OPTIONAL - The final package "<id>.<version>.nupkg" is copied to this 
    directory. Any existing file is silently overwritten.
    
    The directory $OutDir is created if it does not yet exist.
    
    This parameter defaults to $global:CFBuildRoot if defined. Otherwise, if the
    cmdlet is invoked by a script, the default value is 
    $(Directory with script). If invoked from the command line, the default is
    $(Get-Location).
    
.PARAMETER IfNotInRepository
    OPTIONAL - No new package is exported if the file 
    "$IfNotInRepository/<id>.<version>.nupkg" exists.
    
    This parameter defaults to $global:CFRepository if defined. Otherwise no
    default is provided.
    
.PARAMETER NoScan
    OPTIONAL - Disable virus scan. By default the package files are scanned with
    windows defender. If a VtApikKey (VirusTotal.com API key) is provided, the
    default PrepareFilesHook hook also scans files to be fetched from http(s) 
    sources using VirusTotal.com prior to downloading the files.
    
    This parameter defaults to $global:CFNoScan if defined. Otherwise to $false.
    
.PARAMETER VTApiKey
    OPTIONAL - VirusTotal.com API key: See $NoScan for details.
    
    This parameter defaults to $global:CFVtApiKey if defined. Otherwise no
    default is provided.
           
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
function New-Package {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
        [Hashtable] $VersionInfo = @{},
        
        [Parameter(Mandatory=$false)]
        [ScriptBlock] $PrepareFilesHook = $defaultPrepareFilesHook,
        
        [Parameter(Mandatory=$false)]
        [String] $TemplateDir = $(_Get-CallingScriptDirOrCurrentDir),
        
        [Parameter(Mandatory=$false)]
        [String] $BuildRoot = (_Get-Var 'global:CFBuildRoot' `
            '$(_Get-CallingScriptDirOrCurrentDir)/_build'),
                
        [Parameter(Mandatory=$false)]
        [String] $OutDir = (_Get-Var 'global:CFBuildRoot' `
            '$(_Get-CallingScriptDirOrCurrentDir)'),
            
        [Parameter(Mandatory=$false)]
        [String] $IfNotInRepository = (_Get-Var 'global:CFRepository' $null),
        
        [Parameter(Mandatory=$false)]
        [Switch] $NoScan = (_Get-Var 'global:CFNoScan' $false),
        
        [Parameter(Mandatory=$false)]
        [String] $VTApiKey = (_Get-Var 'global:CFVtApiKey' $null)
    )   
    Import-CallerPreference -AdditionalPreferences @{ ProgressBarId = 0 }
    
    function _Invoke-PrepareFilesHook {
        Try {
            $script:pkgData = $pkgData
            $PrepareFilesHook.InvokeWithContext(@{}, @(
                    [PSVariable]::new('_', $pkgData)
                    [PSVariable]::new('PkgData', $pkgData)     
                    [PSVariable]::new('DefaultHook', $defaultPrepareFilesHook)
                )
            )| Out-Null
        } Catch {
            # Propagate original exception
            throw $_.Exception.InnerException
        }
    }

    $debug = $DebugPreference -ne 'SilentlyContinue'
    $verbose = $VerbosePreference -ne 'SilentlyContinue' -or $debug
    $deleteBuildRoot = -not (Test-Path -Path $BuildRoot)
    
    # store current location to restore it later
    $location = Get-Location
    
    # prepare progress bar
    $ProgressBarId          = $ProgressBarId + 1
    $ProgressBarState       = @{
        activity = "Building $TemplateDir"
        status   = "Initializing..."
        current  = 0
        max      = 10
    }
    _Update-Progress $ProgressBarState -noIncrease
    
    
    # retrieve & clone VersionInfo: items are added later on!
    $pkgData                = $VersionInfo.Clone()
    
    # collect template/package information
    $pkgData.NuspecTemplate = Get-ChildItem `
        -Path "$TemplateDir/*$_templateExtension" | Select-Object -First 1
    $pkgData.TemplateDir    = $pkgData.NuspecTemplate.Directory
    $pkgData.Id             = $pkgData.NuspecTemplate.BaseName
        
    If (-not $pkgData.NuspecTemplate) {
        Write-Error "Missing nuspec template: $TemplateDir\*$_templateExtension"
        return
    }
        
    # retrieve & check version + id string
    $nuspecInfo = _Get-NuspecIdAndVersion $pkgData.NuspecTemplate
    
    If (-not $pkgData.ContainsKey('Version')) {
        $pkgData.Version = $nuspecInfo.Version
    }
    If ($pkgData.Version -ne $nuspecInfo.Version `
            -and $nuspecInfo.Version -ne "@Package.Version") {
        Write-Error (
            "Hard coded version from nuspec template does not match the " + `
            "calculated version: $($nuspecInfo.Version) != $($pkgData.Version)"
        )
    }
    If ($pkgData.Id -ne $nuspecInfo.Id `
            -and $nuspecInfo.Id -ne "@Package.Id") {
        Write-Error (
            "Hard coded id from nuspec template does not match the " + `
            "template's name: $($nuspecInfo.Id) != $($pkgData.Id)"
        ) 
    }
    
    $versionFromFile = $false
    If ($pkgData.Version.ToLower().StartsWith("file:")) {
        $versionFromFile = $pkgData.Version.Split(":")[1]
    } ElseIf (-not ($pkgData.Version -match $_semverRegex)) {
        Write-Error "$($pkgData.Version) does not comply with semver specification"
        return
    }  
    
    $ProgressBarState.Activity = "Building $($pkgData.Id)-$($pkgData.Version)..."
    _Update-Progress $ProgressBarState
    
    # prepare other information
    If ($versionFromFile) {
        $pkgData.BuildDir = _Get-AbsolutePath -Path "$BuildRoot/$($pkgData.Id)"
    } Else {
        $pkgData.BuildDir = `
            _Get-AbsolutePath -Path "$BuildRoot/$($pkgData.Id)-$($pkgData.Version)"
        $nupkgName = "$($pkgData.Id).$($pkgData.Version).nupkg"
            
        If ($IfNotInRepository) {
            $queryPath   = Join-Path $IfNotInRepository $nupkgName
            $existingPkg = Get-Item -Path $queryPath -ErrorAction SilentlyContinue
            If ($existingPkg) {
                Write-Verbose "Existing package found: $existingPkg"
                return $existingPkg
            }
        }
    }
    
    $pkgData.Nuspec = Join-Path $pkgData.BuildDir $pkgData.NuspecTemplate.Name
    
    
    # Disable VirusTotal+Defender scan if NoScan has been specified
    If ($NoScan) { 
        Write-Warning "Virus scanning has been disabled!"
    
        $VTApiKey = $null
        _Update-Progress $ProgressBarState # skip one step
    }
    
    
    Write-Verbose "Building package $($pkgData.Id)-$($pkgData.Version) from $($pkgData.NuspecTemplate)"
    
    # take care of lazy initialized version info items
    ForEach ($e in $VersionInfo.GetEnumerator()) {
        If ($e.Value -and [ScriptBlock].IsAssignableFrom($e.Value.GetType())) {
            $pkgData[$e.Key] = & $e.Value
        }
    }
    Write-Verbose "PkgData`n$(_Format-Hash $pkgData)"
    
    
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
    
    $ProgressBarState.status = "Creating working directory."
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
        $ProgressBarState.status = "Prepare/download package resources..."
        _Update-Progress $ProgressBarState
        _Invoke-PrepareFilesHook
        
        # finalize package/version information
        If ($versionFromFile) {
            $versionFile = Get-Item $versionFromFile
            
            $versionParts = $versionFile.VersionInfo.ProductVersion.Split(".")
            while ($versionParts.Length -lt 3) {
                $versionParts += @( "0" )
            }
            $pkgData.Version = [String]::Join(".", $versionParts)
            
            If (-not ($pkgData.Version -match $_semverRegex)) {
                Write-Error "$($pkgData.Version) does not comply with semver specification"
                return
            }  
            
            $nupkgName = "$($pkgData.Id).$($pkgData.Version).nupkg"
            If ($IfNotInRepository) {
                $queryPath = Join-Path $IfNotInRepository $nupkgName
                $existingPkg = Get-Item -Path $queryPath -ErrorAction SilentlyContinue
                If ($existingPkg) {
                    Write-Verbose "Existing package found: $existingPkg"
                    return $existingPkg
                }
            }
        }
        
        $nupkgTmpFile = _Get-AbsolutePath ( Join-Path $pkgData.BuildDir $nupkgName )
        $nupkgOutFile = _Get-AbsolutePath (  Join-Path $OutDir $nupkgName )
        
        $ProgressBarState.Activity = "Building $($pkgData.Id)-$($pkgData.Version)..."
        _Update-Progress $ProgressBarState
             
             
        # process nuspec template
        $ProgressBarState.status = "Process nuspec template."
        _Update-Progress $ProgressBarState
        
        $templateText = Get-Content -Encoding UTF8 -Raw -Path $pkgData.NuspecTemplate
        $razorModel = New-Object psobject -Property $pkgData
        $nuspec = Format-Razor -ModelName "Package" -Model $razorModel  -TemplateText $templateText
        
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

<#
.SYNOPSIS
    Downloads a package resources to the package build directory.
    
.DESCRIPTION
    This cmdlet downloads a resource file to the package build directory and
    takes care of caching and checksum validation.
    
    Important: This script must be called from within a prepare files hook!
    
.PARAMETER Url
    The url of a file to be downloaded.
    
.PARAMETER Cookies
    Cookies to be passed to the download server. This is actually a hashtable
    of key value pairs like {@ "cookie-name"="cookie-value" }.
    
.PARAMETER Checksum
    OPTIONAL - Checksum for file validation. A string of the form 
    '<md5|sha1|sha256>:<hash value>' that is interpreted as hash value to check
    the integrity of the file pointed to by Url.
    
.PARAMETER TargetDirectory
    OPTIONAL - A path relative to the package build directory. The downloaded
    resource is copied to this directory. Defaults to "tools".
    
.PARAMETER TargetName
    Optional - The name of the downloaded file. By default the name is chosen
    based on the server response's content disposition header.
    
.PARAMETER AutoUnzip
    Optional - Unzip *.zip files to the within TargetDirectory.
    
.OUTPUT
    None
    
#>
function Import-PackageResource() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
        [String] $Url,
        
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [HashTable] $Cookies = @{},
        
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [String] $Checksum = $null,
        
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [AllowEmptyString()]
        [String] $TargetDirectory = "tools",
        
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [String] $TargetName = "",
        
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [Switch] $AutoUnzip = $false
    )
    
    Begin {
        Try {
            $pkgData = Get-Variable -Scope script -Name pkgData -ErrorAction stop
        } Catch {
            Throw "Not called from within PrepareFilesHook!"
        }
    }
    Process {
        $cachePath    = _Get-Var global:CFCacheDir $null
        $absTargetDir = Join-Path $script:pkgData.BuildDir $TargetDirectory
        
        If (-not (Test-Path -Path $absTargetDir)) {
            New-Item -Path $absTargetDir -ItemType Directory | Out-Null
        }
              
            
        # Retrieve file from web or cache
        $cacheKey = $null
        $fileFromCache = $null
        If ($cachePath) {
            $httpHeaders = @{}
            Try {
                $headResponse = Invoke-WebRequest -Method Head $url
                $httpHeaders = $headResponse.Headers
            } Catch {
                Write-Warning "Failed to get http headers: $url"
            }
            
            $cacheKey = _Get-StringHash (
                $url + $httpHeaders["Content-Length"] + $httpHeaders["ETag"] `
                + $httpHeaders["Last-Modified"] )
            $fileFromCache = Get-Item "$cachePath/$cacheKey-*" `
                -ErrorAction SilentlyContinue | Select-Object -First 1
        }
            
        If ($fileFromCache) {
            If ($TargetName) {
                $fname = $TargetName
            } Else {
                $fname = (Split-Path -Leaf $fileFromCache) -replace "^$cacheKey-"
            }
            
            $file  = Join-Path $absTargetDir $fname
            Copy-Item -Path $fileFromCache -Destination $file -Force
            $file = Get-Item $file
        } Else {
            $outFileOrFolder = Join-Path $absTargetDir $TargetName
            $file = Get-WebFile -Uri $url -Cookies $cookies `
                -OutFile $outFileOrFolder -VtApiKey $VTApiKey -Debug:$false
        }
            
            
        # Validate checksum
        If (-not $Checksum) {
            Write-Verbose "No checksum provided for file: $file"
        } ElseIf ($Checksum -match "^(?<ALGORITHM>[a-zA-Z0-9]+):(?<HASH>.+)$") {
            $algorithm = $Matches.ALGORITHM
            $expected  = $Matches.HASH.ToLower()
            $actual    = (Get-FileHash -Path $file -Algorithm $algorithm).Hash.ToLower()
            
            if ($actual -ine $expected) {
                $msg = "File hash validation failed.`nFile: $file`nAlgorithm: $algorithm`nExpected: $expected`nActual: $actual"
                If ($fileFromCache) {
                    $msg += "`nConsider deleting cached file: $fileFromCache"
                }
                Write-Error $msg
                
                return
            }  
        } Else {
            Write-Error "Malformed checksum specification. File: $file; Hash: $hash"
            return
        }
        
        
        # Add downloaded file to the download cache
        If ($cacheKey -and -not $fileFromCache) {
            $fname = Split-Path -Leaf $file
                
            New-Item -Type Directory $cachePath -Force | Out-Null
            Copy-Item -Path $file `
                -Destination "$cachePath/$cacheKey-$fname" -Force
        }
        
        
        # Unzip
        If ($AutoUnzip -and $file.Extension -ieq '.zip') {
            Write-Verbose "Expanding archive: $file"
            Expand-Archive -Path $file -DestinationPath $absTargetDir
            Remove-Item -Path $file -Force
        }
    }
}

Set-Alias cf-export Export-Package