$ErrorActionPreference = "Stop"

$BuildRoot = "C:\kiosk-build\build"
$LogFile   = "$BuildRoot\build.log"
$Manifest  = "$BuildRoot\manifest.json"

function Write-Log {
    param([string]$Message)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$ts - $Message" | Out-File -FilePath $LogFile -Append -Encoding utf8
}

Write-Log "Starting image build process"

# Collect system information
Write-Log "Collecting system information"

$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"

$manifestObject = @{
    buildId        = "build-{0}" -f (Get-Date -Format "yyyyMMdd-HHmmss")
    hostname       = $env:COMPUTERNAME
    osName         = $os.Caption
    osVersion      = $os.Version
    architecture   = $os.OSArchitecture
    totalMemoryGB  = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
    diskSizeGB     = [math]::Round($disk.Size / 1GB, 2)
    freeDiskGB     = [math]::Round($disk.FreeSpace / 1GB, 2)
    buildTimestamp = (Get-Date).ToString("o")
    buildStatus    = "SUCCESS"
}

Write-Log "System information collected"

# Write manifest
Write-Log "Writing image manifest"
$manifestObject | ConvertTo-Json -Depth 3 | Out-File -FilePath $Manifest -Encoding utf8

Write-Log "Image build completed successfully"
