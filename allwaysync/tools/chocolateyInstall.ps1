Set-StrictMode -Version latest
$ErrorAction = "Stop"


# Extract msi
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$msi      = Get-Item "$toolsDir\allwaysync-x64-*.msi"
$pkg      = Move-Item $msi "$toolsDir\.." -PassThru

Start-Process -Wait msiexec @(
    "/a", $pkg, "/passive", "/qn", "TARGETDIR=$toolsDir",
    "/liwe", "$toolsDir\msi.log"
)

Remove-Item $msi
Remove-Item $pkg

# Add startmenu entry
$exe      = Join-Path $toolsDir "Bin\syncappw.exe"
Install-StartMenuLink -LinkName "Allway Sync" -TargetPath $exe

# Do not create any shims
Set-AutoShim -Pattern "**" -Mode Ignore | Out-Null