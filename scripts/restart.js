// DST AI Player - 重启脚本

const { execSync, spawn } = require('child_process');
const path = require('path');

function run(cmd) {
  try {
    execSync(cmd, { shell: true, windowsHide: true, stdio: 'ignore' });
  } catch (e) {}
}

function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

async function main() {
  console.log('Closing processes...');

  // 强制关闭所有相关进程
  run('taskkill /F /IM dontstarve.exe /T 2>nul');
  run('taskkill /F /IM dontstarve_steam.exe /T 2>nul');
  run('taskkill /F /IM dontstarve_steam_x64.exe /T 2>nul');
  run('taskkill /F /IM node.exe /T 2>nul');

  // 等待进程关闭
  await sleep(3000);

  // 启动MCP服务器
  console.log('Starting MCP server...');
  const serverDir = path.join(__dirname, '..', 'dst-ai-mcp-server');

  spawn('node', ['dist/index.js'], {
    cwd: serverDir,
    detached: true,
    stdio: 'ignore',
    shell: true,
    windowsHide: true
  }).unref();

  await sleep(2000);

  // 启动游戏
  console.log('Starting game...');
  run('start steam://rungameid/322330');

  console.log('Restart complete!');
}

main().catch(console.error);
