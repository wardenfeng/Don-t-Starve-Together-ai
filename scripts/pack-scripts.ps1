# DST Scripts 打包脚本
# 将修改后的 dst_scripts 打包成 scripts.zip

$ErrorActionPreference = "Stop"

$ProjectDir = "C:\Users\Administrator\Desktop\Don't Starve Together ai"
$SrcDir = "$ProjectDir\dst_scripts"
$OutputZip = "$ProjectDir\scripts.zip"
$GameScriptsZip = "C:\Program Files (x86)\Steam\steamapps\common\Don't Starve Together\scripts\scripts.zip"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DST Scripts Packager" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查源目录
if (-not (Test-Path $SrcDir)) {
    Write-Host "ERROR: Source directory not found: $SrcDir" -ForegroundColor Red
    exit 1
}

# 删除旧的 zip 文件
if (Test-Path $OutputZip) {
    Remove-Item $OutputZip -Force
    Write-Host "Removed old scripts.zip" -ForegroundColor Yellow
}

# 使用 Compress-Archive 打包 (PowerShell 5.0+)
Write-Host "Packing scripts..." -ForegroundColor Yellow

# 创建临时目录结构
$TempDir = "$ProjectDir\temp_scripts"
if (Test-Path $TempDir) {
    Remove-Item $TempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $TempDir | Out-Null

# 复制所有 .lua 文件，保持目录结构
Write-Host "Copying Lua files..." -ForegroundColor Gray
Get-ChildItem -Path $SrcDir -Filter "*.lua" -Recurse | ForEach-Object {
    $relativePath = $_.FullName.Substring($SrcDir.Length + 1)
    $destPath = Join-Path $TempDir $relativePath
    $destDir = Split-Path $destPath -Parent

    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir | Out-Null
    }

    Copy-Item $_.FullName -Destination $destPath -Force
}

# 打包
Compress-Archive -Path "$TempDir\*" -DestinationPath $OutputZip -Force

# 清理临时目录
Remove-Item $TempDir -Recurse -Force

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Packing Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Output: $OutputZip"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Backup the original scripts.zip:"
Write-Host "   Copy-Item `"$GameScriptsZip`" `"$GameScriptsZip.bak`""
Write-Host ""
Write-Host "2. Replace game scripts.zip:"
Write-Host "   Copy-Item `"$OutputZip`" `"$GameScriptsZip`" -Force"
Write-Host ""
Write-Host "3. Start the game and use console commands:"
Write-Host "   ai_help()     - Show all commands"
Write-Host "   ai_enable()   - Enable AI control"
Write-Host "   ai_status()   - Show AI status"
Write-Host ""
