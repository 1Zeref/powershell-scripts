#Kiem tra quyen Administrator
function Test-Admin {
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Host "This script must be run as Administrator. Relaunching with elevated privileges..." -ForegroundColor Yellow
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$MyInvocation.MyCommand.Path`"" -Verb RunAs
    exit
}

#UAC setup to Never notify
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Value 0 -Type DWord -Force

#Tắt Lock Screen
$RegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
$Name = "NoLockScreen"
$Value = 1
If (-Not (Test-Path $RegistryPath)) {
  New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows" -Name "Personalization" -Force | Out-Null
}
New-ItemProperty -Path $RegistryPath -Name $Name -Value $Value -PropertyType DWORD -Force | Out-Null
$CurrentValue = (Get-ItemProperty -Path $RegistryPath -Name $Name).$Name
If ($CurrentValue -eq $Value) {
  Write-Host "Đã tắt màn hình khóa Windows thành công. Bạn có thể cần khởi động lại máy tính."
} Else {
  Write-Host "Không thể tắt màn hình khóa Windows. Vui lòng kiểm tra lại quyền Administrator."
}

#Bật File Extensions
$RegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$Name = "HideFileExt"
$Value = 0
try {
    $Property = Get-ItemProperty -Path $RegistryPath -Name $Name -ErrorAction SilentlyContinue
    If ($Property -ne $null -and $Property.$Name -eq $Value) {
        Write-Host "Phần mở rộng của tệp đã được hiển thị."
    } else {
        Set-ItemProperty -Path $RegistryPath -Name $Name -Value $Value -Type DWORD -Force
        Write-Host "Đã thay đổi cài đặt để hiển thị phần mở rộng của tệp."
    }
}
catch {
    Write-Error "Đã xảy ra lỗi: $($_.Exception.Message)"
    Write-Error "Vui lòng đảm bảo bạn có quyền để thay đổi Registry."
}

#Desktop Icon
function Log($Message) {
    Write-Output $Message
}

try {
    $iconRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
    $desktopRegPath = "HKCU:\Software\Microsoft\Windows\Shell\Bags\1\Desktop"
    
    if (-not (Test-Path $iconRegPath)) {
        New-Item -Path $iconRegPath -Force | Out-Null
    }
    
    Set-ItemProperty -Path $iconRegPath -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value 0
    Set-ItemProperty -Path $iconRegPath -Name "{645FF040-5081-101B-9F08-00AA002F954E}" -Value 0
    Set-ItemProperty -Path $iconRegPath -Name "{26EE0668-A00A-44D7-9371-BEB064C98683}" -Value 0
    Set-ItemProperty -Path $iconRegPath -Name "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" -Value 0
	Set-ItemProperty -Path $iconRegPath -Name "{59031A47-3F72-44A7-89C5-5595FE6B30EE}" -Value 0
    if (-not (Test-Path $desktopRegPath)) {
        New-Item -Path $desktopRegPath -Force | Out-Null
    }
    
    $fflags = Get-ItemProperty -Path $desktopRegPath -Name FFlags -ErrorAction SilentlyContinue
    $newFFlags = if ($fflags) { $fflags.FFlags -bor 0x1 } else { 0x1 }
    Set-ItemProperty -Path $desktopRegPath -Name FFlags -Value $newFFlags
}
catch {
    Log "Failed to modify desktop settings: $($_.Exception.Message)"
}

Log "Desktop Icons Configuration Completed."

#Các cài đặt về nguồn
$PowerButtonActionGuid = "7648efa3-dd9c-4e3e-b566-50f929386280"
$PowerButtonsSubgroupGuid = "4f971e89-eebd-4455-a8de-9e59040e7347"
$ActionShutdown = 3
powercfg /SETACVALUEINDEX SCHEME_CURRENT $PowerButtonsSubgroupGuid $PowerButtonActionGuid $ActionShutdown
powercfg /SETDCVALUEINDEX SCHEME_CURRENT $PowerButtonsSubgroupGuid $PowerButtonActionGuid $ActionShutdown
$SleepButtonActionGuid = "96996bc0-ad50-47ec-923b-6f41874dd9eb"
$ActionSleep = 1
powercfg /SETACVALUEINDEX SCHEME_CURRENT $PowerButtonsSubgroupGuid $SleepButtonActionGuid $ActionSleep
powercfg /SETDCVALUEINDEX SCHEME_CURRENT $PowerButtonsSubgroupGuid $SleepButtonActionGuid $ActionSleep
$SessionManagerPowerPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
$HiberbootEnabledName = "HiberbootEnabled"
Set-ItemProperty -Path $SessionManagerPowerPath -Name $HiberbootEnabledName -Value 0 -Type DWORD -Force -ErrorAction SilentlyContinue
$PolicyExplorerPath = "HKLM:\Software\Policies\Microsoft\Windows\Explorer"
If (-Not (Test-Path $PolicyExplorerPath)) {
    New-Item -Path (Split-Path $PolicyExplorerPath) -Name (Split-Path $PolicyExplorerPath -Leaf) -Force -ErrorAction SilentlyContinue | Out-Null
}
powercfg /hibernate on
$HibernateDisabledCheck = $(powercfg /a | Select-String "Hibernation has not been enabled.")
$ShowHibernatePolicyName = "ShowHibernateOption"
Set-ItemProperty -Path $PolicyExplorerPath -Name $ShowHibernatePolicyName -Value 0 -Type DWORD -Force -ErrorAction SilentlyContinue # Giá trị 0 để "Hide" (Ẩn)
$SleepStates = $(powercfg /a | Select-String "Standby (S[1-3])") # Hoặc S0 Low Power Idle
$ShowSleepPolicyName = "ShowSleepOption"
Set-ItemProperty -Path $PolicyExplorerPath -Name $ShowSleepPolicyName -Value 0 -Type DWORD -Force -ErrorAction SilentlyContinue # Giá trị 0 để "Hide" (Ẩn)
Write-Host "Đã thiết lập để ẩn Sleep khỏi Power menu (ShowSleepOption = 0)."
$FlyoutMenuSettingsPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings"
$ShowLockOptionName = "ShowLockOption"
If (-Not (Test-Path $FlyoutMenuSettingsPath)) {
    New-Item -Path $FlyoutMenuSettingsPath -Force -ErrorAction SilentlyContinue | Out-Null
}
Set-ItemProperty -Path $FlyoutMenuSettingsPath -Name $ShowLockOptionName -Value 1 -Type DWORD -Force -ErrorAction SilentlyContinue # Giá trị 1 để "Show" (Hiển thị)
Write-Host "Các cài đặt nguồn đã được áp dụng."

#Tắt Bing Search
try {
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
    $registryName = "BingSearchEnabled"
    $targetValue  = 0 # Giá trị 0 để tắt tìm kiếm Bing
    Set-ItemProperty -Path $registryPath -Name $registryName -Value $targetValue -Type DWord -Force -ErrorAction Stop 
    Write-Host "Tắt tìm kiếm Bing thành công."
}
catch {
        Write-Host "Tắt tìm kiếm Bing thất bại."
}

#Tắt/Bặt Widgets
Get-AppxPackage *WebExperience* | Remove-AppxPackage
winget uninstall --id 9MSSGKG348SP

#Tắt Update
If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata")) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -Force | Out-Null
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -Name "PreventDeviceMetadataFromNetwork" -Type DWord -Value 1
If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching")) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Force | Out-Null
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontPromptForWindowsUpdate" -Type DWord -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontSearchWindowsUpdate" -Type DWord -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DriverUpdateWizardWuSearchEnabled" -Type DWord -Value 0
If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate")) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" | Out-Null
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate" -Type DWord -Value 1
Write-Host "Disabling Windows Update automatic restart..."
If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU")) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force | Out-Null
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -Type DWord -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUPowerManagement" -Type DWord -Value 0
Write-Host "Disabled driver offering through Windows Update"
If (!(Test-Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings")) {
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Force | Out-Null
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "BranchReadinessLevel" -Type DWord -Value 20
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "DeferFeatureUpdatesPeriodInDays" -Type DWord -Value 365
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "DeferQualityUpdatesPeriodInDays" -Type DWord -Value 4

Write-Host "================================="
Write-Host "-- Updates Set to Recommended ---"
Write-Host "================================="

Get-AppxPackage *WebExperience* | Remove-AppxPackage
winget uninstall --id 9MSSGKG348SP

Stop-Process -Name explorer -Force
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
