# Enable common parameters
[CmdletBinding()] Param()
. $PSScriptRoot/../pip-common.ps1


$pkgId = $(Get-Item $MyInvocation.MyCommand.Definition).Directory.Name
New-AutoPip