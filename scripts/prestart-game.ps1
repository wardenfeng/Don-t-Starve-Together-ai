# DST AI Player - Pre-start script (stop & clean)

$ErrorActionPreference = "SilentlyContinue"

Write-Host "=== DST AI Player ===" -ForegroundColor Cyan

# Check if running
$gameRunning = Get-Process dontstarve* -ErrorAction SilentlyContinue
$serverRunning = Get-Process node -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "*dst-ai-mcp-server*" }

if ($gameRunning -or $serverRunning) {
    Write-Host "Restarting..." -ForegroundColor Yellow
} else {
    Write-Host "Starting..." -ForegroundColor Green
}

# Kill processes
Write-Host "  Stopping..." -ForegroundColor Gray
Get-Process dontstarve* -ErrorAction SilentlyContinue | Stop-Process -Force
Get-Process node -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "*dst-ai-mcp-server*" } | Stop-Process -Force
Start-Sleep -Seconds 2

# Clear mod cache
Write-Host "  Clearing cache..." -ForegroundColor Gray
$cacheDir = Join-Path $env:USERPROFILE "Documents\Klei\DoNotStarveTogether\client_save"
if (Test-Path "$cacheDir\modindex") { Remove-Item -Path "$cacheDir\modindex" -Recurse -Force }
if (Test-Path "$cacheDir\modindex.lua") { Remove-Item -Path "$cacheDir\modindex.lua" -Force }
