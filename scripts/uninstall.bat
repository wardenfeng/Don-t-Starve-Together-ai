@echo off
REM DST AI Player - 卸载脚本

setlocal enabledelayedexpansion

echo ========================================
echo DST AI Player - 卸载脚本
echo ========================================
echo.
echo 警告: 此操作将删除以下内容:
echo   - 游戏中的 Lua Mod
echo   - 同步目录中的文件
echo   - Claude Desktop MCP 配置
echo.
set /p "CONFIRM=确认卸载？ (Y/N): "

if /i not "%CONFIRM%"=="Y" (
    echo 操作已取消
    pause
    exit /b 0
)

echo.
echo [卸载] 正在删除...

REM 删除游戏Mod
set "MOD_PATHS[0]=%USERPROFILE%\Documents\Klei\DoNotStarveTogether\Mods\dst-ai-mod"
set "MOD_PATHS[1]=C:\Program Files (x86)\Steam\steamapps\common\Don't Starve Together\mods\dst-ai-mod"
set "MOD_PATHS[2]=D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\dst-ai-mod"
set "MOD_PATHS[3]=E:\SteamLibrary\steamapps\common\Don't Starve Together\mods\dst-ai-mod"

for /f "tokens=2 delims==" %%V in ('set MOD_PATHS[') do (
    if exist "%%V" (
        echo [删除] %%V
        rmdir /s /q "%%V" 2>nul
    )
)

REM 删除同步目录
set "SYNC_DIR=%USERPROFILE%\dst-ai-sync"
if exist "%SYNC_DIR%" (
    echo [删除] %SYNC_DIR%
    rmdir /s /q "%SYNC_DIR%" 2>nul
)

REM 移除Claude Desktop配置
set "CONFIG_FILE=%APPDATA%\Claude\claude_desktop_config.json"
if exist "%CONFIG_FILE%" (
    echo [更新] Claude Desktop 配置
    powershell -Command "$config = Get-Content '%CONFIG_FILE%' -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue; if ($config.mcpServers.'dst-ai') { $config.mcpServers.PSObject.Properties.Remove('dst-ai'); $config | ConvertTo-Json -Depth 32 | Out-File '%CONFIG_FILE%' -Encoding utf8 }"
)

echo.
echo ========================================
echo [完成] 卸载完成
echo ========================================
echo.
echo 如需重新安装，请运行 install.bat
echo.
pause
