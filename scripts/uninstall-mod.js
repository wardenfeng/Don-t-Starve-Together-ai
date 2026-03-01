// DST AI Player - 卸载脚本

const fs = require('fs');
const path = require('path');
const readline = require('readline');

// 检查 --yes 或 -y 参数
const skipConfirm = process.argv.includes('--yes') || process.argv.includes('-y');

const modPaths = [
  path.join(process.env.USERPROFILE, 'Documents', 'Klei', 'DoNotStarveTogether', 'Mods', 'dst-ai-mod'),
  'C:\\Program Files (x86)\\Steam\\steamapps\\common\\Don\'t Starve Together\\mods\\dst-ai-mod',
  'D:\\SteamLibrary\\steamapps\\common\\Don\'t Starve Together\\mods\\dst-ai-mod',
  'E:\\SteamLibrary\\steamapps\\common\\Don\'t Starve Together\\mods\\dst-ai-mod',
];

const syncDir = path.join(process.env.USERPROFILE, 'dst-ai-sync');

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

async function main() {
  console.log('═'.repeat(50));
  console.log(' DST AI Player - 卸载脚本');
  console.log('═'.repeat(50));
  console.log();
  console.log(' 警告: 此操作将删除以下内容:');
  console.log('   - 游戏中的 Lua Mod');
  console.log('   - 同步目录中的文件');
  console.log('   (MCP 配置在项目中，无需手动删除)');
  console.log();

  if (!skipConfirm) {
    const answer = await question(' 确认卸载？(Y/N): ');
    if (answer.toUpperCase() !== 'Y') {
      console.log(' 操作已取消');
      process.exit(0);
    }
  } else {
    console.log(' 跳过确认 (--yes)');
  }

  console.log();
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

  console.log();
  console.log('═'.repeat(50));
  if (deletedCount > 0) {
    console.log(' [完成] 卸载完成');
  } else {
    console.log(' [提示] 没有找到已安装的内容');
  }
  console.log('═'.repeat(50));
  console.log();
  console.log(' 如需重新安装，请运行 npm run install-mod');
  console.log();
}

main();
