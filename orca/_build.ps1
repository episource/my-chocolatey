# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1

# The url is for the Windows SDK 10.0.14393.33 containing Orca 5.0.10011.0
$sdkSetupUrl = "http://download.microsoft.com/download/6/3/B/63BADCE0-F2E6-44BD-B2F9-60F5F073038E/standalonesdk/SDKSETUP.EXE"
$sdkSetupSha256 = "23b87a221804a8db90bc4af7f974fd5601969d40936f856942aac5c9da295c04"
$orcaMsiSha256 = "c21991edb703c9863071aa7b1c5dc101318770ec1ed9506695c97c24ee997d2c"

# Get-Orca expects the location to be set to the package template's build
# location. This is done when run as prepare files hook.
function Get-Orca() {
    $ProgressBarActivity = "Retrieving Orca"
    If (-not (Get-Variable "ProgressBarId" -ErrorAction SilentlyContinue)) {
        $ProgressBarId = 0
    }
    
    function Update-Progress($percent, $status) {
        Write-Progress -Activity $ProgressBarActivity -Status $status `
            -Id $ProgressBarId -ParentId ($ProgressBarId - 1) -PercentComplete $percent
    }
    
    
    $tmpDir = New-Item "tmp" -Type Directory
    If (-not (Test-Path "tools")) {
        $toolsDir = New-Item "tools"
    }

    # 1. Download SDK Web Installer, which downloads required files on-demand
    Update-Progress 0 "Downloading Windows SDK..."
    
    $setupExe = Get-WebFile $sdkSetupUrl -OutFile $tmpDir
    $actualSetupSha256 = $(Get-FileHash $setupExe -Algorithm sha256).Hash
    If ($actualSetupSha256 -ne $sdkSetupSha256) {
        Throw "$setupExe has unexpected hash!`nActual: $actualSetupSha256`Expected:$sdkSetupSha256"
    }
    
    
    # 2. Use the web installer to download the MSI tools
    Update-Progress 25 "Using SDK Web Installer to download the MSI tools..."
    
    Start-Process -Wait $setupExe @("/q", "/layout", $tmpDir,
        "/features", "OptionId.MSIInstallTools")
        
    $orcaMsi = Get-Item "$tmpDir/Installers/Orca-x86_en-us.msi"
    $actualOrcaMsiSha256 = $(Get-FileHash $orcaMsi -Algorithm sha256).Hash
    If ($actualOrcaMsiSha256 -ne $orcaMsiSha256) {
        Throw "$orcaMsi has unexpected hash!`nActual: $actualOrcaMsiSha256`Expected:$orcaMsiSha256"
    }
    
    Update-Progress 50 "Extracting Orca..."
        
    # 3. Extract Orca
    Start-Process -Wait msiexec.exe @("/qn", "/a", $orcaMsi,
        "TARGETDIR=""$tmpdir""")
        
    Update-Progress 75 "Cleaning up files..."
        
    # 4. Cleanup
    Move-Item "$tmpDir/Orca/*" "tools"
    Remove-Item $tmpDir -Recurse
    
    Write-Progress -Completed -Id $ProgressBarId -Activity $ProgressBarActivity
}

New-Package -PrepareFilesHook { Get-Orca } -VersionInfo @{
    Version = "5.0.10011.0"
}