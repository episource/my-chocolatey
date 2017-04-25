# Enable common parameters
[CmdletBinding()] Param()
. $PSScriptRoot/../pip-common.ps1


$pkgId = $(Get-Item $MyInvocation.MyCommand.Definition).Directory.Name
$additionalDependencies = @( 
    @{ Id = "vcpython27"; Version="[9.0.0,)" }
)
New-AutoPip