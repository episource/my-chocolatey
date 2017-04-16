Set-StrictMode -Version latest
$ErrorAction = "Stop"
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$targetDir = "$env:ProgramFiles\Python\PyLauncher"


$msi = Get-Item "$toolsDir/*.msi"
$msiArgs = "/quiet /qn /norestart REBOOT=ReallySupress ALLUSERS=1"
Install-ChocolateyInstallPackage -PackageName $env:chocolateyPackageName `
    -File $msi -FileType 'msi' -ValidExitCodes @( 0 ) -silentArgs $msiArgs