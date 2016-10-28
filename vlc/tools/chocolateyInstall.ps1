$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"


$exe64 = Get-Item "$toolsDir/vlc-$env:chocolateyPackageVersion/vlc.exe"
Install-StartMenuLink -LinkName "VLC" -TargetPath $exe64
Set-AutoShim -Pattern $exe64 -Invert -Mode Ignore | Out-Null