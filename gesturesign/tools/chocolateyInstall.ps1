Set-StrictMode -Version latest
$ErrorActionPreference = "Stop"

$destdir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$startMenu = @{ LinkName="GestureSign"; TargetPath="$destdir\GestureSign.exe" }


# Extract GestureSign
Set-Location $destdir
$setupExe = Get-Item "GestureSignSetup-*.exe"
Get-ChocolateyUnzip -FileFullPath $setupExe.FullName -Destination $destdir
Remove-Item $setupExe
Remove-Item -Recurse '$PLUGINSDIR'

# Don't create any shims
Set-AutoShim -Pattern "**" -Mode Ignore | Out-Null

# Install start menu shortcut
Install-StartMenuLink @startMenu

# Setup autostart, so that it is recognised by the app's config dialog
$daemonExe = "$destdir\GestureSignDaemon.exe"
$taskXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>Launch GestureSign when user login</Description>
    <URI>\GestureSignAutoRunTask</URI>
  </RegistrationInfo>
  <Principals>
    <Principal id="Author">
      <GroupId>S-1-5-32-545</GroupId><!-- Group: Users -->
    </Principal>
  </Principals>
  <Settings>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
    <MultipleInstancesPolicy>StopExisting</MultipleInstancesPolicy>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
  </Settings>
  <Triggers>
    <LogonTrigger/>
  </Triggers>
  <Actions Context="Author">
    <Exec>
      <Command>cmd.exe</Command>
      <Arguments>/c "start $daemonExe"</Arguments>
    </Exec>
  </Actions>
</Task>
"@

Register-ScheduledTask -TaskName "GestureSignAutoRunTask" -Xml $taskXml `
    -Force | Out-Null