# DST AI Player - MCP版本

让AI通过[MCP协议](https://modelcontextprotocol.io/)自动玩《饥荒联机版》游戏。

## 系统架构

```
游戏进程 (Lua Mod)          同步目录             MCP服务器              AI模型
┌──────────────┐           ┌─────────┐         ┌──────────┐          ┌──────┐
│ 状态采集器    │──写──────→│state.txt│──监听──→│状态缓存  │          │Claude│
│ 动作执行器    │←──读──────│cmd.txt  │←─写入───│命令队列  │←─MCP工具─│/GPT  │
└──────────────┘           └─────────┘         └──────────┘          └──────┘
```

## 功能特性

- **无API密钥需求** - 直接使用已登录的Claude Desktop或其他MCP客户端
- **支持多种模型** - Claude、GPT、Gemini等任何支持MCP的AI
- **完整动作支持** - 移动、采集、砍伐、挖掘、攻击、进食、装备等
- **实时状态反馈** - 玩家属性、周围实体、背包物品
- **低延迟通信** - 文件共享 + MCP，响应迅速

## 快速开始

### 一键安装（推荐）

```bash
# 克隆项目后，在项目根目录运行：
npm install
npm run setup    # 安装Mod + 配置MCP服务器
npm start        # 启动游戏和MCP服务器
```

### 手动安装

#### 1. 安装游戏Mod

运行安装脚本：
```bash
npm run install
```

或将 `dst-ai-mod` 文件夹复制到饥荒联机版 Mods 目录：
   - Windows: `Documents\Klei\DoNotStarveTogether\Mods\`

#### 2. 配置MCP服务器

```bash
npm run setup
```

此命令会：
- 安装 npm 依赖
- 编译 TypeScript 代码

#### 3. 配置 MCP 服务器（所有客户端）

```bash
npm run config
```

这会自动配置所有 Claude 客户端：

| 客户端 | 配置位置 |
|--------|----------|
| VSCode Claude Code | `.vscode/settings.json` |
| Claude Desktop | `~/.config/claude/` |
| Claude CLI | `~/.claude/` 或 `~/.config/claude/` |

**完成后**：
- VSCode: 重新加载窗口 (`Ctrl+Shift+P` → `Reload Window`)
- Claude Desktop: 重启应用
- Claude CLI: 直接可用

在对话中输入 `/mcp` 验证配置

#### 4. 启动系统

```bash
npm start
```

### 其他可用命令

| 命令 | 说明 |
|------|------|
| `npm run setup` | 安装Mod + 配置MCP服务器 |
| `npm run install` | 仅安装游戏Mod |
| `npm start` | 启动游戏和MCP服务器 |
| `npm run dev` | 开发模式（自动重载） |
| `npm run build` | 构建MCP服务器 |
| `npm run test` | 测试MCP服务器 |
| `npm run check` | 健康检查 |
| `npm run clean` | 清理构建产物 |
| `npm run uninstall` | 卸载Mod和配置 |

### 4. 使用

1. 启动饥荒联机版
2. 在设置中启用 "DST AI Player (MCP)" Mod
3. 进入游戏，打开控制台 (`~`) 输入 `ai_enable()`
4. 在Claude对话中操作：
   ```
   请帮我查看当前状态，然后去采集一些浆果
   ```

## 游戏内命令

| 命令 | 说明 |
|------|------|
| `ai_status()` | 显示AI统计信息 |
| `ai_enable()` | 启用AI控制 |
| `ai_disable()` | 禁用AI控制 |

## MCP工具

### get_game_state

获取当前游戏状态。

```json
{
  "success": true,
  "state": {
    "player": { "health": "85%", "hunger": "62%", ... },
    "world": { "day": 5, "season": "summer", ... },
    "nearby": [...],
    "inventory": "..."
  }
}
```

### send_action

发送动作指令到游戏。

```json
{
  "actions": [
    { "type": "move", "target": {"x": 100, "y": 0, "z": -200} },
    { "type": "pickup", "entity": "berrybush" }
  ]
}
```

**支持的动作类型**：
- `move` - 移动到位置
- `pickup` - 拾取物品
- `chop` - 砍树
- `mine` - 挖矿
- `dig` - 挖掘
- `attack` - 攻击
- `eat` - 进食
- `equip` - 装备物品
- `unequip` - 卸下装备
- `craft` - 制作物品
- `build` - 放置建筑
- `wait` - 等待
- `follow` - 跟随实体
- `revive` - 复活

### get_ai_status

获取AI控制器状态。

### enable_ai / disable_ai

控制AI自动模式。

## 文件说明

### 同步目录结构

```
%dst-ai-sync%\
├── state.txt    # 游戏 → MCP (状态)
├── cmd.txt      # MCP → 游戏 (命令)
├── status.txt   # MCP心跳 (连接检测)
├── control.txt  # MCP → 游戏 (控制命令)
└── stats.txt    # 游戏 → MCP (统计信息)
```

### Lua Mod文件

| 文件 | 说明 |
|------|------|
| [modinfo.lua](dst-ai-mod/modinfo.lua) | Mod元数据和配置选项 |
| [modmain.lua](dst-ai-mod/modmain.lua) | 入口文件，注册控制台命令 |
| [file_bridge.lua](dst-ai-mod/scripts/ai/communication/file_bridge.lua) | 文件I/O抽象层 |
| [state_collector.lua](dst-ai-mod/scripts/ai/core/state_collector.lua) | 状态采集器 |
| [action_executor.lua](dst-ai-mod/scripts/ai/core/action_executor.lua) | 动作执行器 |
| [controller.lua](dst-ai-mod/scripts/ai/core/controller.lua) | AI主控制器 |

### MCP服务器文件

| 文件 | 说明 |
|------|------|
| [index.ts](dst-ai-mcp-server/src/index.ts) | 服务器入口 |
| [file-watcher.ts](dst-ai-mcp-server/src/sync/file-watcher.ts) | 文件监听器 |
| [state-cache.ts](dst-ai-mcp-server/src/sync/state-cache.ts) | 状态缓存 |
| [command-queue.ts](dst-ai-mcp-server/src/sync/command-queue.ts) | 命令队列 |
| [heartbeat.ts](dst-ai-mcp-server/src/sync/heartbeat.ts) | 心跳管理 |
| [game-state.ts](dst-ai-mcp-server/src/tools/game-state.ts) | get_game_state工具 |
| [action.ts](dst-ai-mcp-server/src/tools/action.ts) | send_action工具 |
| [control.ts](dst-ai-mcp-server/src/tools/control.ts) | 控制工具 |

## 配置选项

### Mod配置 (游戏内)

| 选项 | 默认值 | 说明 |
|------|--------|------|
| 同步目录 | `%USERPROFILE%\dst-ai-sync\` | 文件同步路径 |
| 更新间隔 | 10帧 | 状态采集频率 |
| 扫描半径 | 20单位 | 实体检测范围 |
| 最大实体数 | 15个 | 最多采集实体数 |

### 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `SYNC_DIR` | `%USERPROFILE%\dst-ai-sync\` | 同步目录 |
| `STATE_CACHE_TTL` | 5000 | 状态缓存过期时间(ms) |
| `COMMAND_SEQUENCE_START` | 1 | 命令序列号起始值 |

## 开发

### 构建MCP服务器

```bash
cd dst-ai-mcp-server
npm install
npm run build
```

### 开发模式

```bash
npm run dev
```

### 查看日志

MCP服务器的日志会输出到stderr，可以在Claude Desktop的日志中查看。

## 故障排除

**游戏Mod无法加载？**
- 确保同步目录存在
- 检查控制台是否有错误信息

**MCP服务器无响应？**
- 检查Claude Desktop配置路径是否正确
- 确认 `npm run build` 已执行
- 查看Claude Desktop开发者日志

**AI不执行动作？**
- 确认游戏内输入了 `ai_enable()`
- 检查 `ai_status()` 输出
- 确认MCP服务器正在运行

## 许可证

MIT

## 相关链接

- [Model Context Protocol](https://modelcontextprotocol.io/)
- [饥荒联机版](https://www.klei.com/games/dont-starve-together)
- [DST Mod API](https://dstapi.com/)
