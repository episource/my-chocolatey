Set-StrictMode -Version latest
$ErrorAction = "Stop"
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"


Set-AutoShim -Pattern "**" -Mode Ignore | Out-Null
Install-StartMenuLink -LinkName "x64dbg (x86)" -TargetPath "$toolsDir\release\x32\x32dbg.exe"
Install-StartMenuLink -LinkName "x64dbg (x64)" -TargetPath "$toolsDir\release\x64\x64dbg.exe"

# create world-writable settings at an central place
$settingsDir = "$env:ProgramData/x64dbg"
New-Item -Type Directory "$env:ProgramData/x64dbg" -ErrorAction SilentlyContinue
$acl = Get-Acl $settingsDir
$usersFullControlAr = [System.Security.AccessControl.FileSystemAccessRule]::new("BUILTIN\Users", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($usersFullControlAr)
Set-Acl $settingsDir $acl

@( "x64", "x32" ) | % {
    $platform = $_
    
    New-Item -Type Directory "$settingsDir/symbols" -ErrorAction SilentlyContinue
    New-Item -Path "$toolsDir/release/$platform/symbols" -ItemType SymbolicLink -Value "$settingsDir/symbols"

    @( "x64dbg.ini", "snowman.ini" ) | %{
        $iniSrc = "$toolsDir/release/$platform/$_"
        $iniTgt = "$settingsDir/$(Split-Path -Leaf $iniSrc)"
        
        "" >> $iniTgt
        New-Item -Path $iniSrc -ItemType SymbolicLink -Value $iniTgt
    }
}
