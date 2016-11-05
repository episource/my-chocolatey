$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"

$orcaExe = Get-Item "$toolsDir/Orca.exe"
Install-StartMenuLink -LinkName "Orca MSI Editor" -TargetPath $orcaExe `
    -WorkingDirectory $toolsDir