// DST AI Player - 卸载脚本

const fs = require('fs');
const path = require('path');
const readline = require('readline');

// 检查 --confirm 参数（需要确认时使用）
const needConfirm = process.argv.includes('--confirm');

const modPaths = [
  path.join(process.env.USERPROFILE, 'Documents', 'Klei', 'DoNotStarveTogether', 'Mods', 'dst-ai-mod'),
  'C:\\Program Files (x86)\\Steam\\steamapps\\common\\Don\'t Starve Together\\mods\\dst-ai-mod',
  'D:\\SteamLibrary\\steamapps\\common\\Don\'t Starve Together\\mods\\dst-ai-mod',
  'E:\\SteamLibrary\\steamapps\\common\\Don\'t Starve Together\\mods\\dst-ai-mod',
];

const syncDir = path.join(process.env.USERPROFILE, 'dst-ai-sync');

// 游戏 mods 目录下的 modsettings.lua (ForceEnableMod 所在位置)
const gameModsModSettings = 'C:\\Program Files (x86)\\Steam\\steamapps\\common\\Don\'t Starve Together\\mods\\modsettings.lua';

// modindex 缓存目录
const modCacheDir = path.join(process.env.USERPROFILE, 'Documents', 'Klei', 'DoNotStarveTogether', 'client_save', 'modindex');

function question(prompt) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });
  return new Promise(resolve => {
    rl.question(prompt, (answer) => {
      rl.close();
      resolve(answer);
    });
  });
}

// 清理游戏 mods 目录下的 modsettings.lua (ForceEnableMod)
function cleanGameModsSettings() {
  if (!fs.existsSync(gameModsModSettings)) {
    return false;
  }

  console.log(`[清理] ${gameModsModSettings}`);

  let content = fs.readFileSync(gameModsModSettings, 'utf8');
  const originalContent = content;

  // 移除 ForceEnableMod("dst-ai-mod") 和 ForceEnableMod('dst-ai-mod')
  content = content.replace(/ForceEnableMod\(["']dst-ai-mod["']\)\s*/g, '');
  // 移除多余的空行
  content = content.replace(/\n\s*\n\s*\n/g, '\n\n');

  if (content !== originalContent) {
    fs.writeFileSync(gameModsModSettings, content, 'utf8');
    console.log('[完成] 已移除 ForceEnableMod("dst-ai-mod")');
    return true;
  }
  return false;
}

// 查找并清理所有存档目录下的 modoverrides.lua
function cleanModOverrides() {
  const saveBasePath = path.join(process.env.USERPROFILE, 'Documents', 'Klei', 'DoNotStarveTogether');
  let cleanedCount = 0;

  if (!fs.existsSync(saveBasePath)) {
    return 0;
  }

  // 递归查找所有 modoverrides.lua 文件
  function findAndCleanModOverrides(dir) {
    if (!fs.existsSync(dir)) return;

    const entries = fs.readdirSync(dir, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);

      if (entry.isDirectory()) {
        findAndCleanModOverrides(fullPath);
      } else if (entry.name === 'modoverrides.lua') {
        cleanSingleModOverrides(fullPath);
        cleanedCount++;
      }
    }
  }

  function cleanSingleModOverrides(filePath) {
    console.log(`[清理] ${filePath}`);

    let content = fs.readFileSync(filePath, 'utf8');

    // 移除 ["dst-ai-mod"] 相关配置
    // 匹配: ["dst-ai-mod"]={ ... },
    const cleaned = content.replace(/\s*\["dst-ai-mod"\]\s*=\s*{[^}]*},?\s*/g, '');

    if (cleaned !== content) {
      fs.writeFileSync(filePath, cleaned, 'utf8');
      console.log('[完成] 已移除 dst-ai-mod 配置');
    }
  }

  // 获取用户存档目录（通常是数字ID的文件夹）
  const entries = fs.readdirSync(saveBasePath, { withFileTypes: true });
  for (const entry of entries) {
    if (entry.isDirectory() && /^\d+$/.test(entry.name)) {
      const userSavePath = path.join(saveBasePath, entry.name);
      findAndCleanModOverrides(userSavePath);
    }
  }

  return cleanedCount;
}

// 清理 modindex 缓存，让游戏重新扫描模组
function cleanModCache() {
  let cleaned = false;

  // 删除整个 modindex 目录
  if (fs.existsSync(modCacheDir)) {
    console.log(`[删除] ${modCacheDir}`);
    fs.rmSync(modCacheDir, { recursive: true, force: true });
    cleaned = true;
  }

  // 删除游戏目录下的 modindex.lua
  const gameModIndex = 'C:\\Program Files (x86)\\Steam\\steamapps\\common\\Don\'t Starve Together\\mods\\modindex.lua';
  if (fs.existsSync(gameModIndex)) {
    console.log(`[删除] ${gameModIndex}`);
    fs.unlinkSync(gameModIndex);
    cleaned = true;
  }

  return cleaned;
}

async function main() {
  console.log('═'.repeat(50));
  console.log(' DST AI Player - 卸载脚本');
  console.log('═'.repeat(50));
  console.log();
  console.log(' 将删除以下内容:');
  console.log('   - 游戏中的 Lua Mod');
  console.log('   - 同步目录中的文件');
  console.log('   - modsettings.lua 中的 ForceEnableMod');
  console.log('   - modoverrides.lua 中的模组配置');
  console.log('   - modindex 缓存');
  console.log();

  if (needConfirm) {
    const answer = await question(' 确认卸载？(Y/N): ');
    if (answer.toUpperCase() !== 'Y') {
      console.log(' 操作已取消');
      process.exit(0);
    }
  }

  console.log('[卸载] 正在删除...');

  let deletedCount = 0;

  // 删除游戏Mod
  for (const modPath of modPaths) {
    if (fs.existsSync(modPath)) {
      console.log(`[删除] ${modPath}`);
      fs.rmSync(modPath, { recursive: true, force: true });
      deletedCount++;
    }
  }

  // 删除同步目录
  if (fs.existsSync(syncDir)) {
    console.log(`[删除] ${syncDir}`);
    fs.rmSync(syncDir, { recursive: true, force: true });
    deletedCount++;
  }

  // 清理配置文件
  console.log();
  console.log('[清理] 正在清理配置文件...');

  cleanGameModsSettings();
  const overridesCleaned = cleanModOverrides();

  // 清理 modindex 缓存
  if (cleanModCache()) {
    console.log('[完成] 已清理模组缓存');
  }

  console.log();
  if (deletedCount > 0 || overridesCleaned > 0) {
    console.log('[完成] 卸载完成');
  } else {
    console.log('[提示] 没有找到已安装的内容');
  }
  console.log();
}

main();
