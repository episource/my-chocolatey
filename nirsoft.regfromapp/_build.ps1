﻿# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


$changelogUrl = "http://www.nirsoft.net/utils/reg_file_from_application.html"
$changelogRaw = Invoke-WebRequest -UseBasicParsing $changelogUrl
$changelogItems = $changelogRaw -split '(?=<li>Version)'
$changes = $changelogItems[1..($changelogItems.Length-2)] | %{ $_ `
    -replace "(?si)<li>(Version[^:`n`r]*).*<ul>",'= ${1} =' `
    -replace "`r?`n(?!<li)(?!</ul>)",'' `
    -replace '<li>',' * ' `
    -replace '</ul>' 
} | Out-String

New-Package -VersionInfo @{
    Version = "file:tools/RegFromApp.exe"
    FileUrl = "http://www.nirsoft.net/utils/regfromapp-x64.zip"
    ReleaseNotes = $changes
}