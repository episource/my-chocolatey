Set-StrictMode -Version latest
$ErrorActionPreference = "Stop"

$destdir   = Split-Path -parent $MyInvocation.MyCommand.Definition

$arch   = "x64"
If (Get-OSArchitectureWidth -Compare 32) {
    $arch   = "x86"
}

$appname   = "ProcessHacker"
$exename   = "$appname.exe"
$startname = "$appname ($arch)"
$x86dir    = Join-Path $destDir "x86"
$x64dir    = Join-Path $destDir "x64"
$bindir    = Join-Path $destDir $arch
$exe       = Join-Path $bindir $exename
$x86exe    = Join-Path $x86dir $exename
$x64exe    = Join-Path $x64dir $exename


# Install start menu shortcut
Install-StartMenuLink -LinkName $startname -TargetPath $exe

# Add shim to path
Install-Shim -Name "${appname}_x86" -Path $x86exe
Install-Shim -Name "${appname}_x64" -Path $x64exe
Install-Shim -Name "$appname"       -Path $exe