Set-StrictMode -Version latest
$ErrorActionPreference = "Stop"

$destdir   = $(Split-Path -parent $MyInvocation.MyCommand.Definition)
$startPath = Join-Path `
    ([Environment]::GetFolderPath([Environment+SpecialFolder]::Programs)) `
    "Chocolatey"


$exe       = Join-Path $destDir "notepad++.exe"
$startName = "notepad++"
$menuKey   = "HKCR:/*/shell/chocolatey.$env:chocolateyPackageName"
$menuEntry = "Open with notepad++"
$menuCmd   = "$exe %1"
$menuIcon  = $exe

If (-not (Test-Path HKCR:)) {
    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | 
        Out-Null
}