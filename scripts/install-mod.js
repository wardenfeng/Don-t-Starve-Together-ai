// DST AI Player - 安装脚本
// 自动安装Lua Mod到饥荒联机版目录

const fs = require('fs');
const path = require('path');

const rootDir = path.join(__dirname, '..');
const sourceModDir = path.join(rootDir, 'dst-ai-mod');

// 可能的游戏Mod目录
const modPaths = [
  path.join(process.env.USERPROFILE, 'Documents', 'Klei', 'DoNotStarveTogether', 'Mods'),
  'C:\\Program Files (x86)\\Steam\\steamapps\\common\\Don\'t Starve Together\\mods',
  'D:\\SteamLibrary\\steamapps\\common\\Don\'t Starve Together\\mods',
  'E:\\SteamLibrary\\steamapps\\common\\Don\'t Starve Together\\mods',
];

function copyRecursiveSync(src, dest) {
  const exists = fs.existsSync(src);
  if (!exists) return;

  const stats = fs.statSync(src);
  const isDirectory = stats.isDirectory();

  if (isDirectory) {
    if (!fs.existsSync(dest)) {
      fs.mkdirSync(dest, { recursive: true });
    }
    fs.readdirSync(src).forEach(child => {
      copyRecursiveSync(path.join(src, child), path.join(dest, child));
    });
  } else {
    fs.copyFileSync(src, dest);
  }
}

console.log('═'.repeat(50));
console.log(' DST AI Player - Mod 安装脚本');
console.log('═'.repeat(50));
console.log();

// 查找游戏目录
let foundPath = null;
for (const modPath of modPaths) {
  if (fs.existsSync(modPath)) {
    foundPath = modPath;
    break;
  }
}

if (!foundPath) {
  console.log('[错误] 未找到饥荒联机版安装目录');
  console.log();
  console.log('请手动指定路径，或确保游戏已安装');
  console.log();
  process.exit(1);
}

console.log(`[检测] 找到游戏目录: ${foundPath}`);
console.log();

// 目标路径
const targetMod = path.join(foundPath, 'dst-ai-mod');
const syncDir = path.join(process.env.USERPROFILE, 'dst-ai-sync');

// 自动移除已安装的内容（复用 uninstall-mod 的逻辑）
console.log('[清理] 正在移除旧版本...');
let deletedCount = 0;

if (fs.existsSync(targetMod)) {
  fs.rmSync(targetMod, { recursive: true, force: true });
  deletedCount++;
}

if (fs.existsSync(syncDir)) {
  fs.rmSync(syncDir, { recursive: true, force: true });
  deletedCount++;
}

if (deletedCount > 0) {
  console.log(`[删除] 已移除 ${deletedCount} 项`);
}
console.log();

// 创建同步目录
console.log('[创建] 同步目录...');
fs.mkdirSync(syncDir, { recursive: true });

// 复制Mod文件
console.log('[安装] 正在复制Mod文件...');
copyRecursiveSync(sourceModDir, targetMod);

console.log();
console.log('═'.repeat(50));
console.log(' [完成] Mod 安装成功！');
console.log('═'.repeat(50));
console.log();
console.log(` 安装位置: ${targetMod}`);
console.log(` 同步目录: ${syncDir}`);
console.log();
