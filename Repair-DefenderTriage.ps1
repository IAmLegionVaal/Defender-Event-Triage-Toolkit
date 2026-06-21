#requires -Version 5.1
<# Created by Dewald Pretorius. Guarded Microsoft Defender health recovery. #>
[CmdletBinding(SupportsShouldProcess=$true)]
param([ValidateSet('Diagnose','UpdateSignatures','StartHealthService')][string]$Action='Diagnose',[string]$OutputPath=(Join-Path ([Environment]::GetFolderPath('Desktop')) 'Defender_Triage_Repair'))
$ErrorActionPreference='Stop';New-Item -ItemType Directory -Path $OutputPath -Force|Out-Null;$s=Get-Date -Format yyyyMMdd_HHmmss
$before=[ordered]@{Status=(Get-MpComputerStatus|Select-Object AMServiceEnabled,AntivirusEnabled,RealTimeProtectionEnabled,AntivirusSignatureLastUpdated,AntivirusSignatureVersion);Service=(Get-Service SecurityHealthService -ErrorAction SilentlyContinue|Select-Object Name,Status,StartType);RecentEvents=@(Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Windows Defender/Operational';StartTime=(Get-Date).AddDays(-1)} -ErrorAction SilentlyContinue|Select-Object -First 100 TimeCreated,Id,LevelDisplayName,Message)};$before|ConvertTo-Json -Depth 6|Set-Content (Join-Path $OutputPath "before_$s.json")
if($Action-eq'Diagnose'){exit 0}
try{if($Action-eq'UpdateSignatures'-and$PSCmdlet.ShouldProcess('Microsoft Defender signatures','Update')){Update-MpSignature}elseif($Action-eq'StartHealthService'-and$PSCmdlet.ShouldProcess('SecurityHealthService','Start if stopped')){$svc=Get-Service SecurityHealthService;if($svc.Status-eq'Stopped'){Start-Service SecurityHealthService}}}catch{Write-Error $_;exit 5}
$after=Get-MpComputerStatus;if(-not$after.AntivirusEnabled){exit 6};$after|Select-Object AMServiceEnabled,AntivirusEnabled,RealTimeProtectionEnabled,AntivirusSignatureLastUpdated,AntivirusSignatureVersion|ConvertTo-Json|Set-Content (Join-Path $OutputPath "after_$s.json");exit 0
