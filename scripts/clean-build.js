// 清理构建产物和临时文件

const fs = require('fs');
const path = require('path');

const rootDir = path.join(__dirname, '..');

console.log('Cleaning build artifacts...');

const dirsToClean = [
  path.join(rootDir, 'dst-ai-mcp-server', 'dist'),
  path.join(rootDir, 'dst-ai-mcp-server', 'node_modules', '.cache'),
];

const filesToClean = [
  path.join(rootDir, 'dst-ai-mcp-server', 'tsconfig.tsbuildinfo'),
];

let cleanedCount = 0;

// 清理目录
for (const dir of dirsToClean) {
  if (fs.existsSync(dir)) {
    fs.rmSync(dir, { recursive: true, force: true });
    console.log(`[OK] Removed: ${dir}`);
    cleanedCount++;
  }
}

// 清理文件
for (const file of filesToClean) {
  if (fs.existsSync(file)) {
    fs.unlinkSync(file);
    console.log(`[OK] Removed: ${file}`);
    cleanedCount++;
  }
}

console.log(`\nCleaned ${cleanedCount} item(s)`);
