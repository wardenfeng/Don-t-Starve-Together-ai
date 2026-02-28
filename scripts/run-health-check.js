// 运行 health-check.bat 的Node.js包装脚本

const { execSync } = require('child_process');
const path = require('path');

const scriptPath = path.join(__dirname, 'health-check.bat');

console.log('Running health check...');

try {
  execSync(`"${scriptPath}"`, { stdio: 'inherit' });
} catch (error) {
  process.exit(1);
}
