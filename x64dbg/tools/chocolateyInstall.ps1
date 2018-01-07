using namespace System.Security.AccessControl
using namespace System.Security.Principal

Set-StrictMode -Version latest
$ErrorAction = "Stop"
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"


Set-AutoShim -Pattern "**" -Mode Ignore | Out-Null
Install-StartMenuLink -LinkName "x64dbg (x86)" -TargetPath "$toolsDir\release\x32\x32dbg.exe"
Install-StartMenuLink -LinkName "x64dbg (x64)" -TargetPath "$toolsDir\release\x64\x64dbg.exe"


# Access rules & security identifiers needed below
$usersSid = [SecurityIdentifier]::new([WellKnownSidType]::BuiltinUsersSid, $null)
$ownersSid = [SecurityIdentifier]::new([WellKnownSidType]::CreatorOwnerSid, $null)
$usersCreateChildren = [FileSystemAccessRule]::new($usersSid, "CreateFiles,CreateDirectories", "ContainerInherit,ObjectInherit", "None", "Allow")
$usersCanModifyChildren = [FileSystemAccessRule]::new($usersSid, "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
$usersCantDeleteThis = [FileSystemAccessRule]::new($usersSid, "Delete", "None", "None", "Deny")
$ownersCanModifyChildren = [FileSystemAccessRule]::new($ownersSid, "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")

# world-writable data directory at an central place
$settingsDir = "$env:ProgramData/x64dbg"
New-Item -Type Directory "$env:ProgramData/x64dbg" -ErrorAction SilentlyContinue
$acl = Get-Acl $settingsDir
$acl.SetAccessRule($usersCanModifyChildren)
Set-Acl $settingsDir $acl

@( "x64", "x32" ) | % {     
    $platform = $_
    $binDir = "$toolsDir/release/$platform"
    
    # permit temporary files in program directories
    $acl = Get-Acl $binDir
    $acl.SetAccessRule($usersCreateChildren)
    $acl.SetAccessRule($ownersCanModifyChildren)
    Set-Acl $binDir $acl
  
    # world-writable configuration files
    @( "${platform}dbg.ini", "snowman.ini" ) | %{
        $iniLnk = "$binDir/$_"
        $iniLnkItem = Get-Item $iniLnk -ErrorAction SilentlyContinue
        $iniFile = "$settingsDir/$_"
        New-Item -Type File $iniFile -ErrorAction SilentlyContinue
        "" >> $iniFile
        
        # prevent users from deleting config files
        $acl = Get-Acl $iniFile
        $acl.SetAccessRule($usersCantDeleteThis)
        Set-Acl $iniFile $acl
        
        If ($iniLnkItem -and $iniLnkItem.Attributes -match "ReparsePoint" ) {
            # link already exists - nothing to do
        } Else {
            If ($iniLnkItem) {
                $iniBak = "$iniLnk.bak"
                Remove-Item $iniBak -ErrorAction SilentlyContinue
                Move-Item $iniLnk $iniBak
            }
            
            
            New-Item -Path $iniLnk -ItemType SymbolicLink -Value $iniFile
        }
    }
    
    # world-writable data directories
    @( "db", "memdumps", "symbols" ) | %{
        $dirLnk = "$binDir/$_"
        $dirLnkItem = Get-Item $dirLnk -ErrorAction SilentlyContinue
        $dirTgt = "$settingsDir/$_"
        New-Item -Type Directory $dirTgt -ErrorAction SilentlyContinue
        
        If ($dirLnkItem -and $dirLnkItem.Attributes -match "ReparsePoint") {
            # link already exists - nothing to do
        } Else {
            If ($dirLnkItem) {
                $dirBak = "$dirLnk.bak"
                Remove-Item -R $dirBak -ErrorAction SilentlyContinue
                Move-Item $dirLnk $dirBak
            }
            
            New-Item -Path $dirLnk -ItemType SymbolicLink -Value $dirTgt
        }
    }
}

# re-install active plugins
choco list -l | Select-String "x64dbg-" | %{
    $pluginInfo = "$_".Split(" ")
    $pName = $pluginInfo[0]
    $pVersion = $pluginInfo[1]
    
    choco install $pName --version=$pVersion --force
}
