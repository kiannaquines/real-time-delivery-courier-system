# ==============================================================================
# M&S Delivery Express Kabacan - Android APK Builder (Windows PowerShell)
# Compiles Flutter APKs for Customer and Rider applications with API configuration
# ==============================================================================

[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [ValidateSet("customer", "rider", "all", "help")]
    [string]$App,

    [Parameter(Position=1)]
    [ValidateSet("release", "debug")]
    [string]$Mode = "release",

    [Parameter(Position=2)]
    [string]$ApiUrl,

    [string]$MapboxToken,

    [switch]$SplitPerAbi,

    [switch]$OpenFolder,

    [switch]$Help
)

$ProjectRoot = $PSScriptRoot
Set-Location -Path $ProjectRoot

function Show-Usage {
    Write-Host @"
==============================================================================
       M&S Delivery Express Kabacan - Android APK Builder (PowerShell)
==============================================================================

Usage:
  .\build_apk.ps1 [-App <customer|rider|all>] [-Mode <release|debug>] [-ApiUrl <url>] [-SplitPerAbi] [-OpenFolder]

Parameters:
  -App          Target application: 'customer', 'rider', or 'all'
  -Mode         Build mode: 'release' (default) or 'debug'
  -ApiUrl       Backend API URL (e.g. http://192.168.1.50:8000)
  -MapboxToken  Mapbox Access Token (defaults to .env value)
  -SplitPerAbi  Generates separate APKs for arm64-v8a, armeabi-v7a, and x86_64
  -OpenFolder   Opens build_output\apks folder in Windows Explorer upon completion
  -Help         Displays this help text

Examples:
  .\build_apk.ps1                                    # Launch interactive menu
  .\build_apk.ps1 -App customer                      # Build Customer Release APK
  .\build_apk.ps1 -App rider -Mode release           # Build Rider Release APK
  .\build_apk.ps1 -App all -ApiUrl http://192.168.1.50:8000
  .\build_apk.ps1 -App customer -SplitPerAbi
"@
    exit 0
}

if ($Help -or $App -eq "help") {
    Show-Usage
}

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "       M&S Delivery Express Kabacan - Android APK Builder (Windows)           " -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan

# 1. Verify Flutter SDK
$FlutterCmd = Get-Command "flutter" -ErrorAction SilentlyContinue
if (-not $FlutterCmd) {
    Write-Host "[ERROR] Flutter SDK was not found in PATH!" -ForegroundColor Red
    Write-Host "Please install Flutter SDK from https://flutter.dev/ and add flutter\bin to PATH." -ForegroundColor Yellow
    exit 1
}

# 2. Read Defaults from .env
$DefaultApiUrl = "http://localhost:8000"
$DefaultMapboxToken = "pk.eyJ1IjoiamVhcmFyZCIsImEiOiJjbWE2ZjNlM2YwM2wyMmlvYW9mdDQ5OHJ5In0.57WdNE6fCl-qVJAoMZe40Q"

$EnvFile = Join-Path $ProjectRoot ".env"
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith("#")) {
            $parts = $line.Split("=", 2)
            if ($parts.Count -eq 2) {
                $k = $parts[0].Trim()
                $v = $parts[1].Trim()
                if ($k -eq "API_BASE_URL" -and -not $ApiUrl) { $DefaultApiUrl = $v }
                if ($k -eq "MAPBOX_ACCESS_TOKEN" -and -not $MapboxToken) { $DefaultMapboxToken = $v }
            }
        }
    }
}

if (-not $ApiUrl) {
    $ApiUrl = $DefaultApiUrl
}
if (-not $MapboxToken) {
    $MapboxToken = $DefaultMapboxToken
}

# 3. Interactive Mode (if -App is not specified)
$IsInteractive = -not $PSBoundParameters.ContainsKey('App')

