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

# 3. Cleanup
Remove-Item -Recurse $tmpDir | Out-Null

# 4. Add startmenu entry & Configure shimgen
Install-StartMenuLink -LinkName "Python2" -TargetPath "$toolsDir\python.exe"
Set-AutoShim -Pattern "**" -Mode Ignore | Out-Null
Install-Shim -Name "python2" -Path "$toolsDir\python.exe"
Install-Shim -Name "pythonw2" -Path "$toolsDir\pythonw.exe"