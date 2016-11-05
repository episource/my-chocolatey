# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


# Note: this file should be encoded as "UTF8 with BOM"
Throw "Not implemented"

$versionInfo = # TODO
New-Package -VersionInfo $versionInfo