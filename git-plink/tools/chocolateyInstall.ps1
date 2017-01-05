Set-StrictMode -Version latest
$ErrorAction = "Stop"


$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$plinkExe = Resolve-Path "$toolsDir/../../putty/tools/PLINK.EXE"
Install-ChocolateyEnvironmentVariable `
    -VariableName 'GIT_SSH' -VariableType 'Machine' `
    -VariableValue "$plinkExe"