$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"

$installerExe    = @("vcredist_x64.exe", "vcredist_x86.exe")
$installerArgs   = "/Q /C:""msiexec.exe /i vcredist.msi /quiet /qn /norestart"""

$validExitCodes = @(
    # https://msdn.microsoft.com/en-us/library/windows/desktop/aa376931(v=vs.85).aspx
    0,   # all ok
    3010 #reboot required
)

ForEach ($exe in $installerExe) {
    $path = Join-Path $toolsDir $exe
    Install-ChocolateyInstallPackage `
        -PackageName "$env:chocolateyPackageName ($exe)" `
        -File $path -FileType 'exe' -ValidExitCodes $validExitCodes `
        -SilentArgs $installerArgs
}