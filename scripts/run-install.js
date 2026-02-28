// 运行 install.bat 的Node.js包装脚本

const { execSync } = require('child_process');
const path = require('path');

const scriptPath = path.join(__dirname, '..', 'install.bat');

console.log('Running install script...');

try {
  execSync(`"${scriptPath}"`, { stdio: 'inherit' });
} catch (error) {
  console.error('Install script failed');
  process.exit(1);
}
