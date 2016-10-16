$toolsDir  = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$puttyExe  = Join-Path $toolsDir "../../putty/tools/PUTTY.EXE"

@(
    @{
        "_SortKey" = "210"
        "Active"   = 0x00000000
        "Cmd1"     = "$puttyExe"
        "Count"    = 0x00000001
        "Flags"    = 0x00000000
        "GuiArgs"  = ""
        "Hotkey"   = 0x00000000
        "Name"     = "{Net::Putty}"
    }              
) | Install-ConEmuTask