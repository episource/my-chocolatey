Set-StrictMode -Version latest
$ErrorAction = "Stop"
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"

# Extract
$inkscapeZip = Get-Item "$toolsDir/inkscape-*.7z"
Get-ChocolateyUnzip -FileFullPath $inkscapeZip.FullName -Destination $toolsDir
Remove-Item $inkscapeZip
Move-Item "$toolsDir/inkscape" "$toolsDir/_tmp_inkscape"
Move-Item "$toolsDir/_tmp_inkscape/*" "$toolsDir"
Remove-Item "$toolsDir/_tmp_inkscape"

# Configure Shims & Startmenu entries
Set-AutoShim -Pattern "inkscape.exe" -Invert -Mode Ignore | Out-Null
Install-StartMenuLink -LinkName "Inkscape" -TargetPath "$toolsDir/inkscape.exe"
