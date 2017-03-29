Set-StrictMode -Version latest
$ErrorAction = "Stop"


# Extract msi
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$msi      = Get-Item "$toolsDir\VelocitySetup*.msi"
$pkg      = Move-Item $msi "$toolsDir\.." -PassThru

Start-Process -Wait msiexec @(
    "/a", $pkg, "/passive", "/qn", "TARGETDIR=$toolsDir",
    "/liwe", "$toolsDir\msi.log"
)

Remove-Item $msi
Remove-Item $pkg

# Add startmenu entry
$exe      = Join-Path $toolsDir "Silverlake Software LLC\Velocity\Velocity.exe"
Install-StartMenuLink -LinkName "Velocity" -TargetPath $exe

# Do not create any shims
Set-AutoShim -Pattern "**" -Mode Ignore | Out-Null