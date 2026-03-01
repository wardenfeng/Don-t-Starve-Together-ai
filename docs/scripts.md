# DST AI Player - 脚本说明

本文档详细说明所有可用脚本的功能和用途。

---

## 用户命令

### install-mod
**安装 Mod 到游戏目录**

```bash
npm run install-mod
```

**执行流程：**
1. 查找游戏安装目录 `...\Don't Starve Together\mods\`
2. 复制 `dst-ai-mod/` 到游戏 mods 目录
3. 创建同步目录 `~/dst-ai-sync/`

**安装位置：**
```
C:\Program Files (x86)\Steam\steamapps\common\Don't Starve Together\mods\dst-ai-mod\
```

**相关文件：**
- `scripts/install-mod.js` - 安装逻辑

**注意：**
- 模组安装在游戏目录（与 workshop 模组相同位置）
- 不使用 `ForceEnableMod`，需要在游戏内手动启用
- 如需开发模式自动加载，需手动编辑 `mods\modsettings.lua`

---

### preinstall-mod
**卸载 Mod 并清理配置**

```bash
npm run preinstall-mod
```

**清理内容：**
1. 游戏目录中的 `mods\dst-ai-mod\`
2. 同步目录 `%USERPROFILE%\dst-ai-sync\`
3. `modsettings.lua` 中的 `ForceEnableMod` 配置
4. 所有 `modoverrides.lua` 中的模组配置
5. `modindex` 缓存

**相关文件：**
- `scripts/uninstall-mod.js` - 卸载和清理逻辑

**使用场景：**
- 开发前清理旧版本
- 模组出现问题需要完全重装
- 游戏因模组配置崩溃无法启动

---

### setup-mcp
**配置 MCP 服务器**

```bash
npm run setup-mcp
```

**功能：**
- 安装 npm 依赖
- 构建 TypeScript 代码
- 可选：启动游戏

---

### start-game
**启动游戏和 MCP 服务器**

```bash
npm run start-game
```

**执行流程：**
1. `prestart-game` 钩子运行 `stop-game.ps1` 关闭旧进程
2. 启动 MCP 服务器（后台运行）
3. 启动 Steam（如果未运行）
4. 启动饥荒联机版

**相关文件：**
- `scripts/stop-game.ps1` - 停止和清理（由钩子调用）
- `scripts/start-game.ps1` - 启动逻辑
- `scripts/start-game.js` - Node.js 入口

---

### dev-mode
**开发模式 - 文件监听自动重载**

```bash
npm run dev-mode
```

**功能：**
- 监听 `dst-ai-mcp-server/src/` 目录
- 代码变更时自动重新构建
- 自动重启 MCP 服务器

---

### build-mcp
**构建 MCP 服务器**

```bash
npm run build-mcp
```

**功能：**
- 编译 TypeScript 到 `dst-ai-mcp-server/dist/`

---

### health-check
**健康检查 - 诊断安装问题**

```bash
npm run health-check
```

**检查项：**
1. Node.js 是否安装
2. npm 是否可用
3. 游戏 Mods 目录是否存在
4. Mod 是否已安装
5. 同步目录权限
6. MCP 服务器是否已构建
7. MCP SDK 是否已安装
8. MCP 配置文件
9. 运行中的进程

---

### clean-build
**清理构建产物**

```bash
npm run clean-build
```

**清理内容：**
- `dst-ai-mcp-server/dist/`
- TypeScript 构建缓存

---

## 内部脚本

以下脚本不由用户直接调用，而是通过 npm 钩子自动执行：

### prestart-game (钩子)
```json
"prestart-game": "powershell -ExecutionPolicy Bypass -File scripts/stop-game.ps1"
```

在 `start-game` 之前自动运行，关闭游戏进程并清理缓存。

### stop-game.ps1
**内部停止脚本** - 被 `prestart-game` 钩子调用

功能：
- 关闭游戏进程
- 关闭 MCP 服务器进程
- 清理 Mod 缓存

---

## 文件结构

```
scripts/
├── install-mod.js      # 安装 Mod 到游戏目录
├── uninstall-mod.js    # 卸载 Mod 并清理配置
├── setup-mcp.js        # 配置 MCP
├── start-game.js       # 启动入口
├── start-game.ps1      # 启动逻辑
├── stop-game.ps1       # 停止逻辑（内部）
├── dev-mode.js         # 开发模式
├── health-check.js     # 健康检查
└── clean-build.js      # 清理构建
```

---

## npm 钩子说明

npm 支持以下钩子，在特定命令前后自动执行：

| 钩子 | 触发时机 |
|------|---------|
| `pre<command>` | 在 `<command>` 之前 |
| `post<command>` | 在 `<command>` 之后 |

本项目使用：
- `prestart-game` → 启动前自动停止

---

## 开发工作流

### 首次安装
```bash
npm run setup-mcp      # 配置 MCP
npm run install-mod    # 安装 Mod
npm run start-game     # 启动游戏
# 在游戏内 Mods 菜单中启用 "DST AI Player"
```

### 开发循环
```bash
npm run preinstall-mod # 清理旧版本
npm run install-mod    # 安装新版本
npm run start-game     # 启动测试
```

### 仅更新 Mod 代码
```bash
npm run install-mod    # 重新安装 Mod
# 游戏已运行时，直接重启游戏即可
```

---

## Mod 文件要求

### modinfo.lua
- 必须使用**双引号** `"`
- 必须使用 **CRLF** 行尾格式
- 必须纯英文（无中文字符）

### modmain.lua
- 小写文件名
- CRLF 行尾格式

### 安装验证
安装后检查以下文件存在：
```
...\mods\dst-ai-mod\
├── modinfo.lua
└── modmain.lua
```
