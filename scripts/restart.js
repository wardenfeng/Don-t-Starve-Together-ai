// DST AI Player - 重启脚本

const { execSync } = require('child_process');
const path = require('path');

function run(cmd) {
  try {
    execSync(cmd, { shell: true, windowsHide: true, stdio: 'pipe' });
  } catch (e) {
    // 忽略错误
  }
}

function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

async function main() {
  console.log('=== DST AI Restart ===');

  // 1. 强制关闭游戏进程
  console.log('[1/4] Closing game...');
  run('taskkill /F /IM dontstarve*.exe /T 2>nul');
  await sleep(2000);

  // 2. 关闭MCP服务器
  console.log('[2/4] Closing MCP server...');
  run('taskkill /F /IM node.exe /T 2>nul');
  await sleep(1500);

  // 3. 清除Mod缓存
  console.log('[3/4] Clearing mod cache...');
  const saveDir = 'C:\\Users\\Administrator\\Documents\\Klei\\DoNotStarveTogether\\client_save';
  run(`rd /s /q "${saveDir}\\modindex" 2>nul`);
  run(`del /q "${saveDir}\\modindex.lua" 2>nul`);
  await sleep(500);

  // 4. 启动MCP服务器
  console.log('[4/4] Starting services...');
  const serverDir = path.join(__dirname, '..', 'dst-ai-mcp-server');

  // 先构建
  console.log('  - Building MCP server...');
  run(`cd "${serverDir}" && npm run build 2>nul`);

  // 启动MCP服务器（后台）
  console.log('  - Starting MCP server...');
  execSync(`start cmd /min "DST AI MCP" node "${serverDir}\\dist\\index.js"`, {
    shell: true,
    windowsHide: true,
    stdio: 'ignore'
  });

  await sleep(2000);

  // 启动游戏
  console.log('  - Starting game...');
  const gameExe = "C:\\\\Program Files (x86)\\\\Steam\\\\steamapps\\\\common\\\\Don't Starve Together\\\\bin64\\\\dontstarve_steam_x64.exe";
  execSync(`start "" "${gameExe}"`, {
    shell: true,
    stdio: 'ignore'
  });

  console.log('\n=== Restart Complete ===');
  console.log('Game should be loading with Mod v1.2.0');
  console.log('Use console command: _DST_AI_SetCommand(...) to execute actions');
}

main().catch(err => console.error('Error:', err.message));
