$packageName = 'HashCheck Shell Extension'
$toolsDir   = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$fileLocation = Join-Path $toolsDir 'HashCheckSetup.exe'
$installerType = 'exe'
$silentArgs = '/S'
$validExitCodes = @(0)

Install-ChocolateyInstallPackage "$packageName" "$installerType" "$silentArgs" "$fileLocation" $validExitCodes
