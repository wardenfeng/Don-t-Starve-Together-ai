// DST AI Player - 安装脚本
// 自动安装Lua Mod到饥荒联机版目录

const fs = require('fs');
const path = require('path');

const rootDir = path.join(__dirname, '..');
const sourceModDir = path.join(rootDir, 'dst-ai-mod');

// 游戏安装目录优先（用于 ForceEnableMod 开发模式）
const modPaths = [
  'C:\\Program Files (x86)\\Steam\\steamapps\\common\\Don\'t Starve Together\\mods',
  'D:\\SteamLibrary\\steamapps\\common\\Don\'t Starve Together\\mods',
  'E:\\SteamLibrary\\steamapps\\common\\Don\'t Starve Together\\mods',
  path.join(process.env.USERPROFILE, 'Documents', 'Klei', 'DoNotStarveTogether', 'Mods'),
];

// modsettings.lua 路径（用于添加 ForceEnableMod）
const gameModSettingsPath = 'C:\\Program Files (x86)\\Steam\\steamapps\\common\\Don\'t Starve Together\\mods\\modsettings.lua';

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

// 在 modsettings.lua 中添加 ForceEnableMod
function addForceEnableMod() {
  if (!fs.existsSync(gameModSettingsPath)) {
    console.log('[跳过] modsettings.lua 不存在，跳过 ForceEnableMod 配置');
    return false;
  }

  let content = fs.readFileSync(gameModSettingsPath, 'utf8');

  // 检查是否已经存在 ForceEnableMod("dst-ai-mod")
  if (content.includes('ForceEnableMod("dst-ai-mod")') || content.includes("ForceEnableMod('dst-ai-mod')")) {
    console.log('[跳过] ForceEnableMod 已存在');
    return false;
  }

  // 在注释区域后添加 ForceEnableMod
  // 查找 "--ForceEnableMod" 或 "-- ForceEnableMod" 的位置
  const lines = content.split('\n');
  let insertIndex = -1;

  for (let i = 0; i < lines.length; i++) {
    // 找到第一个 ForceEnableMod 示例行的前面
    if (lines[i].includes('--ForceEnableMod') && !lines[i].includes('dst-ai-mod')) {
      insertIndex = i;
      break;
    }
  }

  if (insertIndex >= 0) {
    // 在示例行前插入
    lines.splice(insertIndex, 0, 'ForceEnableMod("dst-ai-mod")');
    content = lines.join('\n');
  } else {
    // 找不到示例行，直接添加到文件末尾
    content += '\nForceEnableMod("dst-ai-mod")\n';
  }

  fs.writeFileSync(gameModSettingsPath, content, 'utf8');
  console.log('[完成] 已添加 ForceEnableMod("dst-ai-mod")');
  return true;
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

// 创建同步目录
const syncDir = path.join(process.env.USERPROFILE, 'dst-ai-sync');
console.log('[创建] 同步目录...');
fs.mkdirSync(syncDir, { recursive: true });

// 复制Mod文件
console.log('[安装] 正在复制Mod文件...');
copyRecursiveSync(sourceModDir, targetMod);

// 添加 ForceEnableMod
console.log();
console.log('[配置] 正在配置自动加载...');
addForceEnableMod();

console.log();
console.log('═'.repeat(50));
console.log(' [完成] Mod 安装成功！');
console.log('═'.repeat(50));
console.log();
console.log(` 安装位置: ${targetMod}`);
console.log(` 同步目录: ${syncDir}`);
console.log();