if ($IsInteractive) {
    Write-Host "`nSelect application to build:" -ForegroundColor White
    Write-Host "  [1] Customer App  (ui\apps\customer)"
    Write-Host "  [2] Rider App     (ui\apps\rider)"
    Write-Host "  [3] Both Apps     (Customer and Rider)"
    Write-Host "  [4] Exit"
    $AppChoice = Read-Host "`nEnter selection [1-4] (default: 1)"
    switch ($AppChoice) {
        "2"     { $App = "rider" }
        "3"     { $App = "all" }
        "4"     { exit 0 }
        default { $App = "customer" }
    }

    Write-Host "`nSelect build mode:" -ForegroundColor White
    Write-Host "  [1] Release (Optimized production build) [Recommended]"
    Write-Host "  [2] Debug   (Faster development build)"
    $ModeChoice = Read-Host "`nEnter mode [1-2] (default: 1)"
    if ($ModeChoice -eq "2") {
        $Mode = "debug"
    } else {
        $Mode = "release"
    }

    Write-Host "`nSelect APK packaging format:" -ForegroundColor White
    Write-Host "  [1] Universal APK (Single fat APK - installs on any device) [Recommended]"
    Write-Host "  [2] Split APKs    (--split-per-abi, smaller separate APKs)"
    $SplitChoice = Read-Host "`nEnter format [1-2] (default: 1)"
    if ($SplitChoice -eq "2") {
        $SplitPerAbi = $true
    }

    Write-Host "`n==============================================================================" -ForegroundColor DarkCyan
    Write-Host "Backend API Configuration" -ForegroundColor DarkCyan
    Write-Host "  Current configured API URL: $ApiUrl"
    Write-Host "  Tips for Android testing:"
    Write-Host "    - Physical device on same Wi-Fi:  http://<YOUR_PC_IP>:8000"
    Write-Host "    - Android Emulator (AVD):         http://10.0.2.2:8000"
    Write-Host "    - Cloudflare Tunnel / Domain:     https://your-tunnel.trycloudflare.com"
    Write-Host "==============================================================================" -ForegroundColor DarkCyan
    $CustomApiUrl = Read-Host "`nEnter API Base URL (press ENTER to use [$ApiUrl])"
    if ($CustomApiUrl -and $CustomApiUrl.Trim() -ne "") {
        $ApiUrl = $CustomApiUrl.Trim()
    }
}

# 4. Target Output Folder
$OutputDir = Join-Path $ProjectRoot "build_output\apks"
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

