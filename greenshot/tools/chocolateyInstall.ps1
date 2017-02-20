Set-StrictMode -Version latest
$ErrorAction = "Stop"


$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"

# Enable per-user configuration
Remove-Item "$toolsDir/greenshot.ini"

# Start Menu
$exe = Get-Item "$toolsDir/Greenshot.exe"
Install-StartMenuLink -LinkName "Greenshot" -TargetPath $exe

# Autostart
$autostart = @{
    "SOFTWARE\Microsoft\Windows\CurrentVersion\Run" = @{
        "Greenshot" = """$($exe.FullName)"""
    }
}
Install-UserProfileRegistryImage -Image $autostart -Force