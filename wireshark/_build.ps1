# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


New-Package -VersionInfo @{
    FileUrl="https://1.eu.dl.wireshark.org/win64/Wireshark-latest-x64.exe"
    Version="file:tools/Wireshark-latest-x64.exe"
}