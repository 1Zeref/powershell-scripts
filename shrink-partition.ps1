# Ensure the script is running with administrator privileges
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

# Define the target partition size (200GB)
$targetSize = 200 * 1GB

Write-Host "Attempting to shrink C: drive to $($targetSize/1GB) GB..." -ForegroundColor Cyan

# Get partition information for C drive
$partitionC = Get-Partition -DriveLetter C -ErrorAction SilentlyContinue
if (-not $partitionC) {
    Write-Host "C: drive not found. Exiting..." -ForegroundColor Red
    exit
}

$currentSizeC = $partitionC.Size
Write-Host "Current size of C: drive is $([math]::Round($currentSizeC / 1GB, 2)) GB" -ForegroundColor Cyan

# Get the minimum supported size for shrinking the partition
$supportedSize = Get-PartitionSupportedSize -DiskNumber $partitionC.DiskNumber -PartitionNumber $partitionC.PartitionNumber
$minSize = $supportedSize.SizeMin
Write-Host "Minimum supported size for C: is $([math]::Round($minSize/1GB,2)) GB" -ForegroundColor Cyan

# Check if shrinking is possible and needed
if ($minSize -le $targetSize -and $currentSizeC -gt $targetSize) {
    try {
        Write-Host "Resizing C: drive to $($targetSize/1GB) GB..." -ForegroundColor Cyan
        # Shrink C: drive to targetSize (200GB)
        Resize-Partition -DiskNumber $partitionC.DiskNumber -PartitionNumber $partitionC.PartitionNumber -Size $targetSize -ErrorAction Stop
        Write-Host "C: drive resized successfully." -ForegroundColor Green

        Write-Host "Creating new partition from unallocated space..." -ForegroundColor Cyan
        # Create a new partition from the unallocated space on the same disk
        $partitionNew = New-Partition -DiskNumber $partitionC.DiskNumber -UseMaximumSize -ErrorAction Stop

        # Get the first available drive letter (excluding A and B)
        $usedLetters = (Get-Volume).DriveLetter
        $allLetters = "CDEFGHIJKLMNOPQRSTUVWXYZ".ToCharArray()  # Exclude A and B
        $freeLetter = $allLetters | Where-Object { $_ -notin $usedLetters } | Select-Object -First 1

        if (-not $freeLetter) {
            Write-Host "No available drive letter found." -ForegroundColor Red
            exit
        }

        Write-Host "Assigning drive letter $freeLetter to the new partition..." -ForegroundColor Cyan
        Set-Partition -DiskNumber $partitionNew.DiskNumber -PartitionNumber $partitionNew.PartitionNumber -NewDriveLetter $freeLetter

        Write-Host "Waiting for the system to detect the new volume (${freeLetter}:)..." -ForegroundColor Cyan
        Start-Sleep -Seconds 5

        # Loop until the new volume is detected (or try up to 6 times)
        $attempt = 0
        do {
            $volume = Get-Volume -DriveLetter $freeLetter -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            $attempt++
        } while (-not $volume -and $attempt -lt 6)

        if (-not $volume) {
            Write-Host "Failed to detect the new volume for drive $freeLetter." -ForegroundColor Red
            exit
        }

        Write-Host "Formatting new partition with NTFS and labeling it 'Data'..." -ForegroundColor Cyan
        # Format the new partition with NTFS and apply the "Data" label
        Format-Volume -DriveLetter $freeLetter -FileSystem NTFS -NewFileSystemLabel "Data" -Confirm:$false -ErrorAction Stop
        Write-Host "New partition created and formatted successfully! (Drive letter: $freeLetter)" -ForegroundColor Green
    } 
    catch {
        Write-Host "Error during execution: $_" -ForegroundColor Red
    }
} 
else {
    Write-Host "Cannot shrink C: drive to 200GB or C: is not large enough." -ForegroundColor Red
}

Write-Host "Press Enter to exit..."
Read-Host