function Build-FlutterApp {
    param(
        [string]$TargetAppName
    )

    $AppDir = Join-Path $ProjectRoot "ui\apps\$TargetAppName"
    if (-not (Test-Path $AppDir)) {
        Write-Host "[ERROR] Directory not found: $AppDir" -ForegroundColor Red
        return $false
    }

    Write-Host "`n------------------------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host " [BUILDING] $TargetAppName (Mode: $Mode)" -ForegroundColor Cyan
    Write-Host " Path:     $AppDir"
    Write-Host " API URL:  $ApiUrl"
    Write-Host " Packaging: $(if ($SplitPerAbi) { '--split-per-abi' } else { 'Universal Fat APK' })"
    Write-Host "------------------------------------------------------------------------------" -ForegroundColor Cyan

    Push-Location $AppDir
    try {
        Write-Host "`n[1/3] Resolving dependencies (flutter pub get)..." -ForegroundColor Yellow
        & flutter pub get
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[ERROR] 'flutter pub get' failed in $TargetAppName" -ForegroundColor Red
            return $false
        }

        Write-Host "`n[2/3] Compiling Android APK with Flutter..." -ForegroundColor Yellow
        $BuildArgs = @("build", "apk", "--$Mode", "--dart-define=API_BASE_URL=$ApiUrl", "--dart-define=MAPBOX_ACCESS_TOKEN=$MapboxToken")
        if ($SplitPerAbi) {
            $BuildArgs += "--split-per-abi"
        }

        & flutter @BuildArgs
        if ($LASTEXITCODE -ne 0) {
            Write-Host "`n[ERROR] Flutter build apk failed for $TargetAppName!" -ForegroundColor Red
            Write-Host "Troubleshooting:" -ForegroundColor Yellow
            Write-Host "  1. Run 'flutter doctor' to check Android toolchain."
            Write-Host "  2. Run 'flutter doctor --android-licenses' to accept Android SDK licenses."
            Write-Host "  3. Verify Java JDK 17 is installed."
            return $false
        }

        Write-Host "`n[3/3] Exporting generated APK(s)..." -ForegroundColor Yellow
        $FlutterOutDir = Join-Path $AppDir "build\app\outputs\flutter-apk"
        
        if ($SplitPerAbi) {
            Get-ChildItem -Path $FlutterOutDir -Filter "app-*.apk" | ForEach-Object {
                $NewName = $_.Name -replace "^app-", "$TargetAppName-app-"
                $Dest = Join-Path $OutputDir $NewName
                Copy-Item -Path $_.FullName -Destination $Dest -Force
                $SizeMB = [math]::Round($_.Length / 1MB, 2)
                Write-Host "  [SAVED] $NewName ($SizeMB MB)" -ForegroundColor Green
            }
        } else {
            $SrcApk = Join-Path $FlutterOutDir "app-$Mode.apk"
            $DestName = "$TargetAppName-app-$Mode.apk"
            $DestPath = Join-Path $OutputDir $DestName
            if (Test-Path $SrcApk) {
                Copy-Item -Path $SrcApk -Destination $DestPath -Force
                $FileObj = Get-Item $DestPath
                $SizeMB = [math]::Round($FileObj.Length / 1MB, 2)
                Write-Host "  [SAVED] $DestName ($SizeMB MB) -> $DestPath" -ForegroundColor Green
            } else {
                Write-Host "  [WARN] Expected $SrcApk not found. Copying all APKs in folder..." -ForegroundColor Yellow
                Copy-Item -Path (Join-Path $FlutterOutDir "*.apk") -Destination $OutputDir -Force
            }
        }

        Write-Host "`n[SUCCESS] $TargetAppName APK completed successfully!" -ForegroundColor Green
        return $true
    } finally {
        Pop-Location
    }
}

# 5. Execute Build
$AllSuccess = $true
if ($App -eq "all") {
    $r1 = Build-FlutterApp -TargetAppName "customer"
    $r2 = Build-FlutterApp -TargetAppName "rider"
    $AllSuccess = $r1 -and $r2
} else {
    $AllSuccess = Build-FlutterApp -TargetAppName $App
}

# 6. Final Summary
Write-Host "`n==============================================================================" -ForegroundColor $(if ($AllSuccess) { "Green" } else { "Red" })
if ($AllSuccess) {
    Write-Host "                     BUILD COMPLETED SUCCESSFULLY!                            " -ForegroundColor Green
    Write-Host "==============================================================================" -ForegroundColor Green
    Write-Host "`nOutput Directory: $OutputDir" -ForegroundColor White
    Write-Host "`nGenerated APK Files:" -ForegroundColor White
    Get-ChildItem -Path $OutputDir -Filter "*.apk" | ForEach-Object {
        $SizeMB = [math]::Round($_.Length / 1MB, 2)
        Write-Host "  - $($_.Name) ($SizeMB MB)" -ForegroundColor Cyan
    }

    if ($OpenFolder) {
        Invoke-Item $OutputDir
    } elseif ($IsInteractive) {
        $OpenPrompt = Read-Host "`nOpen output folder in Windows File Explorer? (Y/n)"
        if ($OpenPrompt -eq "" -or $OpenPrompt -eq "Y" -or $OpenPrompt -eq "y") {
            Invoke-Item $OutputDir
        }
    }
} else {
    Write-Host "                         BUILD FINISHED WITH ERRORS                           " -ForegroundColor Red
    Write-Host "==============================================================================" -ForegroundColor Red
}

if ($IsInteractive) {
    Write-Host "`nPress any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

if (-not $AllSuccess) {
    exit 1
}
