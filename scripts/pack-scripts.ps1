# DST Scripts 打包脚本
# 将 dst_databundles/scripts 打包成 scripts.zip
# 使用 Node.js 版本以确保正确的路径分隔符 (/)

$ErrorActionPreference = "Stop"

$ProjectDir = "C:\Users\Administrator\Desktop\Don't Starve Together ai"
$PackScript = "$ProjectDir\scripts\pack-zip.js"

# 检查 Node.js 脚本是否存在
if (-not (Test-Path $PackScript)) {
    Write-Host "ERROR: pack-zip.js not found. Please run: npm install" -ForegroundColor Red
    exit 1
}

# 执行 Node.js 打包脚本
node $PackScript
exit $LASTEXITCODE
