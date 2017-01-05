Set-StrictMode -Version latest
$ErrorAction = "Stop"


Uninstall-ChocolateyEnvironmentVariable `
    -VariableName 'GIT_SSH' -VariableType 'Machine'