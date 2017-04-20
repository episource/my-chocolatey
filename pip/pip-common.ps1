Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1
Import-Module Pip-Package


function New-AutoPip() {
    Set-StrictMode -Off
    
    $pkgId -match "^(?<PYTHON>python.*)-pip-(?<PKG>.*)$" | Out-Null
    $pythonName = $Matches.PYTHON
    $pypiName = $Matches.PKG


    $pypiArgs = @{
        PypiPackage = "$pypiName"
        ChocoPackageMaintainer = "episource"
    }
    If ($maintainer) {
        $pypiArgs.ChocoPackageMaintainer = $maintainer
    }
    If ($postInstallScript) {
        $pypiArgs.PostInstallScript = $postInstallScript
    }
    If ($preUninstallScript) {
        $pypiArgs.PreUninstallScript = $preUninstallScript
    }
    If ($additionalDependencies) {
        $pypiArgs.AdditionalDependencies = $additionalDependencies
    }


    @( "$pythonName", "$pythonName-x86" ) | %{
        $pythonInfo = Select-BuildDependency -Name $_ -Detailed
        $pythonVer = $pythonInfo.Version
        
        $pypiArgs.PythonName = $_
        $pypiArgs.PythonVersion = $pythonVer
        New-PypiPackage @pypiArgs
    }
}