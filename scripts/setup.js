// DST AI Player - MCP 服务器配置脚本
// 自动安装依赖、构建、配置Claude Desktop

const fs = require('fs');
const path = require('path');
const { execSync, spawn } = require('child_process');

const rootDir = path.join(__dirname, '..');
const serverDir = path.join(rootDir, 'dst-ai-mcp-server');

function exec(command, cwd = serverDir) {
  try {
    return execSync(command, { cwd, encoding: 'utf-8' });
  } catch (error) {
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

// 配置Claude Desktop
console.log('═'.repeat(50));
console.log(' [配置] Claude Desktop MCP 服务器');
console.log('═'.repeat(50));
console.log();

const configDir = process.env.APPDATA ?
  path.join(process.env.APPDATA, 'Claude') :
  path.join(process.env.HOME, 'Library', 'Application Support', 'Claude');

const configFile = path.join(configDir, 'claude_desktop_config.json');

if (!fs.existsSync(configDir)) {
  console.log('[错误] 未找到 Claude Desktop 配置目录');
  console.log('请确保已安装 Claude Desktop');
  process.exit(1);
}

// 读取现有配置
let config = {};
if (fs.existsSync(configFile)) {
  try {
    config = JSON.parse(fs.readFileSync(configFile, 'utf-8'));
    console.log('[备份] 现有配置文件已备份');
    fs.copyFileSync(configFile, configFile + '.backup');
  } catch {}
}

// 确保mcpServers对象存在
if (!config.mcpServers) {
  config.mcpServers = {};
}

// 添加dst-ai服务器
config.mcpServers['dst-ai'] = {
  command: 'node',
  args: [serverPath],
  env: {
    SYNC_DIR: syncDir
  }
};

// 写入配置
fs.writeFileSync(configFile, JSON.stringify(config, null, 2), 'utf-8');

console.log();
console.log('═'.repeat(50));
console.log(' [完成] MCP 服务器配置完成！');
console.log('═'.repeat(50));
console.log();
console.log(` 服务器路径: ${serverPath}`);
console.log(` 同步目录: ${syncDir}`);
console.log(` 配置文件: ${configFile}`);
console.log();
console.log(' 下一步:');
console.log(' 1. 重启 Claude Desktop');
console.log(' 2. 运行 npm start 启动游戏和服务器');
console.log(' 3. 游戏内启用 Mod 并输入 ai_enable()');
console.log(' 4. 在 Claude 中对话操作游戏');
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
