$ErrorActionPreference = "Stop"

Write-Host "CI Tests: starting..."

# --- Test 1: Required files exist ---
$requiredPaths = @(
  "build/build-image.ps1",
  "build/sample-manifest.json",
  "tests/system-tests.ps1"
)

$missing = @()
foreach ($p in $requiredPaths) {
  if (-not (Test-Path $p)) { $missing += $p }
}
if ($missing.Count -gt 0) {
  throw "Missing required file(s): $($missing -join ', ')"
}
Write-Host "PASS: required files exist"

# --- Test 2: Manifest is valid JSON and has required keys ---
$manifest = Get-Content "build/sample-manifest.json" -Raw | ConvertFrom-Json

$requiredKeys = @(
  "buildId","hostname","osName","osVersion","architecture",
  "totalMemoryGB","diskSizeGB","freeDiskGB","buildTimestamp","buildStatus"
)

$missingKeys = @()
foreach ($k in $requiredKeys) {
  if ($null -eq $manifest.$k) { $missingKeys += $k }
}
if ($missingKeys.Count -gt 0) {
  throw "Manifest missing required key(s): $($missingKeys -join ', ')"
}
Write-Host "PASS: manifest JSON schema looks good"

# --- Test 3: PowerShell scripts parse cleanly (syntax check) ---
$scriptsToParse = @(
  "build/build-image.ps1",
  "tests/system-tests.ps1",
  "tests/ci-tests.ps1"
)

foreach ($s in $scriptsToParse) {
  $tokens = $null
  $errors = $null
  [void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $s), [ref]$tokens, [ref]$errors)
  if ($errors -and $errors.Count -gt 0) {
    throw "PowerShell parse errors in $s : $($errors | ForEach-Object { $_.Message } | Out-String)"
  }
}
Write-Host "PASS: scripts parse cleanly"

Write-Host "CI Tests: ALL PASSED"
exit 0
