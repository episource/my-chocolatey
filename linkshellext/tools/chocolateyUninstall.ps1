Set-StrictMode -Version latest
$ErrorAction = "Stop"


$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$programName = "Link Shell Extension"
$setupArgs = "/S"
$validExitCodes = @(0)

Get-ItemProperty -ErrorAction:SilentlyContinue -Path @( 
        'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' 
    ) | Where-Object { 
        $_.PSObject.Properties.Name.Contains('DisplayName') `
            -and $_.DisplayName -eq $programName 
    } | ForEach-Object { 
        Uninstall-ChocolateyPackage -PackageName $env:chocolateyPackageName `
            -File $_.UninstallString.Trim('"') -FileType "exe" `
            -ValidExitCodes $validExitCodes  -SilentArgs $setupArgs
    }