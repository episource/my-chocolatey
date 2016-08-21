Set-StrictMode -Version latest
$ErrorActionPreference = "Stop"

$destdir   = Split-Path -parent $MyInvocation.MyCommand.Definition
$drvname   = "kprocesshacker.sys"
$x64dir    = Join-Path $destDir "x64"
$drvsys    = Join-Path $x64dir $drvname


# Try to stop KProcessHacker service (otherwise kprocesshacker.sys cannot be
# deleted!)
$drvsysInfo     = Get-Item $drvsys
$kphServiceName = "KProcessHacker$($drvsysInfo.VersionInfo.ProductMajorPart)"

Try {
    & net stop $kphServiceName | Out-Null
} Catch {
    Write-Warning `
        "Failed to stop KPH service $kphServiceName. This is fine if `
        ProcessHacker has not been used in elevated mode since the last reboot."
}
