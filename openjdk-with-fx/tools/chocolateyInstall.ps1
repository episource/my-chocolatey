Set-StrictMode -Version latest
$ErrorAction = "Stop"

$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"

$jdkZip = Get-Item "$toolsDir/java-*.zip"
$fxSdkZip = Get-Item "$toolsDir/openjfx-*sdk.zip"
$fxJmodsZip = Get-Item "$toolsDir/openjfx-*jmods.zip"


# Extract FX first so that newer jdk components replace duplicates
Get-ChocolateyUnzip -FileFullPath $fxSdkZip.FullName -Destination $toolsDir
Remove-Item $fxSdkZip

$fxSdkDir = $(Get-Item "$toolsDir/javafx-sdk*")[-1].FullName
Remove-Item "$fxSdkDir/lib/src.zip" | Out-Null
Get-Item "$fxSdkDir/*" | %{ Move-Item -Force $_ $toolsDir } | Out-Null
Remove-Item "$fxSdkDir" | Out-Null


# Append FX Jmods
Get-ChocolateyUnzip -FileFullPath $fxJmodsZip.FullName -Destination $toolsDir
Remove-Item $fxJmodsZip | Out-Null

$fxJmodsDir = $(Get-Item "$toolsDir/javafx-jmods*")[-1].FullName
Move-Item -Force $fxJmodsDir "$toolsDir/jmods" | Out-Null


# Extract and move JDK
Get-ChocolateyUnzip -FileFullPath $jdkZip.FullName -Destination $toolsDir
Remove-Item $jdkZip

$jdkDir = $(Get-Item "$toolsDir/java-*-openjdk-*")[-1].FullName
$jdkName = $(Get-Item "$toolsDir/java-*-openjdk-*")[-1].Name

# Move jdkDir content directly to tools dir
# Note: Powershell hosted by chocolatey can't handle unicode paths (\\?\) needed for paths longer than 260 characters
Remove-Item "$jdkDir/lib/src.zip" | Out-Null
& powershell -Command @"
Get-ChildItem -File -Recurse '$jdkDir' | %{
    `$src = `$_.FullName
    `$relParent = Split-Path `$src.Replace('$jdkDir','')
    `$targetDir = Join-Path '$toolsDir' `$relParent
    New-Item -Type directory -Force "\\?\`$targetDir" | Out-Null
    Move-Item -Force -LiteralPath "\\?\`$src" -Destination "\\?\`$targetDir"
}
Remove-Item -Recurse -LiteralPath '\\?\$jdkDir'
"@

# Only create shims for the files listed in $withDefaultShim
$withDefaultShim = @(
    "$toolsDir\bin\javac.exe",
    "$toolsDir\bin\jconsole.exe",
    "$toolsDir\bin\jdb.exe",
    "$toolsDir\bin\java.exe",
    "$toolsDir\bin\javaw.exe",
    "$toolsDir\missioncontrol\jmc.exe"
)
Set-AutoShim -Pattern $withDefaultShim -Invert -Mode Ignore | Out-Null

# Install start menu shortcuts for jmc + jvisualvm
$startJconsole = @{ LinkName="Java/Java Monitoring & Management Console (JConsole)"; TargetPath="$toolsDir\bin\jconsole.exe" }
Install-StartMenuLink @startJconsole
$startJmc = @{ LinkName="Java/Java Mission Control"; TargetPath="$toolsDir\missioncontrol\jmc.exe" }
Install-StartMenuLink @startJmc

# Setup JAVA_HOME
Install-ChocolateyEnvironmentVariable -VariableType "Machine" `
    -VariableName "JAVA_HOME" -VariableValue "$toolsDir"
    
# Register JDK to be found by launchers looking at oracles registry paths
# (e.g. launch4j)
$versionOut = & "$toolsDir/bin/java.exe" -version 2>&1
$versionOut[0] -match "^openjdk version ""(?<INTERNAL_VERSION>[^""]+)""" | Out-Null
$internalVersion = $Matches.INTERNAL_VERSION

$jdk = @{
    "HKLM:\SOFTWARE\JavaSoft\Java Development Kit" = @{
        "CurrentVersion" = $internalVersion;
        "$internalVersion" = @{
            "JavaHome" = $toolsDir;
            "RuntimeLib" = "$toolsDir\bin\server\jvm.dll"
        }
    }
}
Install-RegistryImage -Force $jdk

# Associate *.jar with javaw.exe 
# (global HKCR associaton, might be overwritten by HKCU:SOFTWARE\Classes\.jar)
$ftype = "jar_jdk-$internalVersion"
& cmd /c "ftype $ftype=""$toolsDir\bin\javaw.exe"" -jar ""%1"" ""%~1"""
& cmd /c "assoc .jar=$ftype"

$uninstallScript = "$toolsDir/chocolateyUninstall.ps1"
Add-Content $uninstallScript -Value "`n& cmd /c ""ftype $ftype="""
Add-Content $uninstallScript -Value "`n& cmd /c ""assoc .jar="""
