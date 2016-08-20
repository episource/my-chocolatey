Set-StrictMode -Version latest
$ErrorActionPreference = "Stop"

$destdir   = $(Split-Path -parent $MyInvocation.MyCommand.Definition)
$startPath = Join-Path `
    ([Environment]::GetFolderPath([Environment+SpecialFolder]::Programs)) `
    "Chocolatey"

$arch   = "x64"
If (Get-OSArchitectureWidth -Compare 32) {
    $arch   = "x86"
}

$appname   = "ProcessHacker"
$exename   = "$appname.exe"
$drvname   = "kprocesshacker.sys"
$x86dir    = Join-Path $destDir "x86"
$x64dir    = Join-Path $destDir "x64"
$bindir    = Join-Path $destDir $arch
$exe       = Join-Path $bindir $exename
$x86exe    = Join-Path $x86dir $exename
$x64exe    = Join-Path $x64dir $exename
$drvsys    = Join-Path $bindir $drvname
$startLink = Join-Path $startPath "$appname ($arch).lnk"
