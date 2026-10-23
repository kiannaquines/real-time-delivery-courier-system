@echo off
setlocal enabledelayedexpansion

REM ==============================================================================
REM M&S Delivery Express Kabacan - Android APK Builder (Windows Command Prompt)
REM Compiles Flutter APKs for Customer and Rider applications with API configuration
REM ==============================================================================

title M&S Delivery Express - Android APK Builder

set "PROJECT_ROOT=%~dp0"
cd /d "%PROJECT_ROOT%"

REM Check for Help flags
if /i "%~1"=="/?" goto :ShowHelp
if /i "%~1"=="-h" goto :ShowHelp
if /i "%~1"=="--help" goto :ShowHelp
if /i "%~1"=="help" goto :ShowHelp

REM 1. Verify Flutter SDK is in PATH
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo.
    echo ==============================================================================
    echo [ERROR] Flutter SDK was not found in your PATH!
    echo ==============================================================================
    echo Please ensure Flutter is installed and added to your system PATH:
    echo   1. Download Flutter SDK from https://flutter.dev/
    echo   2. Add your 'flutter\bin' directory to your Windows Environment Variables
    echo   3. Restart this terminal or command prompt
    echo.
    pause
    exit /b 1
)

REM 2. Read Default Configuration from .env if present
set "API_URL=http://localhost:8000"
set "MAPBOX_ACCESS_TOKEN=pk.eyJ1IjoiamVhcmFyZCIsImEiOiJjbWE2ZjNlM2YwM2wyMmlvYW9mdDQ5OHJ5In0.57WdNE6fCl-qVJAoMZe40Q"

if exist "%PROJECT_ROOT%.env" (
    for /f "usebackq tokens=1,* delims==" %%A in ("%PROJECT_ROOT%.env") do (
        set "ENV_KEY=%%A"
        set "ENV_VAL=%%B"
        if defined ENV_KEY (
            for /f "tokens=* delims= " %%K in ("!ENV_KEY!") do set "CLEAN_KEY=%%K"
            if not "!CLEAN_KEY:~0,1!"=="#" (
                if /i "!CLEAN_KEY!"=="API_BASE_URL" set "API_URL=!ENV_VAL!"
                if /i "!CLEAN_KEY!"=="MAPBOX_ACCESS_TOKEN" set "MAPBOX_ACCESS_TOKEN=!ENV_VAL!"
            )
        )
    )
)

REM 3. Parse Command-Line Arguments (if provided)
set "CLI_MODE=0"
set "TARGET_APP="
set "BUILD_MODE=release"
set "SPLIT_FLAG="

if not "%~1"=="" (
    set "CLI_MODE=1"
    set "TARGET_APP=%~1"
    
    if not "%~2"=="" (
        if /i "%~2"=="--split-per-abi" (
            set "SPLIT_FLAG=--split-per-abi"
        ) else if /i "%~2"=="split" (
            set "SPLIT_FLAG=--split-per-abi"
        ) else (
            set "BUILD_MODE=%~2"
        )
    )
    
    if not "%~3"=="" (
        if /i "%~3"=="--split-per-abi" (
            set "SPLIT_FLAG=--split-per-abi"
        ) else if /i "%~3"=="split" (
            set "SPLIT_FLAG=--split-per-abi"
        ) else (
            set "API_URL=%~3"
        )
    )
    
    if not "%~4"=="" (
        if /i "%~4"=="--split-per-abi" set "SPLIT_FLAG=--split-per-abi"
        if /i "%~4"=="split" set "SPLIT_FLAG=--split-per-abi"
    )
    
    REM Validate TARGET_APP argument
    if /i not "!TARGET_APP!"=="customer" if /i not "!TARGET_APP!"=="rider" if /i not "!TARGET_APP!"=="all" (
        echo [ERROR] Unknown application: '!TARGET_APP!'.
        echo Allowed options: customer, rider, all
        exit /b 1
    )
    
    goto :StartBuild
)

REM 4. Interactive Configuration Menu
:InteractiveMenu
cls
echo ==============================================================================
echo        M^&S Delivery Express Kabacan - Android APK Builder (Windows)
echo ==============================================================================
echo.
echo Select target application:
echo   [1] Customer App  (ui\apps\customer)
echo   [2] Rider App     (ui\apps\rider)
echo   [3] Both Apps     (Customer and Rider)
echo   [4] Exit
echo.
set /p "APP_CHOICE=Select an option [1-4] (default 1): "
if "!APP_CHOICE!"=="" set "APP_CHOICE=1"
if "!APP_CHOICE!"=="1" set "TARGET_APP=customer"
if "!APP_CHOICE!"=="2" set "TARGET_APP=rider"
if "!APP_CHOICE!"=="3" set "TARGET_APP=all"
if "!APP_CHOICE!"=="4" exit /b 0

