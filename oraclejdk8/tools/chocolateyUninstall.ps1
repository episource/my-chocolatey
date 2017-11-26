Set-StrictMode -Version latest
$ErrorAction = "Stop"

$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"


# Uninstall JAVA_HOME
Uninstall-ChocolateyEnvironmentVariable `
    -VariableType 'Machine' -VariableName 'JAVA_HOME' 

    
