// 运行 test-server.bat 的Node.js包装脚本

const { spawn } = require('child_process');
const path = require('path');

const scriptPath = path.join(__dirname, '..', 'scripts', 'test-server.bat');

console.log('Running MCP server test...');

const child = spawn('cmd', ['/c', scriptPath], {
  stdio: 'inherit',
  shell: true
});

child.on('close', (code) => {
  process.exit(code);
});
