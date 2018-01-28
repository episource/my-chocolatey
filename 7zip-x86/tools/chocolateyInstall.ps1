$toolsDir    = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$sevenzipDir = "${env:ProgramFiles(x86)}\7-Zip"
Set-Location $toolsDir


$msiArgs  = '/quiet /qn /norestart'
$validExitCodes = @(
    # https://msdn.microsoft.com/en-us/library/windows/desktop/aa376931(v=vs.85).aspx
    0,   # all ok
    3010 #reboot required
)


$msiFile = Get-Item *.msi | Select-Object -First 1 -ExpandProperty FullName
Install-ChocolateyInstallPackage -PackageName $env:chocolateyPackageName `
    -File $msiFile -FileType 'msi' -ValidExitCodes $validExitCodes `
    -SilentArgs $msiArgs 
    
Install-Shim -Name "7z" -Path "$sevenzipDir\7z.exe"