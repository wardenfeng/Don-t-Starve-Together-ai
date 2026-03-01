# DST Scripts 部署脚本
# 将打包好的 scripts.zip 拷贝到游戏目录

$ErrorActionPreference = "Stop"

$ProjectDir = "C:\Users\Administrator\Desktop\Don't Starve Together ai"
$SourceZip = "$ProjectDir\scripts.zip"
$GameScriptsDir = "C:\Program Files (x86)\Steam\steamapps\common\Don't Starve Together\scripts"
$GameScriptsZip = "$GameScriptsDir\scripts.zip"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DST Scripts Deploy" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查源文件是否存在
if (-not (Test-Path $SourceZip)) {
    Write-Host "ERROR: scripts.zip not found. Run 'npm run pack-scripts' first." -ForegroundColor Red
    exit 1
}

# 检查游戏目录是否存在
if (-not (Test-Path $GameScriptsDir)) {
    Write-Host "ERROR: Game scripts directory not found: $GameScriptsDir" -ForegroundColor Red
    exit 1
}

# 备份原文件
if (Test-Path $GameScriptsZip) {
    $BackupFile = "$GameScriptsZip.bak"
    Write-Host "Backing up original scripts.zip..." -ForegroundColor Yellow
    Copy-Item $GameScriptsZip $BackupFile -Force
    Write-Host "Backup created: $BackupFile" -ForegroundColor Green
}

# 拷贝新文件
Write-Host "Deploying scripts.zip to game directory..." -ForegroundColor Yellow
Copy-Item $SourceZip $GameScriptsZip -Force

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Scripts.zip deployed to: $GameScriptsZip"
Write-Host ""
Write-Host "Now you can:" -ForegroundColor Yellow
Write-Host "1. Start the game"
Write-Host "2. Open console and type: ai_help()"
Write-Host ""
