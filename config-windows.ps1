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
# Thay đổi múi giờ, định dạng ngày tháng
function Log {
    param (
        [string]$Message
    )
    Write-Host $Message
}
Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin -Value 0
# Set the time zone, date format, and refresh Taskbar
try {
    # Đặt múi giờ
    Set-TimeZone -Id "SE Asia Standard Time"
    
    # Lấy thông tin múi giờ hiện tại
    $currentTz = Get-TimeZone
    
    # Đặt định dạng Short Date trong registry (cho người dùng hiện tại)
    Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name sShortDate -Value "dd/MM/yyyy"
    
    # Lấy thời gian hiện tại để xác nhận
    $currentTime = Get-Date -Format "dd/MM/yyyy"
    #Reset time zone and date format
    # Stop the Windows Time service
Stop-Service w32time

# Unregister the Windows Time service (if necessary, typically to reset configuration)
w32tm /unregister

# Register the Windows Time service again
w32tm /register

# Configure the time server (replace "your.time.server.com" with your NTP server)
# You can list multiple servers, separated by spaces, e.g., "time.windows.com,pool.ntp.org"
# The /manualpeerlist parameter specifies the list of servers.
# The /syncfromflags:manual parameter specifies that the computer will sync from this manual list.
# The /update parameter updates the configuration.
w32tm /config /manualpeerlist:"time.google.com" /syncfromflags:manual /update

# Restart the Windows Time service to apply the new configuration
Start-Service w32time

# Force an immediate time synchronization with the newly configured server
w32tm /resync /force

# (Optional) Check the configuration and synchronization status
w32tm /query /status
w32tm /query /configuration
    # Reset hiển thị ngày giờ trên Taskbar bằng cách khởi động lại Windows Explorer
    Log "Restarting Windows Explorer to refresh Taskbar date/time display..."
    Stop-Process -Name explorer -Force
    Start-Sleep -Milliseconds 500  # Đợi một chút để Explorer khởi động lại
    
    # Ghi ra thông tin chi tiết
    Log "Time zone successfully set:"
    Log "Id                         : $($currentTz.Id)"
    Log "DisplayName                : $($currentTz.DisplayName)"
    Log "StandardName               : $($currentTz.StandardName)"
    Log "DaylightName               : $($currentTz.DaylightName)"
    Log "BaseUtcOffset              : $($currentTz.BaseUtcOffset)"
    Log "SupportsDaylightSavingTime : $($currentTz.SupportsDaylightSavingTime)"
    Log "Current Time (dd/MM/yyyy)  : $currentTime"
    Log "System Short Date format updated to: dd/MM/yyyy"
    Log "Taskbar date/time display refreshed."
    Log ""
} catch {
    Log "Failed to change time zone, date format, or refresh Taskbar: $($_.Exception.Message)"
}
# Bật chế độ High Performance
powercfg -setactive SCHEME_MIN
powercfg -getactivescheme
Write-Output "`n"

# Điều chỉnh trên Desktop
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
    Set-ItemProperty -Path $iconRegPath -Name "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" -Value 0
    Set-ItemProperty -Path $iconRegPath -Name "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" -Value 0

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
Log ""

# Disable Fast Startup by modifying the registry
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name 'HiberbootEnabled' -Value 0
Write-Host "Fast Startup has been disabled. Please restart your computer for the changes to take effect."
Log ""

# Remove Task View
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0
Get-AppxPackage *WebExperience* | Remove-AppxPackage
$computerInfo = Get-ComputerInfo

# Kiểm tra xem tên hệ điều hành có bắt đầu bằng "Microsoft Windows 11" không
if ($computerInfo.OsName.StartsWith("Microsoft Windows 11")) {
    # Nếu là Windows 11, thực thi đoạn mã của bạn ở đây
    Write-Host "Đây là Windows 11."
    Write-Host "Thực thi mã dành riêng cho Windows 11..."
    winget uninstall –id 9MSSGKG348SPCompletely U
}

# Path to the key containing notification settings
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications"

# If the key does not exist, create a new key
if (!(Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}

# Set the "ToastEnabled" value to 0 (0: disable, 1: enable)
Set-ItemProperty -Path $regPath -Name "ToastEnabled" -Value 0 -Type DWord

Write-Output "Toast notifications have been disabled. Please log out and log back in or restart your computer for the changes to take effect."

# Pause before exiting
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
