#requires -Version 5.1
[CmdletBinding()]
param([int]$Days=7,[string]$OutputPath)
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
if([string]::IsNullOrWhiteSpace($OutputPath)){$OutputPath=Join-Path ([Environment]::GetFolderPath('Desktop')) 'Defender_Triage_Reports'}
New-Item -ItemType Directory -Path $OutputPath -Force|Out-Null
$status=Get-MpComputerStatus -ErrorAction SilentlyContinue|Select-Object AMServiceEnabled,AntivirusEnabled,AntispywareEnabled,BehaviorMonitorEnabled,IoavProtectionEnabled,RealTimeProtectionEnabled,NISEnabled,AntivirusSignatureVersion,AntivirusSignatureLastUpdated,AMEngineVersion
$prefs=Get-MpPreference -ErrorAction SilentlyContinue|Select-Object DisableRealtimeMonitoring,DisableBehaviorMonitoring,DisableIOAVProtection,MAPSReporting,SubmitSamplesConsent
$start=(Get-Date).AddDays(-1*$Days)
$events=Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Windows Defender/Operational';StartTime=$start} -ErrorAction SilentlyContinue|Select-Object -First 300 TimeCreated,Id,LevelDisplayName,Message
$status|Export-Csv (Join-Path $OutputPath "defender_status_$stamp.csv") -NoTypeInformation -Encoding UTF8
$prefs|Export-Csv (Join-Path $OutputPath "defender_preferences_$stamp.csv") -NoTypeInformation -Encoding UTF8
$events|Export-Csv (Join-Path $OutputPath "defender_events_$stamp.csv") -NoTypeInformation -Encoding UTF8
@{Computer=$env:COMPUTERNAME;Generated=Get-Date;Status=$status;Preferences=$prefs;Events=$events}|ConvertTo-Json -Depth 6|Set-Content (Join-Path $OutputPath "defender_triage_$stamp.json") -Encoding UTF8
$html="<h1>Defender Event Triage - $env:COMPUTERNAME</h1><p>Generated $(Get-Date)</p><h2>Status</h2>$(@($status)|ConvertTo-Html -Fragment)<h2>Preferences</h2>$(@($prefs)|ConvertTo-Html -Fragment)<h2>Recent Events</h2>$($events|ConvertTo-Html -Fragment)"
$html|ConvertTo-Html -Title 'Defender Event Triage'|Set-Content (Join-Path $OutputPath "defender_triage_$stamp.html") -Encoding UTF8
Write-Host "Reports saved to: $OutputPath" -ForegroundColor Green
