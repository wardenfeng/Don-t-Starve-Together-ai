@echo off
REM DST AI Player - 安装脚本
REM 自动安装Lua Mod到饥荒联机版目录

setlocal enabledelayedexpansion

echo ========================================
echo DST AI Player - Mod 安装脚本
echo ========================================
echo.

REM 检测游戏安装路径
set "MOD_PATHS[0]=%USERPROFILE%\Documents\Klei\DoNotStarveTogether\Mods"
set "MOD_PATHS[1]=C:\Program Files (x86)\Steam\steamapps\common\Don't Starve Together\mods"
set "MOD_PATHS[2]=D:\SteamLibrary\steamapps\common\Don't Starve Together\mods"
set "MOD_PATHS[3]=E:\SteamLibrary\steamapps\common\Don't Starve Together\mods"

REM 查找有效路径
set "FOUND_PATH="
for /f "tokens=2 delims==" %%V in ('set MOD_PATHS[') do (
    if exist "%%V" (
        set "FOUND_PATH=%%V"
        goto :found
    )
)

:found
if "%FOUND_PATH%"=="" (
    echo [错误] 未找到饥荒联机版安装目录
    echo.
    echo 请手动指定路径，或确保游戏已安装
    echo.
    pause
    exit /b 1
)

echo [检测] 找到游戏目录: %FOUND_PATH%
echo.

REM 设置目标路径
set "TARGET_MOD=%FOUND_PATH%\dst-ai-mod"

REM 检查是否已安装
if exist "%TARGET_MOD%" (
    echo [提示] 检测到已安装的版本
    set /p "REPLACE=是否覆盖安装？ (Y/N): "
    if /i not "!REPLACE!"=="Y" (
        echo 安装已取消
        pause
        exit /b 0
    )
    rmdir /s /q "%TARGET_MOD%" 2>nul
)

REM 创建同步目录
set "SYNC_DIR=%USERPROFILE%\dst-ai-sync"
if not exist "%SYNC_DIR%" (
    echo [创建] 同步目录: %SYNC_DIR%
    mkdir "%SYNC_DIR%"
) else (
    echo [提示] 同步目录已存在
)

REM 复制Mod文件
echo.
echo [安装] 正在复制Mod文件...
xcopy /E /I /Y "%~dp0dst-ai-mod" "%TARGET_MOD%" >nul

if errorlevel 1 (
    echo [错误] 复制文件失败
    pause
    exit /b 1
)

echo.
echo ========================================
echo [完成] Mod 安装成功！
echo ========================================
echo.
echo 安装位置: %TARGET_MOD%
echo 同步目录: %SYNC_DIR%
echo.
echo 下一步:
echo 1. 启动饥荒联机版
echo 2. 在设置中启用 "DST AI Player (MSP)" Mod
echo 3. 运行 setup-mcp.bat 配置MCP服务器
echo.
pause
