$destdir = Split-Path -parent $MyInvocation.MyCommand.Definition
$exe     = Join-Path $destDir "PUTTY.EXE"


# Install start menu shortcut
Install-StartMenuLink -LinkName Putty -TargetPath $exe