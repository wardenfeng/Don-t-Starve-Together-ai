// DST AI Player - 自动检测重启脚本
// 循环检测进程状态，确保正确关闭和启动

const { execSync, spawn } = require('child_process');
const path = require('path');

function run(cmd) {
  try {
    execSync(cmd, { shell: true, windowsHide: true, stdio: 'ignore' });
  } catch (e) {}
}

function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

function isProcessRunning(name) {
  try {
    const result = execSync(`tasklist /FI "IMAGENAME eq ${name}"`, { encoding: 'utf8' });
    return result.includes(name);
  } catch (e) {
    return false;
  }
}

async function waitForProcessExit(name, maxWait = 10000) {
  const start = Date.now();
  while (Date.now() - start < maxWait) {
    if (!isProcessRunning(name)) return true;
    await sleep(500);
  }
  return false;
}

async function main() {
  console.log('=== DST AI Player Auto Restart ===');

  // 1. 强制关闭所有相关进程
  console.log('[1/5] Closing processes...');
  const processes = ['dontstarve.exe', 'dontstarve_steam.exe', 'dontstarve_steam_x64.exe', 'node.exe'];

  for (const proc of processes) {
    if (isProcessRunning(proc)) {
      console.log(`  - Closing ${proc}...`);
      run(`taskkill /F /IM ${proc} /T 2>nul`);
    }
  }

  // 2. 等待所有进程退出
  console.log('[2/5] Waiting for processes to exit...');
  for (const proc of processes) {
    const exited = await waitForProcessExit(proc, 8000);
    if (!exited) {
      console.log(`  ! ${proc} still running, forcing...`);
      run(`taskkill /F /IM ${proc} /T 2>nul`);
    }
  }
  await sleep(2000);

  // 3. 验证所有进程已关闭
  console.log('[3/5] Verifying all processes closed...');
  let anyRunning = false;
  for (const proc of processes) {
    if (isProcessRunning(proc)) {
      console.log(`  ✗ ${proc} still running!`);
      anyRunning = true;
    }
  }
  if (anyRunning) {
    console.log('  Some processes failed to close, retrying...');
    await sleep(3000);
  }
  console.log('  ✓ All processes closed');

  // 4. 启动MCP服务器
  console.log('[4/5] Starting MCP server...');
  const serverDir = path.join(__dirname, '..', 'dst-ai-mcp-server');
  spawn('node', ['dist/index.js'], {
    cwd: serverDir,
    detached: true,
    stdio: 'ignore',
    shell: true,
    windowsHide: true
  }).unref();
  await sleep(2000);

  // 验证MCP服务器运行
  if (!isProcessRunning('node.exe')) {
    console.log('  ! MCP server failed to start, retrying...');
    spawn('node', ['dist/index.js'], {
      cwd: serverDir,
      detached: true,
      stdio: 'ignore',
      shell: true,
      windowsHide: true
    }).unref();
    await sleep(2000);
  }
  console.log('  ✓ MCP server started');

  // 5. 启动游戏
  console.log('[5/5] Starting game...');
  run('start steam://rungameid/322330');
  console.log('  ✓ Game launching...');

  // 6. 等待游戏进程出现
  console.log('');
  console.log('Waiting for game to start...');
  let gameStarted = false;
  for (let i = 0; i < 30; i++) {
    await sleep(1000);
    if (isProcessRunning('dontstarve_steam_x64.exe') ||
        isProcessRunning('dontstarve_steam.exe') ||
        isProcessRunning('dontstarve.exe')) {
      gameStarted = true;
      console.log(`  ✓ Game process detected (${i + 1}s)`);
      break;
    }
    process.stdout.write(`  ${i + 1}s... `);
  }

  if (!gameStarted) {
    console.log('\n  ! Game process not detected after 30s');
    console.log('  Please check if Steam/DST is installed correctly');
  }

  console.log('');
  console.log('=== Restart Complete ===');
}

main().catch(console.error);
