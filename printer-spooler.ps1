# Stop the Print Spooler service
Stop-Service -Name Spooler -Force

# Delete all files in the print spooler folder
# Warning: This command will delete all pending print jobs.
Remove-Item -Path "$env:SystemRoot\System32\spool\PRINTERS\*" -Force -Recurse -ErrorAction SilentlyContinue

# Restart the Print Spooler service
Start-Service -Name Spooler

# Set the Print Spooler service startup type to Automatic
Set-Service -Name Spooler -StartupType Automatic

Write-Host "The print spooler has been cleared and reset successfully."
Write-Host "The Print Spooler service has been started and its startup type set to Automatic."

# Additional information about the "Print Nightmare" vulnerability:
# "Print Nightmare" is a bug in the Windows Print Spooler service
# that can allow an attacker to remotely execute code on a Microsoft Windows system
# with local SYSTEM user privileges.
# You can temporarily disable the Windows Print Spooler service
# to mitigate the vulnerability until a proper fix is released.
# To completely disable the service (if needed to mitigate "Print Nightmare" temporarily):
# Stop-Service -Name Spooler -Force
# Set-Service -Name Spooler -StartupType Disabled
# Write-Host "The Print Spooler service has been stopped and disabled."
