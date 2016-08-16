Set-StrictMode -Version latest
$ErrorActionPreference = "Stop"

$destdir   = $(Split-Path -parent $MyInvocation.MyCommand.Definition)
$startPath = Join-Path `
    ([Environment]::GetFolderPath([Environment+SpecialFolder]::Programs)) `
    "Chocolatey"


$exe       = Join-Path $destDir "PUTTY.EXE"
$startLink = Join-Path $startPath "Putty.lnk"