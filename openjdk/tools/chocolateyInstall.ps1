Set-StrictMode -Version latest
$ErrorAction = "Stop"

$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"

# Extract JDK
$jdkZip = Get-Item "$toolsDir/java-*.zip"
Get-ChocolateyUnzip -FileFullPath $jdkZip.FullName -Destination $toolsDir
Remove-Item $jdkZip

$jdkName = $(Get-Item "$toolsDir/java-*").Name
$jdkDir = $(Get-Item "$toolsDir/java-*").FullName

# Only create shims for the files listed in $withDefaultShim
$withDefaultShim = @(
    "$jdkName\bin\javac.exe",
    "$jdkName\bin\jconsole.exe",
    "$jdkName\bin\jdb.exe",
    "$jdkName\bin\java.exe",
    "$jdkName\bin\javaw.exe"
)
Set-AutoShim -Pattern $withDefaultShim -Invert -Mode Ignore | Out-Null

# Install start menu shortcuts for jmc + jvisualvm
$startJconsole = @{ LinkName="Java/Java Monitoring & Management Console (JConsole)"; TargetPath="$jdkDir\bin\jconsole.exe" }
Install-StartMenuLink @startJconsole

# Setup JAVA_HOME
Install-ChocolateyEnvironmentVariable -VariableType "Machine" `
    -VariableName "JAVA_HOME" -VariableValue "$jdkDir"
    
# Register JDK to be found by launchers looking at oracles registry paths
# (e.g. launch4j)
$versionOut = & "$jdkDir/bin/java.exe" -version 2>&1
$versionOut[0] -match "^openjdk version ""(?<INTERNAL_VERSION>[^""]+)""" | Out-Null
$internalVersion = $Matches.INTERNAL_VERSION

$jdk = @{
    "HKLM:\SOFTWARE\JavaSoft\Java Development Kit" = @{
        "CurrentVersion" = $internalVersion;
        "$internalVersion" = @{
            "JavaHome" = $jdkDir;
            "RuntimeLib" = "$jdkDir\bin\server\jvm.dll"
        }
    }
}
Install-RegistryImage -Force $jdk

# Associate *.jar with javaw.exe 
# (global HKCR associaton, might be overwritten by HKCU:SOFTWARE\Classes\.jar)
$ftype = "jar_jdk-$internalVersion"
& cmd /c "ftype $ftype=""$jdkDir\bin\javaw.exe"" -jar ""%1"" ""%~1"""
& cmd /c "assoc .jar=$ftype"

$uninstallScript = "$jdkDir/chocolateyUninstall.ps1"
Add-Content $uninstallScript -Value "`n& cmd /c ""ftype $ftype="""
Add-Content $uninstallScript -Value "`n& cmd /c ""assoc .jar="""
