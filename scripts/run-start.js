// 运行 start.bat 的Node.js包装脚本

const { execSync, spawn } = require('child_process');
const path = require('path');

const scriptPath = path.join(__dirname, '..', 'start.bat');

console.log('Starting DST AI Player...');

// 使用spawn而不是exec，这样可以在后台运行
const child = spawn('cmd', ['/c', scriptPath], {
  stdio: 'inherit',
  shell: true
});

child.on('close', (code) => {
  console.log(`Start script exited with code ${code}`);
  process.exit(code);
});
