@echo off
REM DST AI Player - 开发模式启动
REM 带文件监听，代码变更自动重新构建

setlocal enabledelayedexpansion

echo ========================================
echo DST AI Player - 开发模式
echo ========================================
echo.

cd /d "%~dp0dst-ai-mcp-server"

REM 检查依赖
if not exist "node_modules" (
    echo [安装] 依赖...
    call npm install
)

REM 检查tsc-watch是否安装
call npm list tsc-watch >nul 2>&1
if errorlevel 1 (
    echo [安装] 开发依赖 tsc-watch...
    call npm install --save-dev tsc-watch
)

REM 检查同步目录
set "SYNC_DIR=%USERPROFILE%\dst-ai-sync"
if not exist "%SYNC_DIR%" (
    mkdir "%SYNC_DIR%"
)

echo.
echo [开发] 监听文件变化并自动重新编译...
echo.
echo 按 Ctrl+C 停止
echo.

REM 使用tsc-watch监听文件变化
npx tsc-watch --onSuccess "node dist/index.js" --onFailure "echo Error detected"
