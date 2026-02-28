@echo off
REM DST AI Player - 服务器测试脚本
REM 测试MCP服务器是否正常工作

setlocal enabledelayedexpansion

echo ========================================
echo DST AI Player - 服务器测试
echo ========================================
echo.

cd /d "%~dp0dst-ai-mcp-server"

REM 检查构建
if not exist "dist\index.js" (
    echo [错误] 服务器未构建，请先运行 setup-mcp.bat
    pause
    exit /b 1
)

REM 检查同步目录
set "SYNC_DIR=%USERPROFILE%\dst-ai-sync"
if not exist "%SYNC_DIR%" (
    echo [创建] 同步目录
    mkdir "%SYNC_DIR%"
)

echo [测试] 创建测试状态文件...

REM 创建测试state.txt
(
    echo {
    echo   "v": 1,
    echo   "t": 1234567890,
    echo   "p": {
    echo     "hp": 0.85,
    echo     "hu": 0.62,
    echo     "sa": 0.95,
    echo     "pos": [100.5, 0, -200.3]
    echo   },
    echo   "w": {
    echo     "day": 5,
    echo     "time": 0.5,
    echo     "season": "summer",
    echo     "isDay": true
    echo   },
    echo   "e": [
    echo     {"p": "berrybush", "pos": [105, 0, -198], "d": 5.2}
    echo   ],
    echo   "i": [
    echo     {"p": "axe", "n": 1}
    echo   ]
    echo }
) > "%SYNC_DIR%\state.txt"

echo [创建] 测试状态文件: %SYNC_DIR%\state.txt

echo.
echo [启动] MCP服务器 (测试模式)...
echo.
echo 服务器将监听文件变化并响应
echo 按 Ctrl+C 停止测试
echo.

REM 启动服务器
node dist\index.js
