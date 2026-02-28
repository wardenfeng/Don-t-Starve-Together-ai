// DST AI Player - 服务器测试脚本
// 测试MCP服务器是否正常工作

const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const rootDir = path.join(__dirname, '..');
const serverDir = path.join(rootDir, 'dst-ai-mcp-server');
const syncDir = path.join(process.env.USERPROFILE, 'dst-ai-sync');

console.log('═'.repeat(50));
console.log(' DST AI Player - 服务器测试');
console.log('═'.repeat(50));
console.log();

// 检查构建
const distFile = path.join(serverDir, 'dist', 'index.js');
if (!fs.existsSync(distFile)) {
  console.log('[错误] 服务器未构建，请先运行 npm run setup');
  process.exit(1);
}

// 检查同步目录
if (!fs.existsSync(syncDir)) {
  console.log('[创建] 同步目录');
  fs.mkdirSync(syncDir, { recursive: true });
}

// 创建测试state.txt
console.log('[测试] 创建测试状态文件...');
const testState = {
  v: 1,
  t: Date.now(),
  p: {
    hp: 0.85,
    hu: 0.62,
    sa: 0.95,
    pos: [100.5, 0, -200.3]
  },
  w: {
    day: 5,
    time: 0.5,
    season: "summer",
    isDay: true
  },
  e: [
    { p: "berrybush", pos: [105, 0, -198], d: 5.2 }
  ],
  i: [
    { p: "axe", n: 1 }
  ]
};

fs.writeFileSync(
  path.join(syncDir, 'state.txt'),
  JSON.stringify(testState),
  'utf-8'
);

console.log(`[创建] 测试文件: ${path.join(syncDir, 'state.txt')}`);
console.log();
console.log('[启动] MCP 服务器 (测试模式)...');
console.log();
console.log('服务器将监听文件变化并响应');
console.log('按 Ctrl+C 停止测试');
console.log();

// 启动服务器
const serverProcess = spawn('node', ['dist/index.js'], {
  cwd: serverDir,
  stdio: 'inherit'
});

serverProcess.on('close', (code) => {
  console.log(`\n服务器已停止，退出码: ${code}`);
  process.exit(code);
});
