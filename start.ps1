# ==============================================================================
# M&S Delivery Express Kabacan - PowerShell Multi-App Launcher
# Cloudflare Tunnels + FastAPI Backend + Flutter Web Applications
# ==============================================================================

[CmdletBinding()]
param()

$ProjectRoot = $PSScriptRoot
Set-Location -Path $ProjectRoot

$MapboxToken = "pk.eyJ1IjoiamVhcmFyZCIsImEiOiJjbWE2ZjNlM2YwM2wyMmlvYW9mdDQ5OHJ5In0.57WdNE6fCl-qVJAoMZe40Q"
$env:MAPBOX_ACCESS_TOKEN = $MapboxToken

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  M&S Delivery Express Kabacan - Windows PS Launcher  " -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

# 1. Clean Ports
$TargetPorts = @(8000, 3000, 3001, 3002)
foreach ($Port in $TargetPorts) {
    try {
        $Pids = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique
        foreach ($p in $Pids) {
            if ($p -and $p -gt 0) {
                Write-Host "Freeing port $Port (Process ID: $p)..." -ForegroundColor Yellow
                Stop-Process -Id $p -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {}
}

# 2. Virtual Environment & Seed
$PythonExe = Join-Path $ProjectRoot ".venv\Scripts\python.exe"
if (-not (Test-Path $PythonExe)) {
    Write-Host "Creating Python virtual environment..." -ForegroundColor Blue
    python -m venv (Join-Path $ProjectRoot ".venv")
}

Write-Host "Ensuring dependencies are installed..." -ForegroundColor Blue
& $PythonExe -m pip install -r (Join-Path $ProjectRoot "backend\requirements.txt") -q

Write-Host "Running database migration and seed data..." -ForegroundColor Blue
& $PythonExe (Join-Path $ProjectRoot "backend\app\seed.py")

# 3. Cloudflare Tunnels
$ApiUrl = "http://localhost:8000"
$AdminUrl = "http://localhost:3000"
$CloudflaredInstalled = (Get-Command "cloudflared" -ErrorAction SilentlyContinue) -ne $null

$CfApiProc = $null
$CfAdminProc = $null

if ($CloudflaredInstalled) {
    Write-Host "Starting Cloudflare Tunnels..." -ForegroundColor Yellow
    $CfApiLog = [System.IO.Path]::GetTempFileName()
    $CfAdminLog = [System.IO.Path]::GetTempFileName()

    $CfApiProc = Start-Process "cloudflared" -ArgumentList "tunnel", "--url", "http://127.0.0.1:8000" -RedirectStandardOutput $CfApiLog -RedirectStandardError $CfApiLog -PassThru
    $CfAdminProc = Start-Process "cloudflared" -ArgumentList "tunnel", "--url", "http://127.0.0.1:3000", "--http-host-header", "0.0.0.0:3000" -RedirectStandardOutput $CfAdminLog -RedirectStandardError $CfAdminLog -PassThru

    Start-Sleep -Seconds 3
    for ($i = 0; $i -lt 12; $i++) {
        if (Test-Path $CfApiLog) {
            $Match = Select-String -Path $CfApiLog -Pattern 'https://[a-zA-Z0-9.-]+\.trycloudflare\.com' | Select-Object -First 1
            if ($Match) {
                $ApiUrl = $Match.Matches[0].Value
                break
            }
        }
        Start-Sleep -Seconds 1
    }

    if (Test-Path $CfAdminLog) {
        $MatchAdmin = Select-String -Path $CfAdminLog -Pattern 'https://[a-zA-Z0-9.-]+\.trycloudflare\.com' | Select-Object -First 1
        if ($MatchAdmin) {
            $AdminUrl = $MatchAdmin.Matches[0].Value
        }
    }
} else {
    Write-Host "cloudflared not found. Running with local URLs." -ForegroundColor Gray
}

# 4. Start FastAPI Backend
Write-Host "Starting FastAPI Backend on port 8000..." -ForegroundColor Green
$BackendProc = Start-Process $PythonExe -ArgumentList "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload", "--app-dir", "backend" -WorkingDirectory $ProjectRoot -PassThru

# 5. Start Flutter Apps
Write-Host "Starting Flutter Web Applications..." -ForegroundColor Green
$AdminProc = Start-Process "flutter" -ArgumentList "run", "-d", "web-server", "--web-port=3000", "--web-hostname=0.0.0.0", "--dart-define=API_BASE_URL=$ApiUrl", "--dart-define=MAPBOX_ACCESS_TOKEN=$MapboxToken" -WorkingDirectory (Join-Path $ProjectRoot "ui\apps\admin") -PassThru
$CustomerProc = Start-Process "flutter" -ArgumentList "run", "-d", "web-server", "--web-port=3001", "--web-hostname=0.0.0.0", "--dart-define=API_BASE_URL=$ApiUrl", "--dart-define=MAPBOX_ACCESS_TOKEN=$MapboxToken" -WorkingDirectory (Join-Path $ProjectRoot "ui\apps\customer") -PassThru
$RiderProc = Start-Process "flutter" -ArgumentList "run", "-d", "web-server", "--web-port=3002", "--web-hostname=0.0.0.0", "--dart-define=API_BASE_URL=$ApiUrl", "--dart-define=MAPBOX_ACCESS_TOKEN=$MapboxToken" -WorkingDirectory (Join-Path $ProjectRoot "ui\apps\rider") -PassThru

Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "✔ All services are running successfully!" -ForegroundColor Green
Write-Host "  • Backend API:      $ApiUrl" -ForegroundColor White
Write-Host "  • Backend Docs:     $ApiUrl/docs" -ForegroundColor White
Write-Host "  • Admin Console:    $AdminUrl (admin@mns.com / AdminPass123!)" -ForegroundColor White
Write-Host "  • Customer App:     http://localhost:3001 (customer@mns.com / CustomerPass123!)" -ForegroundColor White
Write-Host "  • Rider App:        http://localhost:3002 (rider@mns.com / RiderPass123!)" -ForegroundColor White
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to terminate all services..." -ForegroundColor Yellow

try {
    while ($true) {
        Start-Sleep -Seconds 1
    }
} finally {
    Write-Host "`nStopping all processes..." -ForegroundColor Yellow
    @($BackendProc, $AdminProc, $CustomerProc, $RiderProc, $CfApiProc, $CfAdminProc) | Where-Object { $_ -ne $null } | ForEach-Object {
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    }
    Write-Host "Shutdown complete." -ForegroundColor Green
}
