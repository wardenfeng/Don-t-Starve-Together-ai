# DST AI MCP Server

让AI通过 [MCP协议](https://modelcontextprotocol.io/) 与《饥荒联机版》游戏通信。

## 功能特性

- **MCP协议支持** - 提供标准MCP工具接口
- **支持多种模型** - Claude、GPT、Gemini等任何支持MCP的AI
- **完整动作支持** - 移动、采集、砍伐、挖掘、攻击、进食、装备等
- **实时状态反馈** - 玩家属性、周围实体、背包物品
- **低延迟通信** - 文件共享 + 事件驱动

## 项目结构

```
Don't Starve Together ai/
├── dst_scripts/           # DST 游戏脚本参考
├── dst-ai-mcp-server/     # MCP 服务器
├── docs/                  # 文档
└── scripts/               # 工具脚本
```

## 快速开始

### 安装依赖

```bash
npm install
```

### 构建项目

```bash
npm run build
```

### 配置 MCP 服务器

```bash
npm run config
```

这会自动配置所有 Claude 客户端：

| 客户端 | 配置位置 |
|--------|----------|
| VSCode Claude Code | `.vscode/settings.json` |
| Claude Desktop | `~/.config/claude/` |
| Claude CLI | `~/.claude/` 或 `~/.config/claude/` |

配置完成后：
- VSCode: 重新加载窗口 (`Ctrl+Shift+P` → `Reload Window`)
- Claude Desktop: 重启应用

### 启动服务

```bash
npm start
```

## MCP 工具

### get_game_state

获取当前游戏状态。

### send_action

发送动作指令到游戏。

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

## 可用命令

| 命令 | 说明 |
|------|------|
| `npm install` | 安装依赖 |
| `npm run build` | 构建MCP服务器 |
| `npm run dev` | 开发模式（自动重载） |
| `npm start` | 启动MCP服务器 |
| `npm run config` | 配置MCP客户端 |
| `npm run clean` | 清理构建产物 |

## 同步目录

服务器使用以下目录进行文件通信：

```
%USERPROFILE%\dst-ai-sync\
├── state.txt    # 游戏 → MCP (状态)
├── cmd.txt      # MCP → 游戏 (命令)
├── status.txt   # MCP心跳 (连接检测)
├── control.txt  # MCP → 游戏 (控制命令)
└── stats.txt    # 游戏 → MCP (统计信息)
```

## 配置选项

### 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `SYNC_DIR` | `%USERPROFILE%\dst-ai-sync\` | 同步目录 |
| `STATE_CACHE_TTL` | 5000 | 状态缓存过期时间(ms) |
| `COMMAND_SEQUENCE_START` | 1 | 命令序列号起始值 |

## DST 脚本参考

dst_scripts/ 目录包含DST游戏的Lua脚本：

- **actions.lua** - 游戏动作定义
- **components/** - 组件系统实现
- **prefabs/** - 游戏实体预制体
- **stategraphs/** - 状态机定义

## 故障排除

**MCP服务器无响应？**
- 检查配置路径是否正确
- 确认 `npm run build` 已执行
- 查看客户端开发者日志

**无法获取游戏状态？**
- 确认同步目录存在
- 检查游戏端是否正在写入状态文件

## 许可证

MIT

## 相关链接

- [Model Context Protocol](https://modelcontextprotocol.io/)
- [饥荒联机版](https://www.klei.com/games/dont-starve-together)
