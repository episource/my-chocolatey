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

# Create a reduced set of shims
Set-AutoShim -Pattern "**" -Mode Ignore | Out-Null
Install-Shim -Name "java8" -Path "$toolsDir\bin\java.exe"
Install-Shim -Name "javaw8" -Path "$toolsDir\bin\javaw.exe"
Install-Shim -Name "javac8" -Path "$toolsDir\bin\javac.exe"
Install-Shim -Name "jdb8" -Path "$toolsDir\bin\jdb.exe"

# Install start menu shortcuts for jmc + jvisualvm
$startJconsole = @{ LinkName="Java8/Java Monitoring & Management Console (JConsole, JDK8)"; TargetPath="$toolsDir\bin\jconsole.exe" }
Install-StartMenuLink @startJconsole
$startJvisualvm = @{ LinkName="Java8/Java VisualVM  (JDK8)"; TargetPath="$toolsDir\bin\jvisualvm.exe" }
Install-StartMenuLink @startJvisualvm
$startJmc = @{ LinkName="Java8/Java Mission Control (JDK8)"; TargetPath="$toolsDir\bin\jmc.exe" }
Install-StartMenuLink @startJmc
   
# Register JDK to be found by launchers looking at oracles registry paths
# (e.g. launch4j)
$versionOut = & "$toolsDir/bin/java.exe" -version 2>&1
$versionOut[0] -match "^java version ""(?<INTERNAL_VERSION>[^""]+)""$" | Out-Null
$internalVersion = $Matches.INTERNAL_VERSION

$jdk = @{
    "HKLM:\SOFTWARE\JavaSoft\Java Development Kit" = @{
#        "CurrentVersion" = $internalVersion;
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
& cmd /c "assoc .jar8=$ftype"

$uninstallScript = "$toolsDir/chocolateyUninstall.ps1"
Add-Content $uninstallScript -Value "`n& cmd /c ""ftype $ftype="""
Add-Content $uninstallScript -Value "`n& cmd /c ""assoc .jar8="""
