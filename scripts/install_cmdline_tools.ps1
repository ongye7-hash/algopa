# Android cmdline-tools auto installer + ANDROID_HOME + license accept
# Created: 2026-05-12
# Why:
#   winget Google.AndroidStudio installed the SDK but left out the cmdline-tools
#   component, which Flutter doctor flags. We install it standalone.

$ErrorActionPreference = 'Stop'
$ProgressPreference   = 'SilentlyContinue'

$SDK_ROOT  = 'C:\Users\user\AppData\Local\Android\Sdk'
$CT_DIR    = Join-Path $SDK_ROOT 'cmdline-tools'
$LATEST    = Join-Path $CT_DIR  'latest'
$TMP_ZIP   = Join-Path $env:TEMP 'cmdline-tools.zip'

# Pin a known-stable revision. _latest.zip suffix means Google rotates the file
# under this URL when they ship a newer revision.
$URL = 'https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip'

Write-Host "[1/5] Downloading cmdline-tools zip (~120 MB)..."
Invoke-WebRequest -Uri $URL -OutFile $TMP_ZIP -UseBasicParsing
$sizeMB = (Get-Item $TMP_ZIP).Length / 1MB
Write-Host ("    Done: {0:N1} MB" -f $sizeMB)

Write-Host "[2/5] Extracting..."
$tmpExtract = Join-Path $env:TEMP 'cmdline-tools-extract'
if (Test-Path $tmpExtract) { Remove-Item $tmpExtract -Recurse -Force }
Expand-Archive -Path $TMP_ZIP -DestinationPath $tmpExtract -Force
Remove-Item $TMP_ZIP -Force

# zip contains a top-level "cmdline-tools" dir. Move its contents to <SDK>/cmdline-tools/latest/
Write-Host "[3/5] Placing into SDK at cmdline-tools/latest/..."
if (-not (Test-Path $CT_DIR)) { New-Item -ItemType Directory -Path $CT_DIR | Out-Null }
if (Test-Path $LATEST) { Remove-Item $LATEST -Recurse -Force }
$src = Join-Path $tmpExtract 'cmdline-tools'
Move-Item -Path $src -Destination $LATEST
Remove-Item $tmpExtract -Recurse -Force

Write-Host "[4/5] Setting ANDROID_HOME (user env)..."
[Environment]::SetEnvironmentVariable('ANDROID_HOME', $SDK_ROOT, 'User')
[Environment]::SetEnvironmentVariable('ANDROID_SDK_ROOT', $SDK_ROOT, 'User')
$env:ANDROID_HOME     = $SDK_ROOT
$env:ANDROID_SDK_ROOT = $SDK_ROOT

# Add platform-tools and cmdline-tools/latest/bin to user PATH
$pathsToAdd = @(
  "$LATEST\bin",
  "$SDK_ROOT\platform-tools"
)
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
foreach ($p in $pathsToAdd) {
  if ($userPath -notlike "*$p*") {
    $userPath = "$userPath;$p"
    Write-Host "    PATH += $p"
  }
}
[Environment]::SetEnvironmentVariable('Path', $userPath, 'User')

Write-Host "[5/5] Verifying sdkmanager..."
$env:Path = "$LATEST\bin;$SDK_ROOT\platform-tools;$env:Path"
sdkmanager --version
Write-Host ""
Write-Host "=== cmdline-tools install complete ==="
