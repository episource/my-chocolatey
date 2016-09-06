$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
Set-Location $toolsDir


$msiArgs  = '/quiet /qn /norestart REBOOT=ReallySupress ADDLOCAL=ALL REMOVE=CrashReporter,ProtocolAssocGithub,ProtocolAssocSmartgit'
$validExitCodes = @(
    # https://msdn.microsoft.com/en-us/library/windows/desktop/aa376931(v=vs.85).aspx
    0,   # all ok
    3010 #reboot required
)

$tgitRegistryImage = @{
    "SOFTWARE\TortoiseGit" = @{
        # Tell TortoiseGit where to find git-for-windows
        MSysGit = Resolve-Path ../../git/tools/bin/ | `
            Select-Object -ExpandProperty Path
    }
}


$msiFile = Get-Item *.msi | Select-Object -First 1 -ExpandProperty FullName
Install-ChocolateyInstallPackage -PackageName $env:chocolateyPackageName `
    -File $msiFile -FileType 'msi' -ValidExitCodes $validExitCodes `
    -silentArgs $msiArgs 
Install-UserProfileRegistryImage -Image $tgitRegistryImage -Force