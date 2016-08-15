$packageName = 'HashCheck Shell Extension'
$toolsDir   = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$fileLocation = Get-ChildItem "$toolsDir/HashCheckSetup-v*.exe"
$installerType = 'exe'
$silentArgs = '/S'
$validExitCodes = @( 0 )

Install-ChocolateyInstallPackage - PackageName "$packageName" `
    -FileType "$installerType" -SilentArgs "$silentArgs" `
    -File "$fileLocation" -ValidExitCodes $validExitCodes
