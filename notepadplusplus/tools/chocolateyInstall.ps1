. $PSScriptRoot/chocolateyCommon.ps1

# Enable per-user configuration
Remove-Item -Path "$destDir/doLocalConf.xml"


# Install start menu shortcut
Install-StartMenuLink -LinkName $startName -TargetPath $exe


# Install context menu entry
$menuCmdKey = "$menuKey/Command"
If (-not (Test-Path -LiteralPath $menuKey)) {
    New-Item -Path $menuKey
}
Set-ItemProperty -LiteralPath $menuKey -Name "(Default)" -Value $menuEntry
Set-ItemProperty -LiteralPath $menuKey -Name "Icon" -Value $exe

If (-not (Test-Path -LiteralPath $menuCmdKey)) {
    New-Item -Path $menuCmdKey
}
Set-ItemProperty -LiteralPath $menuCmdKey -Name "(Default)" -Value $menuCmd