// DST AI Player - 开发模式
// 文件监听，代码变更自动重新构建和重启服务器

const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const rootDir = path.join(__dirname, '..');
const serverDir = path.join(rootDir, 'dst-ai-mcp-server');
const syncDir = path.join(process.env.USERPROFILE, 'dst-ai-sync');

let serverProcess = null;
let isRestarting = false;

console.log('═'.repeat(50));
console.log(' DST AI Player - 开发模式');
console.log('═'.repeat(50));
console.log();

// 检查依赖
if (!fs.existsSync(path.join(serverDir, 'node_modules'))) {
  console.log('[安装] 依赖...');
  spawnSync('npm', ['install'], { cwd: serverDir, stdio: 'inherit' });
}

// 检查同步目录
if (!fs.existsSync(syncDir)) {
  console.log(`[创建] 同步目录: ${syncDir}`);
  fs.mkdirSync(syncDir, { recursive: true });
}

// 启动服务器
function startServer() {
  if (serverProcess) {
    return;
  }

  console.log('[启动] MCP 服务器...');
  serverProcess = spawn('node', ['dist/index.js'], {
    cwd: serverDir,
    stdio: 'inherit'
  });

  serverProcess.on('exit', (code) => {
    if (!isRestarting) {
      console.log(`\n服务器已停止，退出码: ${code}`);
      process.exit(code);
    }
  });

  serverProcess.on('error', (err) => {
    console.error('[错误] 服务器启动失败:', err.message);
  });
}

// 停止服务器
function stopServer() {
  if (serverProcess) {
    serverProcess.kill();
    serverProcess = null;
  }
}

// 重启服务器
function restartServer() {
  isRestarting = true;
  stopServer();
  setTimeout(() => {
    isRestarting = false;
    startServer();
  }, 500);
}

// 构建并启动
function buildAndStart() {
  console.log('[构建] 编译 TypeScript...');

  const buildProcess = spawn('npx', ['tsc'], {
    cwd: serverDir,
    stdio: 'inherit'
  });

  buildProcess.on('close', (code) => {
    if (code === 0) {
      console.log('[完成] 构建成功');
      console.log();
      console.log('[开发] 监听文件变化...');
      console.log(' 按 Ctrl+C 停止');
      console.log();
      startServer();
      watchFiles();
    } else {
      console.error('[错误] 构建失败');
      process.exit(1);
    }
  });
}

// 监听文件变化
function watchFiles() {
  const srcDir = path.join(serverDir, 'src');
  const watcher = fs.watch(srcDir, { recursive: true }, (eventType, filename) => {
    if (!filename) return;

    // 只监听.ts文件
    if (!filename.endsWith('.ts')) return;

    console.log();
    console.log(`[变更] 检测到文件变化: ${filename}`);
    console.log('[重新构建]...');

    // 重新构建
    const buildProcess = spawn('npx', ['tsc'], {
      cwd: serverDir,
      stdio: 'inherit'
    });

    buildProcess.on('close', (code) => {
      if (code === 0) {
        console.log('[完成] 重新构建成功');
        console.log('[重启] 服务器...');
        restartServer();
      } else {
        console.error('[错误] 构建失败，服务器继续运行');
      }
    });
  });

  watcher.on('error', (err) => {
    console.error('[错误] 文件监听失败:', err.message);
  });

  // 优雅退出
  process.on('SIGINT', () => {
    console.log('\n');
    console.log('[停止] 正在关闭...');
    stopServer();
    watcher.close();
    process.exit(0);
  });
}

// 辅助函数
function spawnSync(command, args, options) {
  const { spawnSync } = require('child_process');
  return spawnSync(command, args, options);
}

// 开始
buildAndStart();
