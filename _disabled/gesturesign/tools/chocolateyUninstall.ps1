Set-StrictMode -Version latest
$ErrorActionPreference = "Stop"


Unregister-ScheduledTask -TaskName "GestureSignAutoRunTask" `
    -ErrorAction Continue | Out-Null