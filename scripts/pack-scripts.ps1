# DST Scripts 打包脚本
# 将 dst_databundles/scripts 打包成 scripts.zip
# zip 内部结构: scripts/achievements.lua, scripts/behaviours/..., 等

$ErrorActionPreference = "Stop"

$ProjectDir = "C:\Users\Administrator\Desktop\Don't Starve Together ai"
$SrcDir = "$ProjectDir\dst_databundles\scripts"
$OutputZip = "$ProjectDir\dst_databundles\scripts.zip"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DST Scripts Packager" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Source: $SrcDir" -ForegroundColor Gray

# 检查源目录
if (-not (Test-Path $SrcDir)) {
    Write-Host "ERROR: Source directory not found: $SrcDir" -ForegroundColor Red
    exit 1
}

# 删除旧的 zip 文件
if (Test-Path $OutputZip) {
    Remove-Item $OutputZip -Force
}

# 压缩：使用 Compress-Archive，会自动保持目录结构
Write-Host "Packing scripts (keeping scripts/ directory structure)..." -ForegroundColor Yellow
Compress-Archive -Path $SrcDir -DestinationPath $OutputZip -Force

# 获取文件大小
$fileSize = (Get-Item $OutputZip).Length
$fileSizeMB = [math]::Round($fileSize / 1MB, 2)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Packing Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Output: $OutputZip" -ForegroundColor Green
Write-Host "Size: $fileSizeMB MB" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Deploy to game:"
Write-Host "   npm run deploy-scripts"
Write-Host ""
Write-Host "2. Or pack and deploy in one command:"
Write-Host "   npm run pack-and-deploy"
Write-Host ""
