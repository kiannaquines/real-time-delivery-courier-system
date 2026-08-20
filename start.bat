@echo off
setlocal enabledelayedexpansion

REM ==============================================================================
REM M&S Delivery Express Kabacan - Windows Unified Interactive Launcher
REM Cloudflare Tunnels + FastAPI Backend + Flutter Web Applications
REM ==============================================================================

title M&S Delivery Express Kabacan - Multi-App Launcher

echo ==============================================================================
echo     M&S Delivery Express Kabacan - Windows Unified Launcher
echo ==============================================================================

set "MAPBOX_ACCESS_TOKEN=pk.eyJ1IjoiamVhcmFyZCIsImEiOiJjbWE2ZjNlM2YwM2wyMmlvYW9mdDQ5OHJ5In0.57WdNE6fCl-qVJAoMZe40Q"
set "PROJECT_ROOT=%~dp0"
cd /d "%PROJECT_ROOT%"

REM 1. Check for Python
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Python 3 was not found in PATH. Please install Python 3.10+ from python.org or via 'winget install Python.Python.3.11'.
    pause
    exit /b 1
)

REM 2. Check for Flutter
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Flutter SDK was not found in PATH. Please install Flutter from flutter.dev.
    pause
    exit /b 1
)

REM 3. Python Virtual Environment Setup
if not exist ".venv\Scripts\python.exe" (
    echo [INFO] Creating Python virtual environment in .venv...
    python -m venv .venv
)

echo [INFO] Installing backend dependencies...
call .venv\Scripts\python.exe -m pip install -r backend\requirements.txt -q

REM 4. Seed Database
echo [INFO] Ensuring database is migrated and seeded...
call .venv\Scripts\python.exe backend\app\seed.py

REM 5. Cloudflare Tunnel Verification
set "API_URL=http://localhost:8000"
set "ADMIN_URL=http://localhost:3000"
set "USE_CLOUDFLARE=0"

where cloudflared >nul 2>nul
if %errorlevel% equ 0 (
    set "USE_CLOUDFLARE=1"
    echo [INFO] Cloudflared found. Starting Cloudflare Tunnels...
    start /b "" cloudflared tunnel --url http://127.0.0.1:8000 > "%TEMP%\cf_api.log" 2>&1
    start /b "" cloudflared tunnel --url http://127.0.0.1:3000 --http-host-header 0.0.0.0:3000 > "%TEMP%\cf_admin.log" 2>&1

    REM Wait briefly for tunnel URLs
    timeout /t 3 /nobreak >nul
    for /f "tokens=*" %%a in ('findstr /r "https://[a-zA-Z0-9.-]*\.trycloudflare\.com" "%TEMP%\cf_api.log" 2^>nul') do (
        set "API_URL=%%a"
    )
    for /f "tokens=*" %%a in ('findstr /r "https://[a-zA-Z0-9.-]*\.trycloudflare\.com" "%TEMP%\cf_admin.log" 2^>nul') do (
        set "ADMIN_URL=%%a"
    )
) else (
    echo [WARN] cloudflared not found in PATH. Defaulting to local URLs.
    echo        (To enable online tunnels: 'winget install Cloudflare.cloudflared')
)

REM 6. Start FastAPI Backend
echo [INFO] Starting FastAPI Backend on port 8000...
start "M&S Backend Server" /b .venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload --app-dir backend

REM 7. Start Admin Web App
echo [INFO] Starting Admin Web App on port 3000...
start "M&S Admin Portal" /d "ui\apps\admin" flutter run -d web-server --web-port=3000 --web-hostname=0.0.0.0 --dart-define=API_BASE_URL=%API_URL% --dart-define=MAPBOX_ACCESS_TOKEN=%MAPBOX_ACCESS_TOKEN%

REM 8. Start Customer App (Web Server)
echo [INFO] Starting Customer App on port 3001...
start "M&S Customer App" /d "ui\apps\customer" flutter run -d web-server --web-port=3001 --web-hostname=0.0.0.0 --dart-define=API_BASE_URL=%API_URL% --dart-define=MAPBOX_ACCESS_TOKEN=%MAPBOX_ACCESS_TOKEN%

REM 9. Start Rider App (Web Server)
echo [INFO] Starting Rider App on port 3002...
start "M&S Rider App" /d "ui\apps\rider" flutter run -d web-server --web-port=3002 --web-hostname=0.0.0.0 --dart-define=API_BASE_URL=%API_URL% --dart-define=MAPBOX_ACCESS_TOKEN=%MAPBOX_ACCESS_TOKEN%

echo.
echo ==============================================================================
echo   All M&S Delivery Services are running:
echo   - Backend API:       %API_URL%
echo   - FastAPI Docs:      %API_URL%/docs
echo   - Admin Console:     http://localhost:3000  (admin@mns.com / AdminPass123!)
echo   - Customer App:      http://localhost:3001  (customer@mns.com / CustomerPass123!)
echo   - Rider App:         http://localhost:3002  (rider@mns.com / RiderPass123!)
echo ==============================================================================
echo.
echo Press any key to stop all services...
pause >nul

echo Stopping services...
taskkill /f /im uvicorn.exe 2>nul
taskkill /f /im cloudflared.exe 2>nul
taskkill /f /im dart.exe 2>nul

echo All services stopped.
