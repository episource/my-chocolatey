Set-StrictMode -Version latest
$ErrorAction = "Stop"
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"

$installerExe = Get-Item "$toolsDir/*.exe"
Get-ChocolateyUnzip -FileFullPath $installerExe.FullName -Destination $toolsDir
Remove-Item $installerExe
Remove-Item "$toolsDir/uninstall.exe"

$exePath = $( Get-Item "$toolsDir\VirusTotalUploader*.exe" ).FullName
$contextMenu = @{
    "HKLM:\SOFTWARE\Classes\*\shell\chocolatey.vtuploader" = @{
        "(Default)" = "Send to VirusTotal"
        "Icon" = "$exePath,0"
        "command" = @{
            "(Default)" = "$exePath ""%1"""
        }
    }
}
Install-RegistryImage -debug -verbose $contextMenu