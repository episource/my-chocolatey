$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"

$startmenu = @{
    LinkName   = "FileSeek"
    TargetPath = "$toolsDir\FileSeek\FileSeek.exe"
}
Install-StartMenuLink @startmenu