echo.
echo Select build mode:
echo   [1] Release (Optimized production build) [Recommended]
echo   [2] Debug   (Faster development build)
echo.
set /p "MODE_CHOICE=Select mode [1-2] (default 1): "
if "!MODE_CHOICE!"=="" set "MODE_CHOICE=1"
if "!MODE_CHOICE!"=="1" set "BUILD_MODE=release"
if "!MODE_CHOICE!"=="2" set "BUILD_MODE=debug"

echo.
echo Select APK packaging format:
echo   [1] Universal APK (Single fat APK - installs on any Android device) [Default]
echo   [2] Split APKs    (--split-per-abi, smaller individual APKs)
echo.
set /p "SPLIT_CHOICE=Select format [1-2] (default 1): "
if "!SPLIT_CHOICE!"=="2" (
    set "SPLIT_FLAG=--split-per-abi"
) else (
    set "SPLIT_FLAG="
)

echo.
echo ==============================================================================
echo Backend API Endpoint Configuration:
echo   Detected API URL: !API_URL!
echo.
echo   Network Tips for Android testing:
echo   - Physical Device (same Wi-Fi):  http://^<YOUR_PC_IP^>:8000  (e.g., http://192.168.1.50:8000)
echo   - Android Emulator (AVD):        http://10.0.2.2:8000
echo   - Cloudflare Tunnel / Domain:    https://your-tunnel.trycloudflare.com
echo ==============================================================================
set /p "INPUT_API_URL=Enter API Base URL (press ENTER to use [!API_URL!]): "
if defined INPUT_API_URL set "API_URL=!INPUT_API_URL!"

:StartBuild
set "OUTPUT_DIR=%PROJECT_ROOT%build_output\apks"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

set "BUILD_FAILED=0"

if /i "!TARGET_APP!"=="all" (
    call :BuildApp customer
    call :BuildApp rider
) else (
    call :BuildApp !TARGET_APP!
)

REM 5. Post-Build Summary
cd /d "%PROJECT_ROOT%"
echo.
if %BUILD_FAILED% equ 0 (
    echo ==============================================================================
    echo                     BUILD COMPLETED SUCCESSFULLY!
    echo ==============================================================================
    echo.
    echo All generated APKs are located at:
    echo   %OUTPUT_DIR%
    echo.
    echo Output files:
    for %%F in ("%OUTPUT_DIR%\*.apk") do (
        if exist "%%~fF" (
            set /a "SIZE_MB=%%~zF / 1048576"
            echo   - %%~nxF [!SIZE_MB! MB]
        )
    )
    echo.
    if "%CLI_MODE%"=="0" (
        set /p "OPEN_DIR=Open APK folder in Windows File Explorer? (Y/n): "
        if /i "!OPEN_DIR!"=="Y" explorer.exe "%OUTPUT_DIR%"
        if "!OPEN_DIR!"=="" explorer.exe "%OUTPUT_DIR%"
    )
) else (
    echo ==============================================================================
    echo                      BUILD FINISHED WITH ERRORS
    echo ==============================================================================
    echo Please check the output messages above for compiler or gradle errors.
)

if "%CLI_MODE%"=="0" (
    echo.
    echo Press any key to exit...
    pause >nul
)

exit /b %BUILD_FAILED%

REM ==============================================================================
REM Helper Subroutine: Build a Single Flutter Application
REM ==============================================================================
:BuildApp
set "CURRENT_APP=%~1"
set "APP_DIR=%PROJECT_ROOT%ui\apps\%CURRENT_APP%"

echo.
echo ==============================================================================
echo [BUILDING] App: %CURRENT_APP% ^| Mode: %BUILD_MODE%
echo Path:     %APP_DIR%
echo API URL:  !API_URL!
if defined SPLIT_FLAG (
    echo Format:   Split per ABI (--split-per-abi)
) else (
    echo Format:   Universal Fat APK
)
echo ==============================================================================

if not exist "%APP_DIR%" (
    echo [ERROR] Application directory "%APP_DIR%" does not exist.
    set "BUILD_FAILED=1"
    goto :eof
)

cd /d "%APP_DIR%"

