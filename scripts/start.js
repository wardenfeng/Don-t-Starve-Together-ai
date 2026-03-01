// DST AI Player - Start script (wrapper for PowerShell)

const { execSync } = require('child_process');
const path = require('path');

const ps1File = path.join(__dirname, 'start.ps1');

execSync(`powershell -ExecutionPolicy Bypass -File "${ps1File}"`, {
  stdio: 'inherit',
  shell: true
});
