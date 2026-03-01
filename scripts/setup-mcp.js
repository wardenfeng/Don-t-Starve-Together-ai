// DST AI Player - MCP 服务器配置脚本
// 自动安装依赖、构建

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const rootDir = path.join(__dirname, '..');
const serverDir = path.join(rootDir, 'dst-ai-mcp-server');

function exec(command, cwd = serverDir) {
  try {
    return execSync(command, { cwd, encoding: 'utf-8' });
  } catch {
    return null;
  }
}

console.log('═'.repeat(50));
console.log(' DST AI Player - MCP 服务器配置');
console.log('═'.repeat(50));
console.log();

// 检查Node.js
const nodeVersion = exec('node --version', rootDir);
if (!nodeVersion) {
  console.log('[错误] 未找到 Node.js');
  console.log('请先安装 Node.js: https://nodejs.org/');
  process.exit(1);
}

console.log('[检测] Node.js 已安装');
console.log(nodeVersion.trim());
console.log();

// 安装依赖
if (!fs.existsSync(path.join(serverDir, 'node_modules'))) {
  console.log('[安装] 正在安装 npm 依赖...');
  const result = exec('npm install');
  if (!result) {
    console.log('[错误] 依赖安装失败');
    process.exit(1);
  }
  console.log('[完成] 依赖安装成功');
} else {
  console.log('[提示] 依赖已安装');
}

// 构建
console.log();
console.log('[构建] 正在编译 TypeScript...');
const buildResult = exec('npm run build');
if (!buildResult) {
  console.log('[错误] 构建失败');
  process.exit(1);
}
console.log('[完成] 构建成功');
console.log();

console.log('[提示] MCP 配置位置: ~/.claude.json');
console.log('        如需更新配置，请手动编辑该文件');

console.log();
console.log('═'.repeat(50));
console.log(' [完成] 配置完成！');
console.log('═'.repeat(50));
console.log();
console.log(' 下一步:');
console.log(' 1. 在 VSCode 中重新加载窗口 (Ctrl+Shift+P → Reload Window)');
console.log(' 2. 在对话中输入 /mcp 验证配置');
console.log(' 3. 运行 npm start 启动游戏');
console.log();

// 询问是否启动游戏
const readline = require('readline');
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

rl.question('是否启动饥荒联机版？(Y/N): ', (answer) => {
  rl.close();
  if (answer.toUpperCase() === 'Y') {
    console.log();
    console.log('[启动] 正在启动游戏...');
    execSync('start steam://rungameid/322330', { cwd: rootDir, shell: true });
  }
});
