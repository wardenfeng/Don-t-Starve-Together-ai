// DST AI Player - 健康检查脚本
// 诊断安装和配置问题

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const rootDir = path.join(__dirname, '..');
const syncDir = path.join(process.env.USERPROFILE || process.env.HOME, 'dst-ai-sync');

let issuesFound = 0;

function log(ok, message) {
  const icon = ok ? '✓' : '✗';
  const tag = ok ? '[OK]' : '[X]';
  console.log(`${icon} ${tag} ${message}`);
  if (!ok) issuesFound++;
}

function logInfo(message) {
  console.log(`[!] ${message}`);
}

function exec(command) {
  try {
    return execSync(command, { encoding: 'utf-8' });
  } catch {
    return null;
  }
}

console.log('═'.repeat(50));
console.log(' DST AI Player - 健康检查');
console.log('═'.repeat(50));
console.log();

// 1. 检查Node.js
console.log('[1/8] 检查 Node.js...');
const nodeVersion = exec('node --version');
if (nodeVersion) {
  log(true, `Node.js 已安装: ${nodeVersion.trim()}`);
} else {
  log(false, 'Node.js 未安装，请从 https://nodejs.org/ 安装');
}
console.log();

// 2. 检查npm
console.log('[2/8] 检查 npm...');
const npmVersion = exec('npm --version');
if (npmVersion) {
  log(true, `npm 已安装: ${npmVersion.trim()}`);
} else {
  log(false, 'npm 未安装');
}
console.log();

// 3. 检查游戏目录
console.log('[3/8] 检查游戏 Mod 目录...');
const modPaths = [
  path.join(process.env.USERPROFILE, 'Documents', 'Klei', 'DoNotStarveTogether', 'Mods'),
  'C:\\Program Files (x86)\\Steam\\steamapps\\common\\Don\'t Starve Together\\mods',
  'D:\\SteamLibrary\\steamapps\\common\\Don\'t Starve Together\\mods',
  'E:\\SteamLibrary\\steamapps\\common\\Don\'t Starve Together\\mods',
];

let gameFound = false;
for (const modPath of modPaths) {
  if (fs.existsSync(modPath)) {
    log(true, `找到游戏目录: ${modPath}`);
    gameFound = true;

    const aiModPath = path.join(modPath, 'dst-ai-mod');
    if (fs.existsSync(path.join(aiModPath, 'modinfo.lua'))) {
      log(true, 'Lua Mod 已安装');
    } else {
      logInfo('Lua Mod 未安装 (运行 npm run install)');
    }
    break;
  }
}
if (!gameFound) {
  log(false, '未找到游戏目录');
}
console.log();

// 4. 检查同步目录
console.log('[4/8] 检查同步目录...');
if (fs.existsSync(syncDir)) {
  log(true, `同步目录存在: ${syncDir}`);

  const testFile = path.join(syncDir, 'test-write.txt');
  try {
    fs.writeFileSync(testFile, 'test');
    fs.unlinkSync(testFile);
    log(true, '有写入权限');
  } catch {
    log(false, '无写入权限');
  }
} else {
  logInfo('同步目录不存在 (会自动创建)');
}
console.log();

// 5. 检查MCP服务器构建
console.log('[5/8] 检查 MCP 服务器...');
const distFile = path.join(rootDir, 'dst-ai-mcp-server', 'dist', 'index.js');
if (fs.existsSync(distFile)) {
  log(true, 'MCP 服务器已构建');
} else {
  log(false, 'MCP 服务器未构建 (运行 npm run setup)');
}
console.log();

// 6. 检查依赖
console.log('[6/8] 检查 npm 依赖...');
const mcpSdk = path.join(rootDir, 'dst-ai-mcp-server', 'node_modules', '@modelcontextprotocol', 'sdk');
if (fs.existsSync(mcpSdk)) {
  log(true, 'MCP SDK 已安装');
} else {
  log(false, 'MCP SDK 未安装 (运行 npm run setup)');
}
console.log();

// 7. 检查项目MCP配置
console.log('[7/8] 检查项目 MCP 配置...');
const projectSettings = path.join(rootDir, '.vscode', 'settings.json');
if (fs.existsSync(projectSettings)) {
  log(true, '项目 .vscode/settings.json 存在');

  const config = JSON.parse(fs.readFileSync(projectSettings, 'utf-8'));
  if (config.mcpServers && config.mcpServers['dst-ai']) {
    log(true, 'dst-ai MCP 服务器已配置 (使用相对路径)');
  } else {
    logInfo('未配置 dst-ai MCP 服务器');
  }
} else {
  log(false, '项目 .vscode/settings.json 不存在');
}
console.log();

// 8. 检查运行状态
console.log('[8/8] 检查运行状态...');
try {
  const tasks = execSync('tasklist /FI "IMAGENAME eq node.exe" /NH', { encoding: 'utf-8' });
  if (tasks.includes('node.exe')) {
    logInfo('检测到 node 进程正在运行');
  } else {
    log(true, '无冲突进程');
  }
} catch {
  log(true, '无法检查进程状态');
}
console.log();

// 总结
console.log('═'.repeat(50));
if (issuesFound === 0) {
  console.log(' [结果] 所有检查通过！');
  console.log();
  console.log(' 可以运行 npm start 启动系统');
} else {
  console.log(` [结果] 发现 ${issuesFound} 个问题，请按照上述提示修复`);
  console.log();
  console.log(' 常用修复命令:');
  console.log('   npm run install  - 安装 Lua Mod');
  console.log('   npm run setup    - 配置 MCP 服务器');
  console.log('   npm run test     - 测试服务器');
}
console.log('═'.repeat(50));
console.log();

process.exit(issuesFound > 0 ? 1 : 0);
