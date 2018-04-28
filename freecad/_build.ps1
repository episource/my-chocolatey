﻿# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


Get-VersionInfoFromGithub -Repo "FreeCAD/FreeCAD" -File "FreeCAD[-_](?<VERSION>\d+\.\d+\.\d+)(?:\.[0-9a-zA-Z]+)?[-_](?:WIN[-_])?x64[-_](?:setup|installer)\.exe" -EnableRegex |
New-Package