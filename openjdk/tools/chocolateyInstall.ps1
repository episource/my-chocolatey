Set-StrictMode -Version latest
$ErrorAction = "Stop"

$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"

# Extract JDK
$jdkZip = Get-Item "$toolsDir/java-*.zip"
Get-ChocolateyUnzip -FileFullPath $jdkZip.FullName -Destination $toolsDir
Remove-Item $jdkZip

$jdkName = $(Get-Item "$toolsDir/java-*")[-1].Name
$jdkDir = $(Get-Item "$toolsDir/java-*")[-1].FullName

# Move jdkDir content directly to tools dir
Get-Item "$jdkDir/*" | %{ Move-Item $_ $toolsDir } | Out-Null
Remove-Item $jdkDir

# Only create shims for the files listed in $withDefaultShim
$withDefaultShim = @(
    "$toolsDir\bin\javac.exe",
    "$toolsDir\bin\jconsole.exe",
    "$toolsDir\bin\jdb.exe",
    "$toolsDir\bin\java.exe",
    "$toolsDir\bin\javaw.exe"
)
Set-AutoShim -Pattern $withDefaultShim -Invert -Mode Ignore | Out-Null

# Install start menu shortcuts for jmc + jvisualvm
$startJconsole = @{ LinkName="Java/Java Monitoring & Management Console (JConsole)"; TargetPath="$toolsDir\bin\jconsole.exe" }
Install-StartMenuLink @startJconsole

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
