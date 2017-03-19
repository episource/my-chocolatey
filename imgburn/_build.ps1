# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


Select-BuildDependency -Name "7zip" -MinVersion "16.4.0" | Out-Null
$dlIndexUrl = "http://www.imgburn.com/index.php?act=download"
$dlIndexRaw = Invoke-WebRequest -UseBasicParsing $dlIndexUrl

$dlIndexRaw -match "(?<FILEURL>http://download.imgburn.com/SetupImgBurn_(?<VERSION>(?:\d+\.){2,3}\d+).exe)" | %{
    If (-not $_) { Write-Error "Failed to parse imgburn's web page." }
}
$fileUrl = $Matches.FILEURL
$version = $Matches.VERSION
$dlIndexRaw -match "MD5: (?<MD5>[a-fA-F0-9]{32})" | %{
    If (-not $_) { Write-Error "Failed to parse imgburn's web page." }
}
$md5 = $Matches.MD5

if (Get-Variable -Scope global -Name "CFVtApiKey" -ErrorAction SilentlyContinue) {
    Write-Warning "Virustotal might report about malware/adware: the installer of imgburn is known to install malware if the user isn't very careful. This build script does not execute the installer, but uses 7zip to extract its content. See malware-info.readme.txt for details."
}
New-Package -VersionInfo @{ Version=$version } -PrepareFiles {
    Import-PackageResource -Url $fileUrl -Checksum "md5:$md5" `
        -TargetDirectory "." -TargetName "setup.bundle"
    
    # extract at build-time so that the malicious installer won't be located in
    # the final nupkg (which in turn might be detected by virus scanners)
    & 7z.exe x -aoa -bd -bb1 -tNsis -x!'uninstall.exe' -x!'$PLUGINSDIR' setup.bundle -o'tools'
    If ($LastExitCode -ne 0) {
        Write-Error "Extracting imgburn failed!"
        return
    }
    
    Remove-Item "setup.bundle"
}