$instDir       = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\TreeSize_is1').InstallLocation
Location

$restartExitCode = 3010
$uninstallArgs   = "/verysilent /norestart /suppressmsgboxes /restartexitcode=$restartExitCode"
$uninstallExe    = Join-Path $instDir "unins000.exe"

$validExitCodes = @(
    0,               # all ok
    $restartExitCode #reboot required
)

Uninstall-ChocolateyPackage -PackageName $env:chocolateyPackageName `
    -File $uninstallExe -FileType 'exe' -ValidExitCodes $validExitCodes `
    -SilentArgs $uninstallArgs