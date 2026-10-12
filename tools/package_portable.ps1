param(
    [string]$ApiUrl = "http://127.0.0.1:8000",
    [string]$OutputName = "CropMedic_Portable"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$FlutterDir = Join-Path $Root "crop_medic"
$BackendDir = Join-Path $Root "crop_medic_backend\backend"
$ReleaseRoot = Join-Path $Root "release"
$Stage = Join-Path $ReleaseRoot $OutputName
$ZipPath = Join-Path $ReleaseRoot "$OutputName.release.zip"

Write-Host "CropMedic portable release builder" -ForegroundColor Green
Write-Host "Root: $Root"

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter is required on the BUILD machine. Install/configure Flutter, then rerun."
}
if (-not (Test-Path (Join-Path $BackendDir "model\model.keras"))) {
    throw "Legacy backend model is missing. Install the validated base model before packaging."
}
if (-not (Test-Path (Join-Path $BackendDir "model\class_names.json"))) {
    throw "Legacy class_names.json is missing."
}

New-Item -ItemType Directory -Path $ReleaseRoot -Force | Out-Null
if (Test-Path $Stage) { Remove-Item $Stage -Recurse -Force }
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }

Write-Host "Building Flutter web release..." -ForegroundColor Cyan
Push-Location $FlutterDir
try {
    flutter pub get
    # The backend serves Flutter assets from /static while / returns index.html.
    # Build with a /static/ base href so CSS/JS/assets resolve correctly.
    flutter build web --release --base-href /static/ --dart-define=CROP_MEDIC_API_URL=$ApiUrl
}
finally {
    Pop-Location
}

Write-Host "Creating portable folder..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $Stage -Force | Out-Null
$StageBackend = Join-Path $Stage "backend"
Copy-Item $BackendDir $StageBackend -Recurse -Force

# Replace the backend's development static site only inside the release bundle
# with the canonical Flutter web build. The repository source is not modified.
$StageStatic = Join-Path $StageBackend "static"
if (Test-Path $StageStatic) { Remove-Item $StageStatic -Recurse -Force }
New-Item -ItemType Directory -Path $StageStatic -Force | Out-Null
Copy-Item (Join-Path $FlutterDir "build\web\*") $StageStatic -Recurse -Force

$StartScript = @'
$ErrorActionPreference = "Stop"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Backend = Join-Path $Here "backend"
$Venv = Join-Path $Here ".venv"

if (-not (Get-Command py -ErrorAction SilentlyContinue) -and -not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Python 3 is required. Install Python 3, then run this file again." -ForegroundColor Red
    Read-Host "Press Enter to close"
    exit 1
}

if (-not (Test-Path $Venv)) {
    Write-Host "First run: creating the CropMedic Python environment..." -ForegroundColor Cyan
    if (Get-Command py -ErrorAction SilentlyContinue) {
        py -3 -m venv $Venv
    } else {
        python -m venv $Venv
    }
}

$Python = Join-Path $Venv "Scripts\python.exe"
Write-Host "Checking backend dependencies..." -ForegroundColor Cyan
& $Python -m pip install -q -r (Join-Path $Backend "requirements.txt")

$env:CROPMEDIC_ENV = "development"
$env:CROPMEDIC_CORS_ORIGINS = "http://127.0.0.1:8000,http://localhost:8000"
$env:CROPMEDIC_TRUSTED_HOSTS = "localhost,127.0.0.1"
$env:CROPMEDIC_FORCE_HTTPS = "false"

Push-Location $Backend
try {
    Write-Host "Starting CropMedic at http://127.0.0.1:8000" -ForegroundColor Green
    Start-Process "http://127.0.0.1:8000"
    & $Python -m uvicorn main:app --host 127.0.0.1 --port 8000
}
finally {
    Pop-Location
}
'@
Set-Content -Path (Join-Path $Stage "START_CROPMEDIC.ps1") -Value $StartScript -Encoding UTF8

$Readme = @"
CropMedic Portable Release
=========================

This package does not require Git or your GitHub account.

Destination PC requirements:
- Windows 10/11
- Python 3 (64-bit)
- Internet access on the first run only if Python packages are not already cached

To run:
1. Extract the ZIP.
2. Right-click START_CROPMEDIC.ps1 and choose Run with PowerShell.
3. On the first run, allow the Python environment/dependencies to install.
4. CropMedic opens at http://127.0.0.1:8000.

The package contains the built Flutter web app, backend code and the validated
model files that were present on the build machine. It does not contain training
datasets and it does not retrain models.
"@
Set-Content -Path (Join-Path $Stage "README.txt") -Value $Readme -Encoding UTF8

Write-Host "Creating ZIP..." -ForegroundColor Cyan
Compress-Archive -Path (Join-Path $Stage "*") -DestinationPath $ZipPath -CompressionLevel Optimal

Write-Host "Portable release created:" -ForegroundColor Green
Write-Host $ZipPath
Write-Host "This is a no-Git runtime package. Training datasets are not included."
