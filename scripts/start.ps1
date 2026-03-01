# DST AI Player - Start/Restart script

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
$cacheDir = "C:\Users\Administrator\Documents\Klei\DoNotStarveTogether\client_save"
if (Test-Path "$cacheDir\modindex") { Remove-Item -Path "$cacheDir\modindex" -Recurse -Force }
if (Test-Path "$cacheDir\modindex.lua") { Remove-Item -Path "$cacheDir\modindex.lua" -Force }

# Start MCP server
Write-Host "  Starting MCP server..." -ForegroundColor Gray
$serverDir = Join-Path $PSScriptRoot "..\dst-ai-mcp-server"
Start-Process node -ArgumentList "dist\index.js" -WorkingDirectory $serverDir -WindowStyle Hidden
Start-Sleep -Seconds 1

# Start game
Write-Host "  Starting game..." -ForegroundColor Gray

# First ensure Steam is running
$steam = Get-Process steam -ErrorAction SilentlyContinue
if (-not $steam) {
    Start-Process "C:\Program Files (x86)\Steam\steam.exe" -ArgumentList "-silent"
    Start-Sleep -Seconds 3
}

Start-Process "steam://rungameid/322330"

Write-Host "=== Done ===" -ForegroundColor Cyan
