Set-StrictMode -Version latest
$ErrorAction = "Stop"
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"


# Extract MSI
$tmpDir = Join-Path $toolsDir "tmp"
New-Item -Type Directory $tmpDir | Out-Null
$msi = Move-Item -PassThru "$toolsDir/*.msi" $tmpDir

Start-Process -Wait msiexec @(
    "/a", $msi, "/passive", "/qn", "TARGETDIR=$toolsDir", "/liwe", "$toolsDir\msi.log"
)

Remove-Item $msi
Move-Item "$toolsDir/Microsoft" $tmpDir
Move-Item "$tmpDir/Microsoft/Visual C++ for Python/*/*" $toolsDir


# Cleanup
Remove-Item -Recurse $tmpDir


# distutils expect vcvarsall.bat to be in VS90COMNTOOLS\..\..\VC
# => create common tools directory like vs
New-Item -Type Directory "$toolsDir/Common/Tools" | Out-Null
Add-Content -Path "$toolsDir/VC/vcvarsall.bat" -Value "@call ""%~dp0\..\vcvarsall.bat"" %*"


# Disable shims
Set-AutoShim -Pattern "**" -Mode Ignore | Out-Null