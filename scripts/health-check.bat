@echo off
REM DST AI Player - 健康检查脚本
REM 诊断安装和配置问题

setlocal enabledelayedexpansion

set "ISSUES_FOUND=0"

echo ========================================
echo DST AI Player - 健康检查
echo ========================================
echo.

REM 1. 检查Node.js
echo [1/8] 检查 Node.js...
where node >nul 2>&1
if errorlevel 1 (
    echo [X] Node.js 未安装
    set "ISSUES_FOUND=1"
) else (
    echo [OK] Node.js 已安装
    node --version
)
echo.

REM 2. 检查npm
echo [2/8] 检查 npm...
where npm >nul 2>&1
if errorlevel 1 (
    echo [X] npm 未安装
    set "ISSUES_FOUND=1"
) else (
    echo [OK] npm 已安装
    npm --version
)
echo.

REM 3. 检查游戏目录
echo [3/8] 检查游戏Mod目录...
set "GAME_FOUND=0"
set "MOD_PATHS[0]=%USERPROFILE%\Documents\Klei\DoNotStarveTogether\Mods"
set "MOD_PATHS[1]=C:\Program Files (x86)\Steam\steamapps\common\DonNot Starve Together\mods"
set "MOD_PATHS[2]=D:\SteamLibrary\steamapps\common\Don't Starve Together\mods"
set "MOD_PATHS[3]=E:\SteamLibrary\steamapps\common\Don't Starve Together\mods"

for /f "tokens=2 delims==" %%V in ('set MOD_PATHS[') do (
    if exist "%%V" (
        echo [OK] 找到游戏目录: %%V
        set "GAME_FOUND=1"

        REM 检查Mod是否已安装
        if exist "%%V\dst-ai-mod\modinfo.lua" (
            echo [OK] Lua Mod 已安装
        ) else (
            echo [!] Lua Mod 未安装 (运行 install.bat)
        )
        goto :game_found
    )
)
:game_found
if "%GAME_FOUND%"=="0" (
    echo [X] 未找到游戏目录
    set "ISSUES_FOUND=1"
)
echo.

REM 4. 检查同步目录
echo [4/8] 检查同步目录...
set "SYNC_DIR=%USERPROFILE%\dst-ai-sync"
if exist "%SYNC_DIR%" (
    echo [OK] 同步目录存在: %SYNC_DIR%

    REM 检查权限
    echo test > "%SYNC_DIR%\test.txt" 2>nul
    if exist "%SYNC_DIR%\test.txt" (
        del "%SYNC_DIR%\test.txt" 2>nul
        echo [OK] 有写入权限
    ) else (
        echo [X] 无写入权限
        set "ISSUES_FOUND=1"
    )
) else (
    echo [!] 同步目录不存在 (会自动创建)
)
echo.

REM 5. 检查MCP服务器构建
echo [5/8] 检查MCP服务器...
cd /d "%~dp0dst-ai-mcp-server"
if exist "dist\index.js" (
    echo [OK] MCP服务器已构建
) else (
    echo [X] MCP服务器未构建 (运行 setup-mcp.bat)
    set "ISSUES_FOUND=1"
)
echo.

REM 6. 检查依赖
echo [6/8] 检查 npm 依赖...
if exist "node_modules\@modelcontextprotocol\sdk" (
    echo [OK] MCP SDK 已安装
) else (
    echo [X] MCP SDK 未安装 (运行 setup-mcp.bat)
    set "ISSUES_FOUND=1"
)
echo.

REM 7. 检查Claude Desktop配置
echo [7/8] 检查 Claude Desktop 配置...
set "CONFIG_FILE=%APPDATA%\Claude\claude_desktop_config.json"
if exist "%CONFIG_FILE%" (
    echo [OK] Claude Desktop 配置文件存在

    findstr /C:"dst-ai" "%CONFIG_FILE%" >nul
    if errorlevel 1 (
        echo [!] 未配置 dst-ai MCP 服务器 (运行 setup-mcp.bat)
    ) else (
        echo [OK] dst-ai MCP 服务器已配置
    )
) else (
    echo [!] Claude Desktop 可能未安装
)
echo.

REM 8. 检查端口冲突（如果有）
echo [8/8] 检查运行状态...
tasklist /FI "IMAGENAME eq node.exe" 2>nul | find /I /N "node.exe">nul
if "%ERRORLEVEL%"=="0" (
    echo [!] 检测到 node 进程正在运行
) else (
    echo [OK] 无冲突进程
)
echo.

REM 总结
echo ========================================
if "%ISSUES_FOUND%"=="0" (
    echo [结果] 所有检查通过！
    echo.
    echo 可以运行 start.bat 启动系统
) else (
    echo [结果] 发现问题，请按照上述提示修复
    echo.
    echo 常用修复命令:
    echo   - install.bat      安装Lua Mod
    echo   - setup-mcp.bat    配置MCP服务器
    echo   - test-server.bat  测试服务器
)
echo ========================================
echo.
pause
