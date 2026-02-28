// 运行 setup-mcp.bat 的Node.js包装脚本

const { execSync } = require('child_process');
const path = require('path');

const scriptPath = path.join(__dirname, '..', 'setup-mcp.bat');

console.log('Running MCP setup script...');

try {
  execSync(`"${scriptPath}"`, { stdio: 'inherit' });
} catch (error) {
  console.error('Setup script failed');
  process.exit(1);
}