echo.
echo [Step 1/3] Resolving Flutter dependencies (flutter pub get)...
call flutter pub get
if %errorlevel% neq 0 (
    echo [ERROR] 'flutter pub get' failed in %CURRENT_APP%.
    set "BUILD_FAILED=1"
    goto :eof
)

echo.
echo [Step 2/3] Compiling Android APK with Flutter (Mode: %BUILD_MODE%)...
if defined SPLIT_FLAG (
    call flutter build apk --%BUILD_MODE% %SPLIT_FLAG% --dart-define=API_BASE_URL="!API_URL!" --dart-define=MAPBOX_ACCESS_TOKEN="!MAPBOX_ACCESS_TOKEN!"
) else (
    call flutter build apk --%BUILD_MODE% --dart-define=API_BASE_URL="!API_URL!" --dart-define=MAPBOX_ACCESS_TOKEN="!MAPBOX_ACCESS_TOKEN!"
)

if %errorlevel% neq 0 (
    echo.
    echo ==============================================================================
    echo [ERROR] Flutter APK compilation failed for %CURRENT_APP%!
    echo ==============================================================================
    echo Common troubleshooting checks:
    echo   1. Run 'flutter doctor' to inspect Android SDK, Android Studio, and Java tools.
    echo   2. Run 'flutter doctor --android-licenses' to accept Android SDK licenses.
    echo   3. Ensure Java Development Kit 17 (JDK 17) is installed and JAVA_HOME is set.
    set "BUILD_FAILED=1"
    goto :eof
)

echo.
echo [Step 3/3] Exporting generated APK to build_output\apks...
set "FLUTTER_OUT=%APP_DIR%\build\app\outputs\flutter-apk"

if not exist "%FLUTTER_OUT%" (
    echo [WARN] Expected build directory '%FLUTTER_OUT%' was not found.
    goto :eof
)

if defined SPLIT_FLAG (
    for %%F in ("%FLUTTER_OUT%\app-*.apk") do (
        if exist "%%~fF" (
            set "SRC_NAME=%%~nxF"
            set "DEST_NAME=!SRC_NAME:app-=%CURRENT_APP%-app-!"
            copy /y "%%F" "%OUTPUT_DIR%\!DEST_NAME!" >nul
            for %%A in ("%OUTPUT_DIR%\!DEST_NAME!") do (
                set /a "SIZE_MB=%%~zA / 1048576"
                echo   [SAVED] !DEST_NAME! [!SIZE_MB! MB]
            )
        )
    )
) else (
    set "SRC_APK=%FLUTTER_OUT%\app-%BUILD_MODE%.apk"
    set "DEST_APK=%OUTPUT_DIR%\%CURRENT_APP%-app-%BUILD_MODE%.apk"
    if exist "!SRC_APK!" (
        copy /y "!SRC_APK!" "!DEST_APK!" >nul
        for %%F in ("!DEST_APK!") do (
            set /a "SIZE_MB=%%~zF / 1048576"
            echo   [SAVED] %%~nxF [!SIZE_MB! MB] -^> !DEST_APK!
        )
    ) else (
        echo [WARN] Could not find '!SRC_APK!'. Copying all available APKs...
        copy /y "%FLUTTER_OUT%\*.apk" "%OUTPUT_DIR%\" >nul
    )
)

echo.
echo [SUCCESS] %CURRENT_APP% APK ready!
goto :eof

REM ==============================================================================
REM Help Information
REM ==============================================================================
:ShowHelp
echo.
echo ==============================================================================
echo        M^&S Delivery Express Kabacan - Android APK Builder (Windows)
echo ==============================================================================
echo.
echo Usage:
echo   build_apk.bat [app] [mode] [api_url] [--split-per-abi]
echo.
echo Arguments:
echo   app              Target application: 'customer', 'rider', or 'all'
echo   mode             Build mode: 'release' (default) or 'debug'
echo   api_url          Backend API endpoint URL (optional, defaults to .env value)
echo   --split-per-abi  Produces separate smaller APKs per architecture (optional)
echo.
echo Examples:
echo   build_apk.bat                                   Launch interactive menu
echo   build_apk.bat customer                          Build Customer Release APK
echo   build_apk.bat rider                             Build Rider Release APK
echo   build_apk.bat all                               Build both Customer and Rider APKs
echo   build_apk.bat customer debug                    Build Customer Debug APK
echo   build_apk.bat rider release http://192.168.1.50:8000
echo   build_apk.bat all release --split-per-abi
echo.
echo Output Directory:
echo   All output APKs are saved to: build_output\apks\
echo.
exit /b 0
