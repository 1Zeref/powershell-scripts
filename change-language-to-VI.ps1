# Check the list of installed languages
Get-WinUserLanguageList

# Add a new language
$LangList = New-WinUserLanguageList "vi-VN"
Set-WinUserLanguageList $LangList

# Install the language pack if not already installed
Install-Language -Language vi-VN

# Set the default display language
Set-WinUILanguageOverride -Language vi-VN
Set-WinUserLanguageList -LanguageList vi-VN -Force

# Prompt the user to restart to apply the changes
Write-Host "The language change process is complete. Please restart your computer!" -ForegroundColor Green

# Pause before exiting
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
