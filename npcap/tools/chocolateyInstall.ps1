Set-StrictMode -Version latest
$ErrorAction = "Stop"
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"

$exeInstaller = Get-Item "$toolsDir/npcap-*.exe"

# /S : silent install
# npf_startup=yes : start driver at boot time
# loopback_support=yes : capture loopback traffic
# dlt_null=yes : don't fake ethernet frames when capturing loopback traffic - requires capturing software support (current wireshark supports this)
# admin_only=no : all users can capture packets
# dot11_support=yes : enable capturing of raw 802.11 (wlan) traffic (see https://wiki.wireshark.org/CaptureSetup)
# vlan_support=yes : support capturing tagged ethernet frames
# winpcap_mode=yes : install winpcap compatible interface
$instArgs = "/S /npf_startup=yes /loopback_support=yes /dlt_null=yes /admin_only=no /dot11_support=yes /vlan_support=yes /winpcap_mode=yes"
Install-ChocolateyInstallPackage -PackageName $env:chocolateyPackageName `
    -File $exeInstaller -FileType 'exe' -silentArgs $instArgs 