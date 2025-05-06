<#
.SYNOPSIS
    Pauses Windows Updates for 35 days using registry keys.
.DESCRIPTION
    This script requires administrative privileges to modify the necessary registry keys
    to pause both Quality and Feature updates for the maximum duration typically allowed (35 days).
.NOTES
    Author: Your Name/AI Assistant
    Date:   2023-10-27
    Requires: Administrator privileges.
#>

#Requires -RunAsAdministrator

Write-Host "Checking for administrator privileges..."
# Simple check, the #Requires statement is the primary enforcer
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator." -ErrorAction Stop
} else {
    Write-Host "Administrator privileges confirmed."
}

$registryPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
$pauseDurationDays = 35
$currentTime = Get-Date
$expiryTime = $currentTime.AddDays($pauseDurationDays).ToString("yyyy-MM-ddT00:00:00Z") # Set to start of the day for consistency
$startTime = $currentTime.ToString("yyyy-MM-ddTHH:mm:ssZ")

Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'| Select-Object PauseUpdatesExpiryTime

Write-Host "Attempting to pause Windows Updates for $pauseDurationDays days (until $($expiryTime))..."

try {
    Set-ItemProperty -Path $registryPath -Name "PauseUpdatesExpiryTime" -Value $expiryTime -ErrorAction Stop
    Set-ItemProperty -Path $registryPath -Name "PauseFeatureUpdatesEndTime" -Value $expiryTime -ErrorAction Stop
    Set-ItemProperty -Path $registryPath -Name "PauseQualityUpdatesEndTime" -Value $expiryTime -ErrorAction Stop
    Set-ItemProperty -Path $registryPath -Name "PauseUpdatesStartTime" -Value $startTime -ErrorAction Stop # Record when pausing started

    Write-Host "Windows Updates have been successfully paused until $expiryTime." -ForegroundColor Green
}
catch {
    Write-Error "Failed to pause Windows Updates. Error: $($_.Exception.Message)"
}

# Pause before exiting
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')