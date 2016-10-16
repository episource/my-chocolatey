$toolsDir  = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"

# Resolve relative path => get-item
$gitDir    = Get-Item (Join-Path $toolsDir "../../git/tools")
$gitBinDir = Join-Path $gitDir "bin"
$gitIcon   = Join-Path $gitDir "usr/share/git/git-for-windows.ico"
$bashExe   = Join-Path $gitBinDir "bash.exe"
$taskName  = "{Dev::Git Bash}"

@(
    @{
        "_SortKey" = "410"
        "Active"   = 0x00000000
        "GuiArgs"  = "/icon $gitIcon"
        "Cmd1"     = "set PATH=""$gitBinDir;%PATH%"" & $bashExe --login -i"
        "Count"    = 0x00000001
        "Flags"    = 0x00000000
        "Hotkey"   = 0x00000000
        "Name"     = $taskName
    }              
) | Install-ConEmuTask

@(
    [PSCustomObject]@{
        TaskName = $taskName; Icon = $gitIcon }
) | Install-ConEmuHere