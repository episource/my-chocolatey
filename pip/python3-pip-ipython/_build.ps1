# Enable common parameters
[CmdletBinding()] Param()
. $PSScriptRoot/../pip-common.ps1

$pkgId = $(Get-Item $MyInvocation.MyCommand.Definition).Directory.Name
$additionalDependencies = @( 
    @{ Id = "startmenu.extension"; Version="[1.1.1,)" }
    @{ ID = "shimgen.extension"; Version="[2.0.2,)" }
)
$postInstallScript = @"
Install-StartMenuLink -LinkName "i`$pythonName" -TargetPath "`$pythonToolsDir\scripts\ipython.exe"
Install-Shim -Name "i`$pythonName" -Path "`$pythonToolsDir\scripts\ipython.exe"
"@

New-AutoPip