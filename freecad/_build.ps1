﻿# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


Get-VersionInfoFromGithub -Repo "FreeCAD/FreeCAD" -File "FreeCAD-(?<VERSION>\d+\.\d+\.\d+).*-WIN-x64_Installer.*\.exe" -EnableRegex |
New-Package