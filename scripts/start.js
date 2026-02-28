// DST AI Player - 一键启动脚本
// 清理Mod缓存，关闭进程，启动MCP服务器和游戏

const fs = require('fs');
const path = require('path');
const { spawn, execSync } = require('child_process');

const rootDir = path.join(__dirname, '..');
const serverDir = path.join(rootDir, 'dst-ai-mcp-server');
const syncDir = process.env.USERPROFILE + '\\dst-ai-sync';
const kleiDir = process.env.LOCALAPPDATA + '\\Klei\\DoNotStarveTogether';
const saveDir = fs.existsSync(kleiDir)
  ? path.join(kleiDir, fs.readdirSync(kleiDir).find(d => d.match(/^\d+$/)))
  : null;

// 检查同步目录
if (!fs.existsSync(syncDir)) {
  fs.mkdirSync(syncDir, { recursive: true });
}

// 检查MCP服务器是否已构建
const distFile = path.join(serverDir, 'dist', 'index.js');
if (!fs.existsSync(distFile)) {
  try {
    console.log('Building MCP server...');
    execSync('npm install', { cwd: serverDir, stdio: 'inherit', shell: true });
    execSync('npm run build', { cwd: serverDir, stdio: 'inherit', shell: true });
  } catch (e) {}
}

// 清理Mod缓存（强制游戏重新扫描）
if (saveDir) {
  const clientSaveDir = path.join(saveDir, 'client_save');
  if (fs.existsSync(clientSaveDir)) {
    try {
      fs.unlinkSync(path.join(clientSaveDir, 'modindex'));
      fs.unlinkSync(path.join(clientSaveDir, 'boot_modindex'));
    } catch (e) {}
  }
}

// 强制关闭所有相关进程
try {
  execSync('taskkill /F /IM dontstarve*.exe /T 2>nul', {
    windowsHide: true,
    stdio: 'ignore',
    shell: true
  });
} catch (e) {}
try {
  execSync('taskkill /F /IM node.exe /T 2>nul', {
    windowsHide: true,
    stdio: 'ignore',
    shell: true
  });
} catch (e) {}

// 等待进程完全关闭
function wait(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// 主启动函数
async function main() {
  await wait(2000);

  // 启动MCP服务器（后台，无窗口）
  const serverProcess = spawn('node', ['dist/index.js'], {
    cwd: serverDir,
    detached: true,
    stdio: 'ignore',
    shell: true,
    windowsHide: true
  });
  serverProcess.unref();

  // 等待服务器启动
  await wait(1500);

  // 启动游戏 - 通过Steam
  try {
    const steamCmd = 'powershell -Command "Start-Process \'C:\\Program Files (x86)\\Steam\\steam.exe\' -ArgumentList \'-applaunch 322330\'"';
    execSync(steamCmd, {
      stdio: 'ignore',
      shell: true
    });
  } catch (e) {}

  console.log('DST AI Player启动完成...');
}

main().catch(console.error);
