# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


$startTitle = "ShellExView"
$exeName = "shexview.exe"
$zipUrl = "http://www.nirsoft.net/utils/shexview-x64.zip"
$changes = ""


New-Package -VersionInfo @{
    Version = "file:tools/$exeName"
    ReleaseNotes = $changes
} -PrepareFilesHook {
    Import-PackageResource -Url $zipUrl -AutoUnzip
    
    Add-Content "$($_.BuildDir)/tools/chocolateyInstall.ps1" @"
Set-StrictMode -Version latest
`$ErrorAction = "Stop"


`$toolsDir = "`$(Split-Path -Parent `$MyInvocation.MyCommand.Definition)"
Install-StartMenuLink -LinkName "Nirsoft\Nirsoft $startTitle" -TargetPath "`$toolsDir/$exeName"  
"@
} 