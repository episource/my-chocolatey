$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$commonTools = Join-Path $toolsDir "../../notepadplusplus-config-common/tools"
$nppPackageDir = Join-Path $toolsDir "../../notepadplusplus-x86"


& "$commonTools/UninstallConfig.ps1" $nppPackageDir