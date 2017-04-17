Set-StrictMode -Version latest
$ErrorAction = "Stop"
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"


Start-Process -Wait -WindowStyle Hidden "$toolsDir\python.exe" `
    @( "-E", "-s", "-B", "-m", "ensurepip._uninstall" )