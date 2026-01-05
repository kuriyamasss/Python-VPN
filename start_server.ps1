# Start SOCKS5 Server
# This script starts the SimpleVPN SOCKS5 server with Python

$ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$ServerScript = Join-Path $ScriptPath "SimpleVPN\server.py"

if (-not (Test-Path $ServerScript)) {
    Write-Host "ERROR: server.py not found at $ServerScript" -ForegroundColor Red
    Exit 1
}

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Starting SOCKS5 Server..." -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check if Python is available
$PythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $PythonCmd) {
    $PythonCmd = Get-Command python3 -ErrorAction SilentlyContinue
}

if (-not $PythonCmd) {
    Write-Host "ERROR: Python is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Python from https://www.python.org/" -ForegroundColor Yellow
    Exit 1
}

Write-Host "Python: $($PythonCmd.Source)" -ForegroundColor Green

# Run the server
& $PythonCmd.Source $ServerScript

# If server stops, show message
Write-Host ""
Write-Host "Server stopped. Press any key to exit..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
