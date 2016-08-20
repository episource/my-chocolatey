. $PSScriptRoot/chocolateyCommon.ps1

# Try to stop KProcessHacker service (otherwise kprocesshacker.sys cannot be
# deleted!)
$drvsysInfo     = Get-Item $drvsys
$kphServiceName = "KProcessHacker$($drvsysInfo.VersionInfo.ProductMajorPart)"

Try {
    & net stop $kphServiceName | Out-Null
} Catch {
    Write-Verbose `
        "Failed to stop KPH service $service. This is fine if ProcessHacker `
        has not been used since the last reboot."
}


# Uninstall start menu shortcut
If (Test-Path -Path $startLink) {
    Remove-item -Path $startLink
}

# Remove shim from path
Uninstall-BinFile -Name "${appname}_x86" -Path $x86exe
Uninstall-BinFile -Name "${appname}_x64" -Path $x64exe
Uninstall-BinFile -Name "$appname"       -Path $exe