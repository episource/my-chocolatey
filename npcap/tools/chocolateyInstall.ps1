Set-StrictMode -Version latest
$ErrorAction = "Stop"
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"

. $toolsDir/chocolateyInstallLib.ps1
write-warning "The interactive npcap installer will open soon."
write-warning "The chocolatey install script will go through the installer automatically."


# let installation timeout after a reasonable time
$instTimeoutSec = 120

# note: since 0.97 /S (silent) is supported by oem package, only!
# npf_startup=yes : start driver at boot time
# loopback_support=yes : capture loopback traffic
# dlt_null=yes : don't fake ethernet frames when capturing loopback traffic - requires capturing software support (current wireshark supports this)
# admin_only=no : all users can capture packets
# dot11_support=yes : enable capturing of raw 802.11 (wlan) traffic (see https://wiki.wireshark.org/CaptureSetup)
# vlan_support=yes : support capturing tagged ethernet frames
# winpcap_mode=no : use npcap native interface (no backwards compatibility)
$instArgs = @( "/npf_startup=yes", "/loopback_support=yes", "/dlt_null=yes", "/admin_only=no", "/dot11_support=yes","/vlan_support=yes", "/winpcap_mode=no")

$tStart = Get-Date
$instProc = Start-Process -PassThru $exeInstaller -ArgumentList $instArgs

# Fake silent installation by stepping through minimized installer dialog
# => programmatically click confirmation button
while (-not $instProc.HasExited -and $(Get-IsNoTimeout $tStart $instTimeoutSec)) {
    $instProc.Refresh()
    Click-Button $instProc @( "*yes*", "*agree*", "*install*", "*next*", "*finish*" ) | Out-Null
    Start-Sleep 0.05
}

if (-not $instProc.HasExited) {
    $instProc.Kill()
    throw "Timeout - installation aborted!"
} elseif ($instProc.ExitCode -ne 0) {
    throw "Installation failed - non-zero exit code!"
} else {
    write-host "Npcap installed successfully!"
}


