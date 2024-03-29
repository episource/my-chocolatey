﻿# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


# Query github API to get url and version of the latest release
$repo = 'icsharpcode/ILSpy'
$filename = "ILSpy_[bB]inaries.*?(?<VERSION>\d+(?:\.\d+){1,3})-x64\.zip"


# Export the package (subject to _config.ps1)
Get-VersionInfoFromGithub -Repo $repo -File $filename -EnableRegex | New-Package