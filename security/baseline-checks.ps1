$ErrorActionPreference = "Stop"

$OutDir = "security"
$Log    = Join-Path $OutDir "security-checks.log"
$Json   = Join-Path $OutDir "security-report.json"

function Write-Log {
    param([string]$Message)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$ts - $Message" | Out-File -FilePath $Log -Append -Encoding utf8
}

function Add-CheckResult {
    param(
        [string]$CheckId,
        [string]$Title,
        [bool]$Passed,
        [string]$Details
    )
    $script:Results += [pscustomobject]@{
        checkId  = $CheckId
        title    = $Title
        passed   = $Passed
        details  = $Details
    }
}

Write-Log "Starting security baseline checks (non-destructive)"

$Results = @()

# CHECK 1: Windows Firewall enabled for all profiles
try {
    $profiles = Get-NetFirewallProfile
    $disabled = $profiles | Where-Object { $_.Enabled -eq $false } | Select-Object -ExpandProperty Name
    if ($disabled) {
        Add-CheckResult -CheckId "FW-001" -Title "Windows Firewall enabled (all profiles)" -Passed $false -Details ("Disabled profiles: " + ($disabled -join ", "))
        Write-Log "FAIL FW-001: Firewall disabled on $($disabled -join ', ')"
    } else {
        Add-CheckResult -CheckId "FW-001" -Title "Windows Firewall enabled (all profiles)" -Passed $true -Details "All profiles enabled"
        Write-Log "PASS FW-001: Firewall enabled"
    }
} catch {
    Add-CheckResult -CheckId "FW-001" -Title "Windows Firewall enabled (all profiles)" -Passed $false -Details $_.Exception.Message
    Write-Log "ERROR FW-001: $($_.Exception.Message)"
}

# CHECK 2: RDP disabled (or restricted)
try {
    $rdp = Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections"
    $deny = [int]$rdp.fDenyTSConnections
    if ($deny -eq 1) {
        Add-CheckResult -CheckId "RDP-001" -Title "Remote Desktop disabled" -Passed $true -Details "RDP connections denied (fDenyTSConnections=1)"
        Write-Log "PASS RDP-001: RDP disabled"
    } else {
        Add-CheckResult -CheckId "RDP-001" -Title "Remote Desktop disabled" -Passed $false -Details "RDP appears enabled (fDenyTSConnections=0)"
        Write-Log "FAIL RDP-001: RDP appears enabled"
    }
} catch {
    Add-CheckResult -CheckId "RDP-001" -Title "Remote Desktop disabled" -Passed $false -Details $_.Exception.Message
    Write-Log "ERROR RDP-001: $($_.Exception.Message)"
}

# CHECK 3: UAC enabled (basic check)
try {
    $uac = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA"
    $enabled = [int]$uac.EnableLUA
    if ($enabled -eq 1) {
        Add-CheckResult -CheckId "UAC-001" -Title "User Account Control enabled" -Passed $true -Details "EnableLUA=1"
        Write-Log "PASS UAC-001: UAC enabled"
    } else {
        Add-CheckResult -CheckId "UAC-001" -Title "User Account Control enabled" -Passed $false -Details "EnableLUA=0"
        Write-Log "FAIL UAC-001: UAC disabled"
    }
} catch {
    Add-CheckResult -CheckId "UAC-001" -Title "User Account Control enabled" -Passed $false -Details $_.Exception.Message
    Write-Log "ERROR UAC-001: $($_.Exception.Message)"
}

# CHECK 4: SMBv1 disabled (common baseline)
try {
    $smb1 = Get-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol" -ErrorAction Stop
    if ($smb1.State -eq "Disabled") {
        Add-CheckResult -CheckId "SMB-001" -Title "SMBv1 disabled" -Passed $true -Details "SMB1Protocol is Disabled"
        Write-Log "PASS SMB-001: SMBv1 disabled"
    } else {
        Add-CheckResult -CheckId "SMB-001" -Title "SMBv1 disabled" -Passed $false -Details ("SMB1Protocol state: " + $smb1.State)
        Write-Log "FAIL SMB-001: SMBv1 state is $($smb1.State)"
    }
} catch {
    Add-CheckResult -CheckId "SMB-001" -Title "SMBv1 disabled" -Passed $false -Details $_.Exception.Message
    Write-Log "ERROR SMB-001: $($_.Exception.Message)"
}

# Summarize
$failed = ($Results | Where-Object { $_.passed -eq $false }).Count
$status = if ($failed -eq 0) { "PASS" } else { "FAIL" }

$report = @{
    reportId   = "sec-{0}" -f (Get-Date -Format "yyyyMMdd-HHmmss")
    timestamp  = (Get-Date).ToString("o")
    status     = $status
    failures   = $failed
    results    = $Results
}

$report | ConvertTo-Json -Depth 6 | Out-File -FilePath $Json -Encoding utf8

Write-Log "Security baseline completed: $status (failures=$failed)"
Write-Host "Security baseline completed: $status (failures=$failed)"
exit 0
