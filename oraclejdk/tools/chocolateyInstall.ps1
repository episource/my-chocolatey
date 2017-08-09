Set-StrictMode -Version latest
$ErrorAction = "Stop"

$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$tmpDir = Join-Path $toolsDir "tmp"


# Extract tools.zip
# Credits: https://techtavern.wordpress.com/2014/03/25/portable-java-8-sdk-on-windows/
$installerExe = Get-Item "$toolsDir/jdk-*windows-x64.exe"
Get-ChocolateyUnzip -FileFullPath $installerExe.FullName -Destination $tmpDir
$jdkCab = Get-Item "$tmpDir/.rsrc/1033/JAVA_CAB10/111"
Get-ChocolateyUnzip -FileFullPath $jdkCab.FullName -Destination $tmpDir
$jdkZip = Get-Item "$tmpDir/tools.zip"
Get-ChocolateyUnzip -FileFullPath $jdkZip.FullName -Destination $toolsDir

# Cleanup tmpDir + original installerExe
Remove-Item $installerExe
Remove-Item -Recurse $tmpDir

# Extract pack files
$unpackExe = Get-Item "$toolsDir/bin/unpack200.exe"
Get-ChildItem -Recurse $toolsDir  -Filter "*.pack" | %{
    $newName = $_.FullName -replace "\.pack$",".jar"
    & $unpackExe -r $_.FullName $newName
}

# Only create shims for the files listed in $withDefaultShim
$withDefaultShim = @(
    "$toolsDir\bin\javac.exe",
    "$toolsDir\bin\jconsole.exe",
    "$toolsDir\bin\jdb.exe",
    "$toolsDir\bin\jmc.exe",
    "$toolsDir\bin\jvisualvm.exe",
    "$toolsDir\bin\java.exe",
    "$toolsDir\bin\javaw.exe"
)
Set-AutoShim -Pattern $withDefaultShim -Invert -Mode Ignore | Out-Null

# Install start menu shortcuts for jmc + jvisualvm
$startJconsole = @{ LinkName="Java/Java Monitoring & Management Console (JConsole)"; TargetPath="$toolsDir\bin\jconsole.exe" }
Install-StartMenuLink @startJconsole
$startJvisualvm = @{ LinkName="Java/Java VisualVM"; TargetPath="$toolsDir\bin\jvisualvm.exe" }
Install-StartMenuLink @startJvisualvm
$startJmc = @{ LinkName="Java/Java Mission Control"; TargetPath="$toolsDir\bin\jmc.exe" }
Install-StartMenuLink @startJmc

# Setup JAVA_HOME
Install-ChocolateyEnvironmentVariable -VariableType "Machine" `
    -VariableName "JAVA_HOME" -VariableValue "$toolsDir"
    
# Register JDK to be found by launchers looking at oracles registry paths
# (e.g. launch4j)
$versionOut = & "$toolsDir/bin/java.exe" -version 2>&1
$versionOut[0] -match "^java version ""(?<INTERNAL_VERSION>[^""]+)""$" | Out-Null
$internalVersion = $Matches.INTERNAL_VERSION

$jdk = @{
    "HKLM:\SOFTWARE\JavaSoft\Java Development Kit" = @{
        "CurrentVersion" = $internalVersion;
        "$internalVersion" = @{
            "JavaHome" = $toolsDir;
            "RuntimeLib" = "$toolsDir\jre\bin\server\jvm.dll"
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
