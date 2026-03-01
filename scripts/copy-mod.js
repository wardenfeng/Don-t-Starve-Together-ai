const fs = require('fs');
const path = require('path');

const source = `c:\\Users\\Administrator\\Desktop\\Don't Starve Together ai\\dst-ai-mod`;
const dest = `C:\\Program Files (x86)\\Steam\\steamapps\\common\\Don't Star Together\\mods\\dst-ai-mod`;

console.log('Copying from:', source);
console.log('To:', dest);

// 创建目标目录
if (!fs.existsSync(dest)) {
    fs.mkdirSync(dest, { recursive: true });
}

// 复制所有文件
const files = fs.readdirSync(source);
console.log('Files:', files);

for (const file of files) {
    const srcPath = path.join(source, file);
    const destPath = path.join(dest, file);
    const stat = fs.statSync(srcPath);

    if (stat.isDirectory()) {
        if (!fs.existsSync(destPath)) {
            fs.mkdirSync(destPath, { recursive: true });
        }
    } else {
        fs.copyFileSync(srcPath, destPath);
    }
}

console.log('Mod files copied successfully');
