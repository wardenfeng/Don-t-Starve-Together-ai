@echo off
REM DST AI Player - MCP服务器配置脚本
REM 自动安装依赖、构建、配置Claude Desktop

setlocal enabledelayedexpansion

echo ========================================
echo DST AI Player - MCP 服务器配置
echo ========================================
echo.

REM 检查Node.js
where node >nul 2>&1
if errorlevel 1 (
    echo [错误] 未找到 Node.js
    echo.
    echo 请先安装 Node.js: https://nodejs.org/
    echo.
    start https://nodejs.org/
    pause
    exit /b 1
)

echo [检测] Node.js 已安装
node --version
echo.

REM 进入服务器目录
cd /d "%~dp0dst-ai-mcp-server"

REM 安装依赖
if not exist "node_modules" (
    echo [安装] 正在安装 npm 依赖...
    call npm install
    if errorlevel 1 (
        echo [错误] 依赖安装失败
        pause
        exit /b 1
    )
) else (
    echo [提示] 依赖已安装
)

REM 构建
echo.
echo [构建] 正在编译 TypeScript...
call npm run build
if errorlevel 1 (
    echo [错误] 构建失败
    pause
    exit /b 1
)

REM 获取绝对路径
for %%I in ("%~dp0") do set "PROJECT_DIR=%%~fI"
set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"
set "SERVER_PATH=%PROJECT_DIR%\dst-ai-mcp-server\dist\index.js"
set "SYNC_DIR=%USERPROFILE%\dst-ai-sync"

REM 转义路径中的反斜杠
set "SERVER_PATH_ESC=%SERVER_PATH:\=\\%"

echo.
echo ========================================
echo [配置] Claude Desktop MCP 服务器
echo ========================================
echo.

REM 检测Claude Desktop配置文件位置
set "CONFIG_DIR=%APPDATA%\Claude"
set "CONFIG_FILE=%CONFIG_DIR%\claude_desktop_config.json"

if not exist "%CONFIG_DIR%" (
    echo [错误] 未找到 Claude Desktop 配置目录
    echo 请确保已安装 Claude Desktop
    pause
    exit /b 1
)

REM 备份现有配置
if exist "%CONFIG_FILE%" (
    echo [备份] 现有配置文件
    copy "%CONFIG_FILE%" "%CONFIG_FILE%.backup" >nul
    set "EXISTING_CONFIG=1"
)

REM 创建或更新配置
echo [创建] MCP 服务器配置...

if exist "%CONFIG_FILE%" (
    REM 读取现有配置并添加新服务器
    powershell -Command "$config = Get-Content '%CONFIG_FILE%' -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue; if (-not $config.mcpServers) { $config | Add-Member -Type NoteProperty -Name 'mcpServers' -Value @{} -Force }; $config.mcpServers | Add-Member -Type NoteProperty -Name 'dst-ai' -Value @{command='node'; args=@('%SERVER_PATH_ESC%'); env=@{SYNC_DIR='%SYNC_DIR%'}} -Force; $config | ConvertTo-Json -Depth 32 | Out-File '%CONFIG_FILE%' -Encoding utf8"
) else (
    REM 创建新配置文件
    (
        echo {
        echo   "mcpServers": {
        echo     "dst-ai": {
        echo       "command": "node",
        echo       "args": ["%SERVER_PATH_ESC%"],
        echo       "env": {
        echo         "SYNC_DIR": "%SYNC_DIR%"
        echo       }
        echo     }
        echo   }
        echo }
    ) > "%CONFIG_FILE%"
)

echo.
echo ========================================
echo [完成] MCP 服务器配置完成！
echo ========================================
echo.
echo 服务器路径: %SERVER_PATH%
echo 同步目录: %SYNC_DIR%
echo 配置文件: %CONFIG_FILE%
echo.
echo 下一步:
echo 1. 重启 Claude Desktop
echo 2. 启动饥荒联机版并启用 Mod
echo 3. 游戏内输入 ^`ai_enable()^`
echo 4. 在 Claude 中对话操作游戏
echo.

REM 询问是否启动游戏
set /p "LAUNCH=是否启动饥荒联机版？ (Y/N): "
if /i "%LAUNCH%"=="Y" (
    echo.
    echo [启动] 正在启动游戏...
    start "" "steam://rungameid/322330"
)

echo.
echo 按任意键退出...
pause >nul
