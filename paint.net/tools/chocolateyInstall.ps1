Set-StrictMode -Version latest
$ErrorAction = "Stop"


$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$tmpDir = Join-Path $toolsDir "tmp"

# 1. Extract Installer
$instExe = Get-Item "$toolsDir\paint.net*install.exe"
Get-ChocolateyUnzip -FileFullPath $instExe.FullName -Destination $tmpDir

# 2. Extract MSI
$msi = Get-Item "$tmpDir\PaintDotNet_x64.msi"
Start-Process -Wait msiexec @(
    "/a", $msi, "/passive", "/qn", "TARGETDIR=$toolsDir", "CHECKFORUPDATES=0",
    "/liwe", "$toolsDir\msi.log"
)

# 3. Cleanup
Remove-Item $instExe | Out-Null
Remove-Item -Recurse $tmpDir | Out-Null

# 4. Add startmenu entry & Configure shimgen
Install-StartMenuLink -LinkName "Paint.NET" -TargetPath "$toolsDir\PaintDotNet.exe"
Set-AutoShim -Pattern "PaintDotNet.exe" -Invert -Mode Ignore | Out-Null