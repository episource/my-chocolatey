Set-StrictMode -Version latest
$ErrorAction = "Stop"
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$setupDir = Join-Path $toolsDir "_setup"

# 1. Extract Features
# See also:
# -> https://docs.python.org/3/using/windows.html
# -> https://github.com/python/cpython/tree/master/Tools/msi/bundle
# Excluded features:
# -> launcher.msi: separate package
# -> path.msi: adds python directories to the path - replaced by shims
# -> test.msi: standard library test suite not needed for normal use
# -> pip.msi: doesn't contain any files, but runs ensurepip instead
# -> *.msu: VCRuntime - not needed @win10
@("core.msi", "exe.msi", "lib.msi", "doc.msi", "dev.msi", "tcltk.msi", "tools.msi" ) | %{
    Start-Process -Wait msiexec @(
        "/a", "$setupDir\AttachedContainer\$_", "/passive", "/qn", "TARGETDIR=$toolsDir", "/liwe", "$toolsDir\$_.log"
    )
}

# 2. Install pip
Start-Process -Wait -WindowStyle Hidden "$toolsDir\python.exe" `
    @( "-E", "-s", "-m", "ensurepip", "-U", "--default-pip" ) 

# 3. Cleanup
Remove-Item -Recurse $setupDir | Out-Null

# 4. Register python environment
$version = $env:ChocolateyPackageVersion 
$versionShort = [String]::Join(".", $version.Split(".")[0..1])
$pyreg = @{
    "HKLM:\SOFTWARE\Python\PythonCore\$versionShort" = @{
        "DisplayName" = "Python $versionShort (64-bit, chocolatey)"
        "Version" = $version
        "SysVersion" = $versionShort
        "SysArchitecture" = "64bit"
        "SupportUrl" = "https://github.com/episource/my-chocolatey"
        "InstallPath" = @{
            "(default)" = $toolsDir
            "ExecutablePath" = "$toolsDir\python.exe"
            "WindowedExecutablePath" = "$toolsDir\pythonw.exe"
        }
    }
}
Install-RegistryImage $pyreg

# 5. Add startmenu entry & Configure shimgen
Install-StartMenuLink -LinkName "Python3" -TargetPath "$toolsDir\python.exe"
Set-AutoShim -Pattern "**" -Mode Ignore | Out-Null
Install-Shim -Name "python3" -Path "$toolsDir\python.exe"
Install-Shim -Name "pythonw3" -Path "$toolsDir\pythonw.exe"
Install-Shim -Name "pip3" -Path "$toolsDir\python.exe" -Arguments "-m pip"