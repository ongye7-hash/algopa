# Flutter SDK auto installer (Windows)
# Created: 2026-05-12
# Steps:
#   1. Fetch latest stable from storage.googleapis.com/flutter_infra_release
#   2. Extract to C:\src\flutter
#   3. Add C:\src\flutter\bin to user PATH
#   4. Verify with flutter --version

$ErrorActionPreference = 'Stop'
$ProgressPreference   = 'SilentlyContinue'

$INSTALL_ROOT = 'C:\src'
$FLUTTER_DIR  = Join-Path $INSTALL_ROOT 'flutter'
$TMP_ZIP      = Join-Path $env:TEMP 'flutter_stable.zip'

Write-Host "[1/5] Fetching latest stable info..."
$json = Invoke-RestMethod -Uri 'https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json'
$stableHash = $json.current_release.stable
$stable = $json.releases | Where-Object { $_.hash -eq $stableHash } | Select-Object -First 1
$url = "https://storage.googleapis.com/flutter_infra_release/releases/$($stable.archive)"
Write-Host "    Version: $($stable.version)"
Write-Host "    URL    : $url"

Write-Host "[2/5] Preparing install dir..."
if (-not (Test-Path $INSTALL_ROOT)) {
  New-Item -ItemType Directory -Path $INSTALL_ROOT | Out-Null
}
if (Test-Path $FLUTTER_DIR) {
  throw "Already exists: $FLUTTER_DIR -- abort. Remove manually and retry."
}

Write-Host "[3/5] Downloading zip (~1GB)..."
$startTime = Get-Date
Invoke-WebRequest -Uri $url -OutFile $TMP_ZIP -UseBasicParsing
$elapsed = (Get-Date) - $startTime
$sizeMB  = (Get-Item $TMP_ZIP).Length / 1MB
Write-Host ("    Done: {0:N1} MB in {1:N1}s" -f $sizeMB, $elapsed.TotalSeconds)

Write-Host "[4/5] Extracting (a few minutes)..."
$startTime = Get-Date
Expand-Archive -Path $TMP_ZIP -DestinationPath $INSTALL_ROOT -Force
$elapsed = (Get-Date) - $startTime
Write-Host ("    Done: {0:N1}s" -f $elapsed.TotalSeconds)
Remove-Item $TMP_ZIP -Force

Write-Host "[5/5] Adding to user PATH..."
$binPath  = Join-Path $FLUTTER_DIR 'bin'
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath -notlike "*$binPath*") {
  $newPath = if ($userPath) { "$userPath;$binPath" } else { $binPath }
  [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
  Write-Host "    Added: $binPath"
} else {
  Write-Host "    Already in PATH"
}

$env:Path = $env:Path + ';' + $binPath
Write-Host ""
Write-Host "=== Install complete ==="
& "$binPath\flutter.bat" --version
