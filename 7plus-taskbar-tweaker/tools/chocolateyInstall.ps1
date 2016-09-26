$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
Set-Location $toolsDir

$installer = Get-Item "7tt_setup.exe"
Get-ChocolateyUnzip -FileFullPath $installer.FullName -Destination $toolsDir
Move-Item -Force "bin/64/7+ Taskbar Tweaker.ex2" "$toolsDir/7+ Taskbar Tweaker.exe"
Move-Item -Force "bin/64/inject.dll" "$toolsDir/inject.dll"
Remove-Item -Recurse bin
Remove-Item -Recurse '$PLUGINSDIR'
Remove-Item $installer

Install-StartMenuLink -LinkName "7+ Taskbar Tweaker" `
        -TargetPath "$toolsDir\7+ Taskbar Tweaker.exe"
        
$exe = Get-Item "7+ Taskbar Tweaker.exe"
$autostart = @{
    "SOFTWARE\Microsoft\Windows\CurrentVersion\Run" = @{
        "7 Taskbar Tweaker" = """$($exe.FullName)"" -hidewnd"
    }
}
Install-UserProfileRegistryImage -Image $autostart -Force