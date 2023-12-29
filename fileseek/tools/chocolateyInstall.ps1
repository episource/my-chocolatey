$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"

$startmenu = @{
    LinkName   = "FileSeek"
    TargetPath = "$toolsDir\FileSeek64\FileSeek.exe"
}
Install-StartMenuLink @startmenu