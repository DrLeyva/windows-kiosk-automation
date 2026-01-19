$ErrorActionPreference = "Stop"

$TestRoot = "C:\kiosk-build\tests"
$LogFile  = "$TestRoot\system-tests.log"

function Write-Log {
    param([string]$Message)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$ts - $Message" | Out-File -FilePath $LogFile -Append -Encoding utf8
}

Write-Log "Starting system validation tests"

$TestFailures = 0

# Test 1: Kiosk user exists
Write-Log "Test: kiosk user exists"
if (Get-LocalUser -Name "kioskuser" -ErrorAction SilentlyContinue) {
    Write-Log "PASS: kioskuser exists"
} else {
    Write-Log "FAIL: kioskuser missing"
    $TestFailures++
}

# Test 2: kiosk user is not admin
Write-Log "Test: kiosk user is not Administrator"
$admins = Get-LocalGroupMember -Group "Administrators" | Select-Object -ExpandProperty Name
if ($admins -notmatch "(^|\\)kioskuser$") {
    Write-Log "PASS: kioskuser is not admin"
} else {
    Write-Log "FAIL: kioskuser has admin rights"
    $TestFailures++
}

# Test 3: Image manifest exists
Write-Log "Test: image manifest exists"
if (Test-Path "C:\kiosk-build\build\manifest.json") {
    Write-Log "PASS: manifest.json found"
} else {
    Write-Log "FAIL: manifest.json missing"
    $TestFailures++
}

# Test 4: Firewall enabled
Write-Log "Test: Windows Firewall enabled"
$fw = Get-NetFirewallProfile | Where-Object { $_.Enabled -eq $false }
if (-not $fw) {
    Write-Log "PASS: Firewall enabled on all profiles"
} else {
    Write-Log "FAIL: Firewall disabled on one or more profiles"
    $TestFailures++
}

# Summary
if ($TestFailures -eq 0) {
    Write-Log "ALL TESTS PASSED"
    exit 0
} else {
    Write-Log "TESTS FAILED: $TestFailures failure(s)"
    exit 1
}
