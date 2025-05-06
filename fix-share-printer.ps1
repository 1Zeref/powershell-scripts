#Fix SMB Signing
Set-SmbClientConfiguration -RequireSecuritySignature $false
# Nhập địa chỉ mạng từ người dùng
$networkAddress = Read-Host "Input Internet or Network address"
# Thêm Credential với Username là 'Guest' và mật khẩu trống
cmdkey /add:$networkAddress /user:Guest /pass:""

# Pause before exiting
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')