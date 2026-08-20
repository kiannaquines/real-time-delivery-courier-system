# ==============================================================================
# M&S Delivery Express Kabacan - One-Click Automated Windows Installer (PowerShell)
# ==============================================================================

[CmdletBinding()]
param()

$ProjectRoot = $PSScriptRoot
Set-Location -Path $ProjectRoot

# Check for Python
$PythonCmd = Get-Command "python" -ErrorAction SilentlyContinue
if (-not $PythonCmd) {
    $PythonCmd = Get-Command "python3" -ErrorAction SilentlyContinue
}

if (-not $PythonCmd) {
    Write-Host "[ERROR] Python 3 was not found in PATH." -ForegroundColor Red
    Write-Host "Please install Python 3.10+ from https://www.python.org/ or via 'winget install Python.Python.3.11'." -ForegroundColor Yellow
    exit 1
}

# Run the installer
& $PythonCmd.Source "$ProjectRoot\install.py" $args
