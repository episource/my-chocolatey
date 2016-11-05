Set-StrictMode -Version latest
$ErrorAction = "Stop"


$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$setupExe = Get-Item "$toolsDir/HardLinkShellExt_x64.exe"
$setupArgs = "/S"
$validExitCodes = @(0)

Install-ChocolateyInstallPackage `
    -PackageName $env:chocolateyPackageName `
    -File $setupExe -FileType 'exe' -ValidExitCodes $validExitCodes `
    -SilentArgs $setupArgs