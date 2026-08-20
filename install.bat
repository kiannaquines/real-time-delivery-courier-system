@echo off
setlocal enabledelayedexpansion

REM ==============================================================================
REM M&S Delivery Express Kabacan - One-Click Automated Windows Installer (CMD)
REM ==============================================================================

title M&S Delivery Express Kabacan - System Installer

set "PROJECT_ROOT=%~dp0"
cd /d "%PROJECT_ROOT%"

REM Check for Python
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Python 3 was not found in PATH.
    echo Please install Python 3.10+ from python.org or via 'winget install Python.Python.3.11'.
    pause
    exit /b 1
)

REM Run universal installer
python "%PROJECT_ROOT%install.py" %*

if %errorlevel% neq 0 (
    echo [ERROR] Installation failed. Check messages above.
    pause
    exit /b %errorlevel%
)

pause
