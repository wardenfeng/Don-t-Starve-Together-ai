@echo off
REM DST AI Player - 一键启动脚本
REM 同时启动MCP服务器和游戏

setlocal enabledelayedexpansion

echo ========================================
echo DST AI Player - 一键启动
echo ========================================
echo.

REM 检查同步目录
set "SYNC_DIR=%USERPROFILE%\dst-ai-sync"
if not exist "%SYNC_DIR%" (
    echo [创建] 同步目录: %SYNC_DIR%
    mkdir "%SYNC_DIR%"
)

REM 检查MCP服务器是否已构建
cd /d "%~dp0dst-ai-mcp-server"

if not exist "dist\index.js" (
    echo [提示] MCP服务器未构建，正在构建...
    call npm install
    call npm run build
    if errorlevel 1 (
        echo [错误] 构建失败
        pause
        exit /b 1
    )
)

echo [启动] MCP服务器...
start "DST AI MCP Server" cmd /k "node dist\index.js"

echo [等待] 等待服务器启动...
timeout /t 2 /nobreak >nul

echo [启动] 饥荒联机版...
start "" "steam://rungameid/322330"

echo.
echo ========================================
echo [完成]
echo ========================================
echo.
echo MCP服务器已在后台窗口运行
echo 游戏正在启动...
echo.
echo 游戏内操作:
echo 1. 启用 "DST AI Player (MCP)" Mod
echo 2. 打开控制台 (~) 输入: ai_enable()
echo 3. 在 Claude Desktop 中对话操作游戏
echo.
echo 按任意键关闭此窗口...
pause >nul
