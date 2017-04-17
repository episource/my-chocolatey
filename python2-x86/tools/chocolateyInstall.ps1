Set-StrictMode -Version latest
$ErrorAction = "Stop"
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$tmpDir = Join-Path $toolsDir "tmp"

# 1. Move msi isntaller away from install location
New-Item -Type Directory $tmpDir
$msi = Move-Item "$toolsDir/*.msi" $tmpDir -PassThru

# 2. Extract MSI
Start-Process -Wait msiexec @(
    "/a", $msi, "/passive", "/qn", "TARGETDIR=$toolsDir", "/liwe", "$toolsDir\msi.log"
)

# 2. Install pip
Start-Process -Wait -WindowStyle Hidden "$toolsDir\python.exe" `
    @( "-E", "-s", "-m", "ensurepip", "-U", "--default-pip" ) 

# 4. Cleanup
Remove-Item -Recurse $tmpDir | Out-Null

# 5. Register python environment
$version = $env:ChocolateyPackageVersion 
$versionShort = [String]::Join(".", $version.Split(".")[0..1])
$pyreg = @{
    "HKLM:\SOFTWARE\WOW6432Node\Python\PythonCore\$versionShort" = @{
        "DisplayName" = "Python $versionShort (32-bit, chocolatey)"
        "Version" = $version
        "SysVersion" = $versionShort
        "SysArchitecture" = "32bit"
        "SupportUrl" = "https://github.com/episource/my-chocolatey"
        "InstallPath" = @{
            "(default)" = $toolsDir
            "ExecutablePath" = "$toolsDir\python.exe"
            "WindowedExecutablePath" = "$toolsDir\pythonw.exe"
        }
    }
}
Install-RegistryImage $pyreg

# 6. Add startmenu entry & Configure shimgen
Install-StartMenuLink -LinkName "Python2 (x86)" -TargetPath "$toolsDir\python.exe"
Set-AutoShim -Pattern "**" -Mode Ignore | Out-Null
Install-Shim -Name "python2_x86" -Path "$toolsDir\python.exe"
Install-Shim -Name "pythonw2_x86" -Path "$toolsDir\pythonw.exe"
Install-Shim -Name "pip2_x86" -Path "$toolsDir\python.exe" -Arguments "-m pip"