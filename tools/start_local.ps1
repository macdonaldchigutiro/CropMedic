param(
    [string]$HostIp = "",
    [int]$ApiPort = 8000,
    [int]$WebPort = 8080
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$BackendDir = Join-Path $Root "crop_medic_backend\backend"
$FlutterDir = Join-Path $Root "crop_medic"

if (-not (Test-Path $BackendDir)) { throw "Backend folder not found: $BackendDir" }
if (-not (Test-Path $FlutterDir)) { throw "Flutter folder not found: $FlutterDir" }
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter is not available in PATH."
}

if (-not $HostIp) {
    try {
        $route = Get-NetRoute -DestinationPrefix "0.0.0.0/0" |
            Where-Object { $_.NextHop -ne "0.0.0.0" } |
            Sort-Object RouteMetric, InterfaceMetric |
            Select-Object -First 1
        if ($route) {
            $address = Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $route.InterfaceIndex |
                Where-Object { $_.IPAddress -notlike "169.254.*" -and $_.IPAddress -ne "127.0.0.1" } |
                Select-Object -First 1
            if ($address) { $HostIp = $address.IPAddress }
        }
    } catch {}
}

if (-not $HostIp) {
    $HostIp = "127.0.0.1"
    Write-Warning "Could not detect the LAN IPv4 address. Using localhost only. Pass -HostIp <your-PC-IP> for phone testing."
}

$PythonCommand = if (Get-Command py -ErrorAction SilentlyContinue) { "py -3" } elseif (Get-Command python -ErrorAction SilentlyContinue) { "python" } else { $null }
if (-not $PythonCommand) { throw "Python 3 is not available in PATH." }

$ApiUrl = "http://${HostIp}:$ApiPort"
$WebUrl = "http://${HostIp}:$WebPort"

Write-Host "CropMedic local launcher" -ForegroundColor Green
Write-Host "PC/LAN IP: $HostIp"
Write-Host "API: $ApiUrl"
Write-Host "App: $WebUrl"

$backendScript = @"
Set-Location '$BackendDir'
`$env:CROPMEDIC_ENV = 'development'
`$env:CROPMEDIC_CORS_ORIGINS = 'http://${HostIp}:$WebPort,http://127.0.0.1:$WebPort,http://localhost:$WebPort'
`$env:CROPMEDIC_TRUSTED_HOSTS = 'localhost,127.0.0.1,$HostIp'
`$env:CROPMEDIC_FORCE_HTTPS = 'false'
$PythonCommand -m uvicorn main:app --reload --host 0.0.0.0 --port $ApiPort
"@

$flutterScript = @"
Set-Location '$FlutterDir'
flutter run -d web-server --web-hostname 0.0.0.0 --web-port $WebPort --dart-define=CROP_MEDIC_API_URL=$ApiUrl
"@

Start-Process powershell -ArgumentList @("-NoExit", "-ExecutionPolicy", "Bypass", "-Command", $backendScript)
Start-Sleep -Seconds 3
Start-Process powershell -ArgumentList @("-NoExit", "-ExecutionPolicy", "Bypass", "-Command", $flutterScript)

Write-Host "Started backend and Flutter in two PowerShell windows." -ForegroundColor Green
Write-Host "Open on this PC: http://127.0.0.1:$WebPort"
if ($HostIp -ne "127.0.0.1") {
    Write-Host "Open on a phone on the same Wi-Fi: $WebUrl" -ForegroundColor Cyan
}
