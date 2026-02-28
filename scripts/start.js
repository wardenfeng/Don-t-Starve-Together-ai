// DST AI Player - 一键启动脚本
// 同时启动MCP服务器和游戏

const fs = require('fs');
const path = require('path');
const { spawn, execSync } = require('child_process');

const rootDir = path.join(__dirname, '..');
const serverDir = path.join(rootDir, 'dst-ai-mcp-server');
const syncDir = path.join(process.env.USERPROFILE, 'dst-ai-sync');

console.log('═'.repeat(50));
console.log(' DST AI Player - 一键启动');
console.log('═'.repeat(50));
console.log();

// 检查同步目录
if (!fs.existsSync(syncDir)) {
  console.log(`[创建] 同步目录: ${syncDir}`);
  fs.mkdirSync(syncDir, { recursive: true });
}

// 检查MCP服务器是否已构建
const distFile = path.join(serverDir, 'dist', 'index.js');
if (!fs.existsSync(distFile)) {
  console.log('[提示] MCP 服务器未构建，正在构建...');
  try {
    execSync('npm install', { cwd: serverDir, stdio: 'inherit' });
    execSync('npm run build', { cwd: serverDir, stdio: 'inherit' });
  } catch (error) {
    console.log('[错误] 构建失败');
    process.exit(1);
  }
}

// 启动MCP服务器（后台）
console.log('[启动] MCP 服务器...');
const serverProcess = spawn('node', ['dist/index.js'], {
  cwd: serverDir,
  detached: true,
  stdio: 'ignore',
  shell: true
});
serverProcess.unref();

console.log('[等待] 等待服务器启动...');
setTimeout(() => {
  console.log('[启动] 饥荒联机版...');

  try {
    execSync('start steam://rungameid/322330', { shell: true });
  } catch {
    console.log('[提示] 无法启动Steam，请手动启动游戏');
  }

  console.log();
  console.log('═'.repeat(50));
  console.log(' [完成]');
  console.log('═'.repeat(50));
  console.log();
  console.log(' MCP 服务器已在后台运行');
  console.log(' 游戏正在启动...');
  console.log();
  console.log(' 游戏内操作:');
  console.log(' 1. 启用 "DST AI Player (MCP)" Mod');
  console.log(' 2. 打开控制台 (~) 输入: ai_enable()');
  console.log(' 3. 在 Claude Desktop 中对话操作游戏');
  console.log();
  console.log('按任意键退出...');
}, 2000);
