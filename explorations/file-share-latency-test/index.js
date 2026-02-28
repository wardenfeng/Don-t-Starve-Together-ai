#!/usr/bin/env node

/**
 * 文件共享通信延迟测试
 *
 * 测试原理：
 * 1. Writer 进程写入消息到文件
 * 2. Reader 进程轮询读取文件
 * 3. 通过时间戳计算往返延迟
 */

import { spawn } from 'child_process';
import { writeFile, readFile, unlink, mkdir } from 'fs/promises';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { existsSync } from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const DATA_DIR = join(__dirname, '.ipc-data');
const WRITER_FILE = join(DATA_DIR, 'writer.pipe');
const READER_FILE = join(DATA_DIR, 'reader.pipe');

// 使用 JSON.stringify 来转义路径中的特殊字符
const DATA_DIR_STR = JSON.stringify(DATA_DIR);
const WRITER_FILE_STR = JSON.stringify(WRITER_FILE);
const READER_FILE_STR = JSON.stringify(READER_FILE);

// 测试配置
const CONFIG = {
  messageCount: 100,      // 测试消息数量
  pollInterval: 1,        // 轮询间隔 (ms)
};

/**
 * 写入方进程代码
 */
function getWriterCode() {
  return `
import { writeFile, readFile, mkdir } from 'fs/promises';
import { existsSync } from 'fs';

const DATA_DIR = ${DATA_DIR_STR};
const WRITER_FILE = ${WRITER_FILE_STR};
const READER_FILE = ${READER_FILE_STR};

async function main() {
  if (!existsSync(DATA_DIR)) {
    await mkdir(DATA_DIR, { recursive: true });
  }

  console.log('[Writer] 启动中...');

  const messageCount = parseInt(process.argv[2]) || 100;
  const results = [];

  for (let i = 0; i < messageCount; i++) {
    const message = {
      id: i,
      timestamp: Date.now(),
      data: 'Test message #' + i + ' '.repeat(10),
    };

    // 写入消息
    await writeFile(WRITER_FILE, JSON.stringify(message) + '\\n');

    // 等待响应
    let response = null;
    let attempts = 0;
    while (!response && attempts < 1000) {
      try {
        const content = await readFile(READER_FILE, 'utf-8');
        const lines = content.trim().split('\\n').filter(Boolean);
        for (const line of lines) {
          const msg = JSON.parse(line);
          if (msg.id === i) {
            response = msg;
            break;
          }
        }
      } catch (e) {
        // 文件可能不存在或被读取中
      }
      if (!response) {
        await new Promise(r => setTimeout(r, 1));
        attempts++;
      }
    }

    const latency = response ? (response.timestamp - message.timestamp) : -1;
    results.push(latency);

    if ((i + 1) % 10 === 0) {
      console.log('[Writer] 进度: ' + (i + 1) + '/' + messageCount + ', 最近延迟: ' + latency + 'ms');
    }
  }

  // 输出结果
  const validResults = results.filter(r => r >= 0);
  const avg = validResults.reduce((a, b) => a + b, 0) / validResults.length;
  const min = Math.min(...validResults);
  const max = Math.max(...validResults);
  const sorted = [...validResults].sort((a, b) => a - b);
  const p50 = sorted[Math.floor(sorted.length * 0.5)];
  const p95 = sorted[Math.floor(sorted.length * 0.95)];
  const p99 = sorted[Math.floor(sorted.length * 0.99)];

  console.log('');
  console.log('========== Writer 结果 ==========');
  console.log('消息总数: ' + messageCount);
  console.log('成功: ' + validResults.length);
  console.log('平均延迟: ' + avg.toFixed(2) + 'ms');
  console.log('最小延迟: ' + min + 'ms');
  console.log('最大延迟: ' + max + 'ms');
  console.log('P50: ' + p50 + 'ms');
  console.log('P95: ' + p95 + 'ms');
  console.log('P99: ' + p99 + 'ms');

  process.exit(0);
}

main().catch(console.error);
`;
}

/**
 * 读取方进程代码
 */
function getReaderCode() {
  return `
import { writeFile, readFile, mkdir, stat } from 'fs/promises';
import { existsSync } from 'fs';

const DATA_DIR = ${DATA_DIR_STR};
const WRITER_FILE = ${WRITER_FILE_STR};
const READER_FILE = ${READER_FILE_STR};

async function main() {
  if (!existsSync(DATA_DIR)) {
    await mkdir(DATA_DIR, { recursive: true });
  }

  console.log('[Reader] 启动中...');

  const pollInterval = parseInt(process.argv[2]) || 1;
  let lastSize = 0;
  let buffer = '';

  while (true) {
    try {
      const stats = await stat(WRITER_FILE);

      if (stats.size > lastSize) {
        // 文件有新内容
        const content = await readFile(WRITER_FILE, 'utf-8');
        const newContent = content.slice(lastSize);
        buffer += newContent;
        lastSize = stats.size;

        // 处理完整消息
        const lines = buffer.split('\\n');
        buffer = lines.pop() || '';

        for (const line of lines) {
          if (!line.trim()) continue;
          try {
            const message = JSON.parse(line);
            const response = {
              id: message.id,
              timestamp: Date.now(),
              processed: true,
            };

            // 写入响应
            await writeFile(READER_FILE, JSON.stringify(response) + '\\n');
          } catch (e) {
            console.error('[Reader] 解析消息失败: ' + e.message);
          }
        }

        // 重置 writer 文件
        await writeFile(WRITER_FILE, '');
        lastSize = 0;
      }
    } catch (e) {
      // 文件可能不存在
    }

    await new Promise(r => setTimeout(r, pollInterval));
  }
}

main().catch(console.error);
`;
}

/**
 * 启动子进程
 */
function runCode(code, args = []) {
  return spawn('node', ['--input-type=module', '-e', code, ...args], {
    stdio: ['ignore', 'pipe', 'pipe'],
  });
}

/**
 * 主测试函数
 */
async function runTest() {
  console.log('========================================');
  console.log('   文件共享通信延迟测试');
  console.log('========================================\n');

  // 确保数据目录存在
  if (!existsSync(DATA_DIR)) {
    await mkdir(DATA_DIR, { recursive: true });
  }

  // 清理旧数据
  try {
    await unlink(WRITER_FILE);
    await unlink(READER_FILE);
  } catch (e) {
    // 文件不存在，忽略
  }

  console.log('配置:');
  console.log('  - 测试消息数: ' + CONFIG.messageCount);
  console.log('  - 轮询间隔: ' + CONFIG.pollInterval + 'ms');
  console.log();

  // 启动 Reader
  console.log('启动 Reader 进程...');
  const reader = runCode(getReaderCode(), [CONFIG.pollInterval.toString()]);

  reader.stderr.on('data', (data) => {
    process.stderr.write('[Reader stderr] ' + data);
  });

  reader.stdout.on('data', (data) => {
    process.stdout.write(data);
  });

  // 等待 Reader 启动
  await new Promise(r => setTimeout(r, 500));

  // 启动 Writer
  console.log('启动 Writer 进程...\n');
  const writer = runCode(getWriterCode(), [CONFIG.messageCount.toString()]);

  writer.stdout.on('data', (data) => {
    process.stdout.write(data);
  });

  writer.stderr.on('data', (data) => {
    process.stderr.write('[Writer stderr] ' + data);
  });

  // 等待 Writer 完成
  await new Promise((resolve) => {
    writer.on('exit', resolve);
  });

  // 关闭 Reader
  reader.kill();

  console.log('\n测试完成!');
}

// 运行测试
runTest().catch(console.error);
