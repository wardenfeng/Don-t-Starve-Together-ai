// DST Scripts 部署脚本 (Node.js 版本)
// 将打包好的 scripts.zip 拷贝到游戏目录

const fs = require('fs');
const path = require('path');

const projectDir = 'C:\\Users\\Administrator\\Desktop\\Don\'t Starve Together ai';
const sourceZip = path.join(projectDir, 'dst_databundles', 'scripts.zip');

// 读取 .env 配置文件
function loadEnvFile() {
    const envFile = path.join(projectDir, '.env');
    if (fs.existsSync(envFile)) {
        const content = fs.readFileSync(envFile, 'utf-8');
        content.split('\n').forEach(line => {
            const match = line.match(/^([^=]+)=(.*)$/);
            if (match) {
                const name = match[1].trim();
                let value = match[2].trim();
                value = value.replace(/^"|"$/g, '');
                process.env[name] = value;
            }
        });
    }
}

loadEnvFile();

const gameDir = process.env.DST_GAME_DIR || 'C:\\Program Files (x86)\\Steam\\steamapps\\common\\Don\'t Starve Together';
const dataBundlesDir = path.join(gameDir, 'data', 'databundles');
const gameScriptsZip = path.join(dataBundlesDir, 'scripts.zip');
const backupZip = path.join(dataBundlesDir, 'backup_scripts.zip');

console.log('========================================');
console.log('  DST Scripts Deploy');
console.log('========================================');
console.log('');
console.log(`Game Directory: ${gameDir}`);
console.log(`Target: ${gameScriptsZip}`);
console.log('');

// 检查源文件
if (!fs.existsSync(sourceZip)) {
    console.error('ERROR: scripts.zip not found. Run "npm run pack-scripts" first.');
    process.exit(1);
}

// 检查游戏目录
if (!fs.existsSync(dataBundlesDir)) {
    console.error(`ERROR: Game databundles directory not found: ${dataBundlesDir}`);
    console.log('');
    console.log('Please verify your game installation or update DST_GAME_DIR in .env file.');
    process.exit(1);
}

// 备份原文件
if (fs.existsSync(gameScriptsZip)) {
    console.log('Backing up original scripts.zip...');
    if (fs.existsSync(backupZip)) {
        fs.unlinkSync(backupZip);
    }
    fs.copyFileSync(gameScriptsZip, backupZip);
    console.log(`Backup created: ${backupZip}`);
    console.log('');
}

// 拷贝新文件
console.log('Deploying scripts.zip to game directory...');
fs.copyFileSync(sourceZip, gameScriptsZip);

const stats = fs.statSync(gameScriptsZip);
const sizeMB = (stats.size / 1024 / 1024).toFixed(2);

console.log('');
console.log('========================================');
console.log('  Deployment Complete!');
console.log('========================================');
console.log('');
console.log(`Scripts.zip deployed to: ${gameScriptsZip}`);
console.log(`Size: ${sizeMB} MB`);
console.log('');
console.log('To restore original scripts:');
console.log('  Rename backup_scripts.zip to scripts.zip');
console.log('');
console.log('Now you can:');
console.log('1. Start the game');
console.log('2. Open console (~) and type: ai_help()');
console.log('');
