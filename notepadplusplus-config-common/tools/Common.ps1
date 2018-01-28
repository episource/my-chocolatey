Set-StrictMode -Version latest
$ErrorActionPreference = "Stop"

$destdir = $(Split-Path -parent $MyInvocation.MyCommand.Definition)
$nppdir  = Join-Path $nppPackageDir "tools"

$configModel        = Join-Path $nppdir "config.model.xml"
$configModelBackup  = "$configModel.bak"

$stylersModel       = Join-Path $nppdir "stylers.model.xml"
$stylersModelBackup = "$stylersModel.bak"

$shortcuts          = Join-Path $nppdir "shortcuts.xml"
$shortcutsBackup    = "$shortcuts.bak"