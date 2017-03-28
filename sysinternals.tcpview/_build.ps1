# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


$startTitle = "TCPview"
$exeName = "TCPView.exe"


New-Package -VersionInfo @{
    Version = "file:tools/$exeName"
} -PrepareFilesHook {
    Import-PackageResource -Url "https://live.sysinternals.com/$exeName"
    
    Add-Content "$($_.BuildDir)/tools/chocolateyInstall.ps1" @"
Set-StrictMode -Version latest
`$ErrorAction = "Stop"


`$toolsDir = "`$(Split-Path -Parent `$MyInvocation.MyCommand.Definition)"
Install-StartMenuLink -LinkName "Sysinternals\Sysinternals $startTitle" -TargetPath "`$toolsDir/$exeName"  
"@
} 