// 通用MCP配置脚本 - 从项目配置分发到各客户端

const fs = require('fs');
const path = require('path');
const os = require('os');

const rootDir = path.join(__dirname, '..');
const mcpDir = path.join(rootDir, '.mcp');

const serverPath = path.join(rootDir, 'dst-ai-mcp-server', 'dist', 'index.js');
const syncDir = path.join(os.homedir(), 'dst-ai-sync');

console.log('═'.repeat(50));
console.log('  通用 MCP 配置 - 从项目分发到各客户端');
console.log('═'.repeat(50));
console.log();
console.log('项目目录:', rootDir);
console.log('服务器路径:', serverPath);
console.log('同步目录:', syncDir);
console.log();

// MCP配置（绝对路径版本）
const mcpConfig = {
  'dst-ai': {
    command: 'node',
    args: [serverPath],
    env: { SYNC_DIR: syncDir }
  }
};

let configured = [];

// 1. VSCode Claude Code (.vscode/settings.json)
console.log('[1/3] 配置 VSCode Claude Code...');
const vscodeSettingsFile = path.join(rootDir, '.vscode', 'settings.json');
const vscodeDir = path.dirname(vscodeSettingsFile);
if (!fs.existsSync(vscodeDir)) {
  fs.mkdirSync(vscodeDir, { recursive: true });
}

let vscodeConfig = {};
if (fs.existsSync(vscodeSettingsFile)) {
  vscodeConfig = JSON.parse(fs.readFileSync(vscodeSettingsFile, 'utf-8'));
}
vscodeConfig.mcpServers = { ...vscodeConfig.mcpServers, ...mcpConfig };
fs.writeFileSync(vscodeSettingsFile, JSON.stringify(vscodeConfig, null, 2));
console.log('  ✓ .vscode/settings.json');
configured.push('VSCode Claude Code');
console.log();

// 2. Claude Desktop (~/.config/claude/ 或 %APPDATA%/Claude/)
console.log('[2/3] 配置 Claude Desktop...');
let claudeConfigDir, claudeConfigFile;

if (process.platform === 'win32') {
  claudeConfigDir = path.join(process.env.APPDATA, 'Claude');
} else if (process.platform === 'darwin') {
  claudeConfigDir = path.join(os.homedir(), 'Library', 'Application Support', 'Claude');
} else {
  claudeConfigDir = path.join(os.homedir(), '.config', 'claude');
}

claudeConfigFile = path.join(claudeConfigDir, 'claude_desktop_config.json');
if (!fs.existsSync(claudeConfigDir)) {
  fs.mkdirSync(claudeConfigDir, { recursive: true });
}

let claudeConfig = {};
if (fs.existsSync(claudeConfigFile)) {
  claudeConfig = JSON.parse(fs.readFileSync(claudeConfigFile, 'utf-8'));
}
claudeConfig.mcpServers = { ...claudeConfig.mcpServers, ...mcpConfig };
fs.writeFileSync(claudeConfigFile, JSON.stringify(claudeConfig, null, 2));
console.log('  ✓ ' + claudeConfigFile);
configured.push('Claude Desktop');
console.log();

// 3. Claude CLI (~/.claude/claude.json 或 ~/.config/claude/claude.json)
console.log('[3/3] 配置 Claude CLI...');
let claudeCliConfigFile;

if (process.platform === 'win32') {
  claudeCliConfigFile = path.join(os.homedir(), '.claude', 'claude.json');
} else {
  claudeCliConfigFile = path.join(os.homedir(), '.config', 'claude', 'claude.json');
}

let claudeCliDir = path.dirname(claudeCliConfigFile);
if (!fs.existsSync(claudeCliDir)) {
  fs.mkdirSync(claudeCliDir, { recursive: true });
}

let claudeCliConfig = {};
if (fs.existsSync(claudeCliConfigFile)) {
  claudeCliConfig = JSON.parse(fs.readFileSync(claudeCliConfigFile, 'utf-8'));
}
claudeCliConfig.mcpServers = { ...claudeCliConfig.mcpServers, ...mcpConfig };
fs.writeFileSync(claudeCliConfigFile, JSON.stringify(claudeCliConfig, null, 2));
console.log('  ✓ ' + claudeCliConfigFile);
configured.push('Claude CLI');
console.log();

// 输出结果
console.log('═'.repeat(50));
console.log('  配置完成！');
console.log('═'.repeat(50));
console.log();
console.log('已配置的客户端:');
configured.forEach(c => console.log('  - ' + c));
console.log();
console.log('下一步:');
console.log('  - VSCode: 重新加载窗口 (Ctrl+Shift+P → Reload Window)');
console.log('  - Claude Desktop: 重启应用');
console.log('  - Claude CLI: 直接可用');
console.log();
console.log('提示: 配置源文件位于 .mcp/ 目录 (相对路径)');
console.log();
