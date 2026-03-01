# DST Scripts 打包脚本
# 将修改后的 dst_scripts 打包成 scripts.zip

$ErrorActionPreference = "Stop"

$ProjectDir = "C:\Users\Administrator\Desktop\Don't Starve Together ai"
$SrcDir = "$ProjectDir\dst_scripts"
$OutputZip = "$ProjectDir\scripts.zip"

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

# 复制所有文件，保持目录结构
Write-Host "Copying files..." -ForegroundColor Gray
$files = Get-ChildItem -Path $SrcDir -Recurse -File
$totalFiles = $files.Count
$copiedFiles = 0

foreach ($file in $files) {
    $relativePath = $file.FullName.Substring($SrcDir.Length + 1)
    $destPath = Join-Path $TempDir $relativePath
    $destDir = Split-Path $destPath -Parent

    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir | Out-Null
    }

    Copy-Item $file.FullName -Destination $destPath -Force
    $copiedFiles++

    if ($copiedFiles % 500 -eq 0) {
        Write-Host "  Progress: $copiedFiles / $totalFiles" -ForegroundColor Gray
    }
}

Write-Host "  Copied $copiedFiles files" -ForegroundColor Gray

# 打包
Write-Host "Compressing..." -ForegroundColor Yellow
Compress-Archive -Path "$TempDir\*" -DestinationPath $OutputZip -Force

# 清理临时目录
Remove-Item $TempDir -Recurse -Force

# 获取文件大小
$fileSize = (Get-Item $OutputZip).Length
$fileSizeMB = [math]::Round($fileSize / 1MB, 2)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Packing Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Output: $OutputZip" -ForegroundColor Green
Write-Host "Size: $fileSizeMB MB ($copiedFiles files)" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Deploy to game:"
Write-Host "   npm run deploy-scripts"
Write-Host ""
Write-Host "2. Or pack and deploy in one command:"
Write-Host "   npm run pack-and-deploy"
Write-Host ""
