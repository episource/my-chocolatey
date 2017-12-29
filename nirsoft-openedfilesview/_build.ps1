# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


$startTitle = "OpenedFilesView"
$exeName = "OpenedFilesView.exe"
$zipUrl = "http://www.nirsoft.net/utils/ofview-x64.zip"

$changelogUrl = "http://www.nirsoft.net/utils/opened_files_view.html"
$changelogRaw = Invoke-WebRequest -UseBasicParsing $changelogUrl
$changelogItems = $changelogRaw -split '(?=<li>Version)'
$changes = $changelogItems[1..($changelogItems.Length-2)] | %{ $_ `
    -replace "(?si)<li>(Version[^:`n`r]*).*<ul>",'= ${1} =' `
    -replace "`r?`n(?!<li)(?!</ul>)",'' `
    -replace '<li>',' * ' `
    -replace '</ul>' 
} | Out-String


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
Set-AutoShim -Pattern "**" -Mode Ignore | Out-Null
"@
} 