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

// 检查是否已安装
if (fs.existsSync(targetMod)) {
  console.log('[提示] 检测到已安装的版本');
  // 可以选择覆盖或跳过
  fs.rmSync(targetMod, { recursive: true, force: true });
  console.log('[删除] 旧版本已移除');
}

// 创建同步目录
const syncDir = path.join(process.env.USERPROFILE, 'dst-ai-sync');
if (!fs.existsSync(syncDir)) {
  console.log(`[创建] 同步目录: ${syncDir}`);
  fs.mkdirSync(syncDir, { recursive: true });
} else {
  console.log('[提示] 同步目录已存在');
}

// 复制Mod文件
console.log();
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
console.log(' 下一步:');
console.log(' 1. 运行 npm run setup 配置 MCP 服务器');
console.log(' 2. 启动饥荒联机版');
console.log(' 3. 在设置中启用 "DST AI Player (MCP)" Mod');
console.log(' 4. 游戏内输入 ai_enable()');
console.log();
