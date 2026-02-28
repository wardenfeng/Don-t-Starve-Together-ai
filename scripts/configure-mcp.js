// 通用MCP配置脚本 - 配置所有Claude客户端

const fs = require('fs');
const path = require('path');
const os = require('os');

const rootDir = path.join(__dirname, '..');
const serverDir = path.join(rootDir, 'dst-ai-mcp-server');
const serverPath = path.join(serverDir, 'dist', 'index.js');
const syncDir = path.join(os.homedir(), 'dst-ai-sync');

console.log('═'.repeat(50));
console.log(' 通用 MCP 配置脚本');
console.log('═'.repeat(50));
console.log();

// 配置内容
const mcpConfig = {
  'dst-ai': {
    command: 'node',
    args: [serverPath],
    env: { SYNC_DIR: syncDir }
  }
};

let configured = [];

// 1. VSCode Claude Code (项目级配置)
console.log('[1/3] 配置 VSCode Claude Code...');
const vscodeSettingsDir = path.join(rootDir, '.vscode');
if (!fs.existsSync(vscodeSettingsDir)) {
  fs.mkdirSync(vscodeSettingsDir, { recursive: true });
}
const vscodeSettingsFile = path.join(vscodeSettingsDir, 'settings.json');

let vscodeConfig = {};
if (fs.existsSync(vscodeSettingsFile)) {
  vscodeConfig = JSON.parse(fs.readFileSync(vscodeSettingsFile, 'utf-8'));
}
vscodeConfig.mcpServers = { ...vscodeConfig.mcpServers, ...mcpConfig };
fs.writeFileSync(vscodeSettingsFile, JSON.stringify(vscodeConfig, null, 2));
console.log('  ✓ 已更新 .vscode/settings.json');
configured.push('VSCode Claude Code');
console.log();

// 2. Claude Desktop (用户级配置)
console.log('[2/3] 配置 Claude Desktop...');
let claudeConfigDir;
let claudeConfigFile;

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
console.log('  ✓ 已更新 ' + claudeConfigFile);
configured.push('Claude Desktop');
console.log();

// 3. Claude CLI
console.log('[3/3] 配置 Claude CLI...');
let claudeCliConfigFile;
if (process.platform === 'win32') {
  claudeCliConfigFile = path.join(os.homedir(), '.claude', 'claude.json');
} else {
  claudeCliConfigFile = path.join(os.homedir(), '.config', 'claude', 'claude.json');
}

let claudeDir = path.dirname(claudeCliConfigFile);
if (!fs.existsSync(claudeDir)) {
  fs.mkdirSync(claudeDir, { recursive: true });
}

let claudeCliConfig = {};
if (fs.existsSync(claudeCliConfigFile)) {
  claudeCliConfig = JSON.parse(fs.readFileSync(claudeCliConfigFile, 'utf-8'));
}
claudeCliConfig.mcpServers = { ...claudeCliConfig.mcpServers, ...mcpConfig };
fs.writeFileSync(claudeCliConfigFile, JSON.stringify(claudeCliConfig, null, 2));
console.log('  ✓ 已更新 ' + claudeCliConfigFile);
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
