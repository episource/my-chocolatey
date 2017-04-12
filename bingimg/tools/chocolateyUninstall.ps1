Set-StrictMode -Version latest
$ErrorActionPreference = "Stop"


Unregister-ScheduledTask -TaskName "get-bingimg" -Confirm:$false -ErrorAction Continue | Out-Null