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
const configFile = path.join(
  process.env.APPDATA || path.join(process.env.HOME, 'Library', 'Application Support'),
  'Claude',
  'claude_desktop_config.json'
);

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
  console.log('   - Claude Desktop MCP 配置');
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

  // 移除Claude Desktop配置
  if (fs.existsSync(configFile)) {
    console.log('[更新] Claude Desktop 配置');
    try {
      const config = JSON.parse(fs.readFileSync(configFile, 'utf-8'));
      if (config.mcpServers && config.mcpServers['dst-ai']) {
        delete config.mcpServers['dst-ai'];
        fs.writeFileSync(configFile, JSON.stringify(config, null, 2), 'utf-8');
      }
    } catch (error) {
      console.log('[提示] 无法更新 Claude Desktop 配置');
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
