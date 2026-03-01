# DST Scripts 部署脚本
# 将打包好的 scripts.zip 拷贝到游戏目录

$ErrorActionPreference = "Stop"

# 读取 .env 配置文件
function Load-EnvFile {
    $envFile = ".env"
    if (Test-Path $envFile) {
        Get-Content $envFile | ForEach-Object {
            if ($_ -match '^([^=]+)=(.*)$') {
                $name = $matches[1].Trim()
                $value = $matches[2].Trim()
                # 移除引号
                $value = $value -replace '^"|"$', ''
                [Environment]::SetEnvironmentVariable($name, $value, "Process")
            }
        }
    }
}

Load-EnvFile

$ProjectDir = "C:\Users\Administrator\Desktop\Don't Starve Together ai"
$SourceZip = "$ProjectDir\dst_databundles\scripts.zip"

# 从环境变量或配置读取游戏目录
$GameDir = if ($env:DST_GAME_DIR) { $env:DST_GAME_DIR } else { "C:\Program Files (x86)\Steam\steamapps\common\Don't Starve Together" }
$DataBundlesDir = "$GameDir\data\databundles"
$GameScriptsZip = "$DataBundlesDir\scripts.zip"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DST Scripts Deploy" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Game Directory: $GameDir" -ForegroundColor Gray
Write-Host "Target: $GameScriptsZip" -ForegroundColor Gray
Write-Host ""

# 检查源文件是否存在
if (-not (Test-Path $SourceZip)) {
    Write-Host "ERROR: scripts.zip not found. Run 'npm run pack-scripts' first." -ForegroundColor Red
    exit 1
}

# 检查游戏目录是否存在
if (-not (Test-Path $DataBundlesDir)) {
    Write-Host "ERROR: Game databundles directory not found: $DataBundlesDir" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please verify your game installation or update DST_GAME_DIR in .env file." -ForegroundColor Yellow
    exit 1
}

# 备份原文件
if (Test-Path $GameScriptsZip) {
    $BackupFile = "$DataBundlesDir\backup_scripts.zip"
    Write-Host "Backing up original scripts.zip..." -ForegroundColor Yellow

    # 删除旧备份
    if (Test-Path $BackupFile) {
        Remove-Item $BackupFile -Force
    }

    Copy-Item $GameScriptsZip $BackupFile -Force
    Write-Host "Backup created: $BackupFile" -ForegroundColor Green
    Write-Host ""
}

# 拷贝新文件
Write-Host "Deploying scripts.zip to game directory..." -ForegroundColor Yellow
Copy-Item $SourceZip $GameScriptsZip -Force

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Scripts.zip deployed to: $GameScriptsZip" -ForegroundColor Green
Write-Host ""
Write-Host "To restore original scripts:" -ForegroundColor Yellow
Write-Host "  Rename backup_scripts.zip to scripts.zip"
Write-Host ""
Write-Host "Now you can:" -ForegroundColor Yellow
Write-Host "1. Start the game"
Write-Host "2. Open console (~) and type: ai_help()"
Write-Host ""
