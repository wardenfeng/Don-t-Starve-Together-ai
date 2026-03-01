# DST AI Player - Start script

$ErrorActionPreference = "SilentlyContinue"

# Start MCP server
Write-Host "  Starting MCP server..." -ForegroundColor Gray
$serverDir = Join-Path $PSScriptRoot "..\dst-ai-mcp-server"
Start-Process node -ArgumentList "dist\index.js" -WorkingDirectory $serverDir -WindowStyle Hidden
Start-Sleep -Seconds 1

# Start game
Write-Host "  Starting game..." -ForegroundColor Gray

# Find Steam installation
$steamPaths = @(
    "${env:ProgramFiles(x86)}\Steam\steam.exe",
    "${env:ProgramFiles}\Steam\steam.exe",
    "$env:LOCALAPPDATA\Steam\steam.exe"
)

$steamExe = $null
foreach ($path in $steamPaths) {
    if (Test-Path $path) {
        $steamExe = $path
        break
    }
}

# Ensure Steam is running
$steam = Get-Process steam -ErrorAction SilentlyContinue
if (-not $steam -and $steamExe) {
    Start-Process $steamExe -ArgumentList "-silent"
    Start-Sleep -Seconds 3
}

Start-Process "steam://rungameid/322330"

Write-Host "=== Done ===" -ForegroundColor Cyan
