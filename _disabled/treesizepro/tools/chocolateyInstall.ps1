$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"

$installerExe    = Join-Path $toolsDir "TreeSize-x64-Full.exe"
$restartExitCode = 3010
$installerArgs   = "/verysilent /norestart /restartexitcode=$restartExitCode"

$validExitCodes = @(
    0,               # all ok
    $restartExitCode #reboot required
)

Install-ChocolateyInstallPackage -PackageName $env:chocolateyPackageName `
    -File $installerExe -FileType 'exe' -ValidExitCodes $validExitCodes `
    -SilentArgs $installerArgs