Set-StrictMode -Version latest
$ErrorAction = "Stop"
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"


$imgDir = Join-Path $env:ProgramData "bingimg"
New-Item -Type Directory -Path $imgDir -ErrorAction SilentlyContinue


$taskName = "get-bingimg"
$launcherPath = Join-Path $toolsDir "get-bingimg.vbs"
$scriptPath = Join-Path $toolsDir "get-bingimg.ps1"

@"
Dim shell,command
command = "powershell.exe -NoProfile -NoLogo -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File ""$scriptPath"" -TargetDir ""$imgDir"" -Max 8 -AddTitle -TitleSize 12 -TitleHPos Center -TitleVPos Bottom -TitleMargin 35"
set shell = CreateObject("WScript.Shell")
shell.Run command,0,True
"@ | Out-File $launcherPath

Register-ScheduledTask -TaskName $taskName -Force -Xml @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>Download bing image of the day to be used as desktop wallpaper.</Description>
    <URI>\$taskName</URI>
  </RegistrationInfo>
  <Principals>
    <Principal id="Author">
      <GroupId>S-1-5-32-545</GroupId><!-- Group: Users -->
    </Principal>
  </Principals>
  <Settings>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <RunOnlyIfNetworkAvailable>true</RunOnlyIfNetworkAvailable>
    <ExecutionTimeLimit>PT30M</ExecutionTimeLimit>
    <AllowHardTerminate>true</AllowHardTerminate>
    <MultipleInstancesPolicy>StopExisting</MultipleInstancesPolicy>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
  </Settings>
  <Triggers>
    <BootTrigger>
      <Repetition>
        <Interval>PT12H</Interval>
        <StopAtDurationEnd>false</StopAtDurationEnd>
      </Repetition>
      <ExecutionTimeLimit>PT30M</ExecutionTimeLimit>
      <Enabled>true</Enabled>
      <Delay>PT5M</Delay>
    </BootTrigger>
  </Triggers>
  <Actions Context="Author">
    <Exec>
      <Command>wscript.exe</Command>
      <Arguments>"$launcherPath"</Arguments>
    </Exec>
  </Actions>
</Task>
"@ | Out-Null
Start-ScheduledTask -TaskName $taskName