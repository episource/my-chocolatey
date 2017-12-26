using namespace System.Security.AccessControl
using namespace System.Security.Principal

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
$usersSid = [SecurityIdentifier]::new([WellKnownSidType]::BuiltinUsersSid, $null)
$usersFullControlAr = [FileSystemAccessRule]::new($usersSid, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($usersFullControlAr)
Set-Acl $settingsDir $acl

@( "x64", "x32" ) | % {
    $platform = $_
    
    # world-writable symbols directory
    $symSrc = "$toolsDir/release/$platform/symbols"
    $symSrcItem = Get-Item $symSrc -ErrorAction SilentlyContinue
    $symTgt = "$settingsDir/symbols"
    
    If ($symSrcItem -and $symSrcItem.Attributes -match "ReparsePoint") {
        # link already exists - nothing to do
    } Else {
        If ($symSrcItem) {
            $symBak = "$symSrc.bak"
            Remove-Item -R $symBak -ErrorAction SilentlyContinue
            Move-Item $symSrc $symSrcBak
        }
        
        New-Item -Type Directory $symTgt -ErrorAction SilentlyContinue
        New-Item -Path $symSrc -ItemType SymbolicLink -Value $symTgt
    }
        
    # world-writable configuration file
    @( "${platform}dbg.ini", "snowman.ini" ) | %{
        $iniSrc = "$toolsDir/release/$platform/$_"
        $iniSrcItem = Get-Item $iniSrc -ErrorAction SilentlyContinue
        $iniTgt = "$settingsDir/$(Split-Path -Leaf $iniSrc)"
        
        If ($iniSrcItem -and $iniSrcItem.Attributes -match "ReparsePoint" ) {
            # link already exists - nothing to do
        } Else {
            If ($iniSrcItem) {
                $iniBak = "$iniSrc.bak"
                Remove-Item $iniBak -ErrorAction SilentlyContinue
                Move-Item $iniSrc $iniBak
            }
            
            "" >> $iniTgt
            New-Item -Path $iniSrc -ItemType SymbolicLink -Value $iniTgt
        }
    }
    
    # world-writable database directory
    # note: currently db compression needs to be disabled for x64dbg to pickup
    # database files from this directory
    $dbSrc = "$toolsDir/release/$platform/db"
    $dbSrcItem = Get-Item $dbSrc -ErrorAction SilentlyContinue
    $dbTgt = "$settingsDir/db"
    
    If ($dbSrcItem -and $dbSrcItem.Attributes -match "ReparsePoint") {
        # link already exists - nothing to do
    } Else {
        If ($dbSrcItem) {
            $dbBak = "$dbSrc.bak"
            Remove-Item -R $dbBak -ErrorAction SilentlyContinue
            Move-Item $dbSrc $dbSrcBak
        }
        
        New-Item -Type Directory $dbTgt -ErrorAction SilentlyContinue
        New-Item -Path $dbSrc -ItemType SymbolicLink -Value $dbTgt
    }
}

# re-install active plugins
choco list -l | Select-String "x64dbg-" | %{
    $pluginInfo = "$_".Split(" ")
    $pName = $pluginInfo[0]
    $pVersion = $pluginInfo[1]
    
    choco install $pName --version=$pVersion --force
}
