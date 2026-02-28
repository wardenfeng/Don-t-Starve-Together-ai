// DST AI Player - 卸载脚本

const fs = require('fs');
const path = require('path');
const readline = require('readline');

const modPaths = [
  path.join(process.env.USERPROFILE, 'Documents', 'Klei', 'DoNotStarveTogether', 'Mods', 'dst-ai-mod'),
  'C:\\Program Files (x86)\\Steam\\steamapps\\common\\Don\'t Starve Together\\mods\\dst-ai-mod',
  'D:\\SteamLibrary\\steamapps\\common\\Don\'t Starve Together\\mods\\dst-ai-mod',
  'E:\\SteamLibrary\\steamapps\\common\\Don\'t Starve Together\\mods\\dst-ai-mod',
];

const syncDir = path.join(process.env.USERPROFILE, 'dst-ai-sync');

const vscodeSettingsFile = process.env.APPDATA
  ? path.join(process.env.APPDATA, 'Code', 'User', 'settings.json')
  : path.join(process.env.HOME, '.vscode', 'settings.json');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function question(prompt) {
  return new Promise(resolve => {
    rl.question(prompt, resolve);
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
  console.log('   - VSCode Claude Code 插件 MCP 配置');
  console.log();

  const answer = await question(' 确认卸载？(Y/N): ');

  if (answer.toUpperCase() !== 'Y') {
    console.log(' 操作已取消');
    rl.close();
    process.exit(0);
  }

  console.log();
  console.log('[卸载] 正在删除...');

  // 删除游戏Mod
  for (const modPath of modPaths) {
    if (fs.existsSync(modPath)) {
      console.log(`[删除] ${modPath}`);
      fs.rmSync(modPath, { recursive: true, force: true });
    }
  }

  // 删除同步目录
  if (fs.existsSync(syncDir)) {
    console.log(`[删除] ${syncDir}`);
    fs.rmSync(syncDir, { recursive: true, force: true });
  }

  // 移除VSCode MCP配置
  if (fs.existsSync(vscodeSettingsFile)) {
    console.log('[更新] VSCode MCP 配置');
    try {
      const config = JSON.parse(fs.readFileSync(vscodeSettingsFile, 'utf-8'));
      if (config.mcpServers && config.mcpServers['dst-ai']) {
        delete config.mcpServers['dst-ai'];
        fs.writeFileSync(vscodeSettingsFile, JSON.stringify(config, null, 2), 'utf-8');
      }
    } catch (error) {
      console.log('[提示] 无法更新 VSCode 配置');
    }
  }

  console.log();
  console.log('═'.repeat(50));
  console.log(' [完成] 卸载完成');
  console.log('═'.repeat(50));
  console.log();
  console.log(' 如需重新安装，请运行 npm run install');
  console.log();

  rl.close();
}

main();
