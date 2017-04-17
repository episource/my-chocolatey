# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1

Select-BuildDependency -Name "wix" -Version "3.11" | Out-Null


$dlIndexUrl = "https://www.python.org/downloads/windows/"
$dlIndex = Invoke-WebRequest -UseBasicParsing $dlIndexUrl
$dlIndex -match "Latest Python 3 release - Python (?<VERSION>(?:\d+\.){2,3}\d+)" | Out-Null
$version = $Matches.VERSION

New-Package -VersionInfo @{
    Version =  $version
    FileUrl = "https://www.python.org/ftp/python/$version/python-$version.exe"
} -PrepareFiles {
    $setupDir = "tools/_setup"
    New-Item -Type Directory $setupDir
    Import-PackageResource -Url $_.FileUrl -TargetDirectory $setupDir
    $setupExe = Get-Item "$setupDir/*.exe"
    
    # extract bundle using dark decompiler from the wix toolset
    # -> preserve original bootstrap exe, so that manual install remains
    #    possible!
    & dark.exe $setupExe -x $setupDir
    If ($LastExitCode -ne 0) {
        Write-Error "Extracting python bundle failed!"
        return
    }
}