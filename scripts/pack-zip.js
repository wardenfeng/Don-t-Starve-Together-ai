// DST Scripts 打包脚本 (Node.js 版本)
// 正确使用 / 作为路径分隔符

const fs = require('fs');
const path = require('path');

const projectDir = 'C:\\Users\\Administrator\\Desktop\\Don\'t Starve Together ai';
const srcDir = path.join(projectDir, 'dst_databundles', 'scripts');
const outputZip = path.join(projectDir, 'dst_databundles', 'scripts.zip');

async function packScripts() {
    console.log('========================================');
    console.log('  DST Scripts Packager (Node.js)');
    console.log('========================================');
    console.log('');
    console.log(`Source: ${srcDir}`);

    // 检查源目录
    if (!fs.existsSync(srcDir)) {
        console.error(`ERROR: Source directory not found: ${srcDir}`);
        process.exit(1);
    }

    // 删除旧的 zip 文件
    if (fs.existsSync(outputZip)) {
        fs.unlinkSync(outputZip);
    }

    // 使用 archiver 库打包，确保使用 / 分隔符
    const Archiver = require('archiver');

    const output = fs.createWriteStream(outputZip);
    const archive = Archiver('zip', {
        zlib: { level: 5 }
    });

    archive.on('warning', (err) => {
        if (err.code !== 'ENOENT') {
            throw err;
        }
    });

    archive.on('error', (err) => {
        throw err;
    });

    // 等待完成
    await new Promise((resolve, reject) => {
        output.on('close', resolve);
        output.on('error', reject);
        archive.on('error', reject);

        // 打包整个 scripts 目录，使用相对路径
        archive.directory(srcDir, 'scripts');
        archive.finalize();

        // 将 archive 流连接到输出
        archive.pipe(output);
    });

    const fileSizeMB = (archive.pointer() / 1024 / 1024).toFixed(2);
    console.log('');
    console.log('========================================');
    console.log('  Packing Complete!');
    console.log('========================================');
    console.log('');
    console.log(`Output: ${outputZip}`);
    console.log(`Size: ${fileSizeMB} MB`);
    console.log('');
    console.log('Next steps:');
    console.log('1. Deploy to game:');
    console.log('   npm run deploy-scripts');
    console.log('');
    console.log('2. Or pack and deploy in one command:');
    console.log('   npm run pack-and-deploy');
    console.log('');
}

packScripts().catch(err => {
    console.error('ERROR:', err);
    process.exit(1);
});
