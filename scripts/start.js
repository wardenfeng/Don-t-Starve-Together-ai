// DST AI Player - 一键启动脚本
// 关闭已运行的游戏，然后启动MCP服务器和游戏（无控制台窗口）

const fs = require('fs');
const path = require('path');
const { spawn, execSync } = require('child_process');

const rootDir = path.join(__dirname, '..');
const serverDir = path.join(rootDir, 'dst-ai-mcp-server');
const syncDir = path.join(process.env.USERPROFILE, 'dst-ai-sync');

// 检查同步目录
if (!fs.existsSync(syncDir)) {
  fs.mkdirSync(syncDir, { recursive: true });
}

// 检查MCP服务器是否已构建
const distFile = path.join(serverDir, 'dist', 'index.js');
if (!fs.existsSync(distFile)) {
  try {
    execSync('npm install', { cwd: serverDir, stdio: 'hide', shell: true });
    execSync('npm run build', { cwd: serverDir, stdio: 'hide', shell: true });
  } catch (error) {
    // 忽略错误，继续尝试启动
  }
}

// 强制关闭已运行的游戏进程
try {
  execSync('taskkill /F /IM "dontstarve_steam.exe" /T 2>nul & taskkill /F /IM "dontstarve_x64.exe" /T 2>nul', { shell: true, windowsHide: true });
} catch {
  // 忽略错误
}

// 启动MCP服务器（后台，无窗口）
const serverProcess = spawn('node', ['dist/index.js'], {
  cwd: serverDir,
  detached: true,
  stdio: 'ignore',
  shell: true,
  windowsHide: true
});
serverProcess.unref();

// 等待后启动游戏
setTimeout(() => {
  try {
    execSync('start steam://rungameid/322330', { shell: true, windowsHide: true });
  } catch {
    // 忽略错误
  }
}, 2000);
