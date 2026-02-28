# DST AI Player - 重启脚本 (PowerShell)

Write-Host "=== DST AI Player Restart ===" -ForegroundColor Cyan

# 查找并强制关闭所有DST和Node进程
Write-Host "Closing processes..." -ForegroundColor Yellow

$processes = @("dontstarve", "dontstarve_steam", "dontstarve_steam_x64", "node")
foreach ($proc in $processes) {
    $p = Get-Process -Name $proc -ErrorAction SilentlyContinue
    if ($p) {
        Write-Host "  Closing $proc (PID: $($p.Id))..." -ForegroundColor Gray
        $p.CloseMainWindow() | Out-Null
        Start-Sleep -Milliseconds 500
        if (!$p.HasExited) {
            $p.Kill()
            $p.WaitForExit(3000)
        }
    }
}

# 额外等待确保完全关闭
Write-Host "Waiting for processes to exit..." -ForegroundColor Gray
Start-Sleep -Seconds 3

# 验证所有进程已关闭
$stillRunning = Get-Process -Name $processes -ErrorAction SilentlyContinue
if ($stillRunning) {
    Write-Host "  Force killing remaining processes..." -ForegroundColor Red
    $stillRunning | Stop-Process -Force
    Start-Sleep -Seconds 2
}

# 启动MCP服务器
Write-Host "Starting MCP server..." -ForegroundColor Green
$serverDir = Join-Path $PSScriptRoot "..\dst-ai-mcp-server"
$nodeProc = Start-Process node -ArgumentList "dist\index.js" -WorkingDirectory $serverDir -WindowStyle Hidden -PassThru
Write-Host "  MCP Server PID: $($nodeProc.Id)" -ForegroundColor Gray

Start-Sleep -Seconds 2

# 启动游戏
Write-Host "Starting game..." -ForegroundColor Green
$gameProc = Start-Process "steam://rungameid/322330" -PassThru
Write-Host "  Game launching..." -ForegroundColor Gray

Write-Host "=== Restart Complete ===" -ForegroundColor Cyan
