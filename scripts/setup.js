// DST AI Player - MCP 服务器配置脚本
// 自动安装依赖、构建、配置VSCode Claude Code插件

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

// 获取路径
const serverPath = path.join(serverDir, 'dist', 'index.js');
const syncDir = path.join(process.env.USERPROFILE, 'dst-ai-sync');

// 配置 VSCode Claude Code 插件
console.log('═'.repeat(50));
console.log(' [配置] VSCode Claude Code 插件');
console.log('═'.repeat(50));
console.log();

const vscodeSettingsDir = process.env.APPDATA
  ? path.join(process.env.APPDATA, 'Code', 'User')
  : path.join(process.env.HOME, '.vscode');

const vscodeSettingsFile = path.join(vscodeSettingsDir, 'settings.json');

if (!fs.existsSync(vscodeSettingsDir)) {
  console.log('[创建] VSCode 配置目录');
  fs.mkdirSync(vscodeSettingsDir, { recursive: true });
}

// 读取现有配置
let vscodeConfig = {};
if (fs.existsSync(vscodeSettingsFile)) {
  try {
    const content = fs.readFileSync(vscodeSettingsFile, 'utf-8');
    vscodeConfig = JSON.parse(content);
  } catch {}
}

// 添加或更新 mcpServers
if (!vscodeConfig.mcpServers) {
  vscodeConfig.mcpServers = {};
}

vscodeConfig.mcpServers['dst-ai'] = {
  command: 'node',
  args: [serverPath],
  env: {
    SYNC_DIR: syncDir
  }
};

// 写入配置
fs.writeFileSync(vscodeSettingsFile, JSON.stringify(vscodeConfig, null, 2), 'utf-8');

console.log(`[完成] VSCode 配置已更新`);
console.log();
console.log(` 服务器路径: ${serverPath}`);
console.log(` 同步目录: ${syncDir}`);
console.log(` 配置文件: ${vscodeSettingsFile}`);
console.log();
console.log(' 下一步:');
console.log(' 1. 在 VSCode 中按 Ctrl+Shift+P');
console.log(' 2. 输入 "Reload Window" 并回车');
console.log(' 3. 在对话中输入 /mcp 验证配置');
console.log(' 4. 运行 npm start 启动游戏');
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
