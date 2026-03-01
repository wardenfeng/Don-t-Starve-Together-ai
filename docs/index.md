# DST AI Player - 文档索引

本目录包含 DST AI Player 项目的所有文档。

---

## 快速开始

- **[项目概述](../CLAUDE.md)** - 系统架构、目录结构、通信协议

---

## 项目文档

| 文档 | 说明 |
|------|------|
| **[通信协议](communication-protocol.md)** | 外部脚本与 AI 服务器的数据格式 |
| **[脚本说明](scripts.md)** | 所有 npm 脚本的功能和用法 |

---

## 系统架构

DST AI Player 使用**文件共享通信架构**：

```
┌─────────────────┐                   ┌─────────────────┐
│  DST 游戏进程   │                   │  Node.js MCP    │
│  (外部脚本)     │                   │     服务器      │
│                 │                   │                 │
│  状态采集器     │── 写入 ────→  │   文件监听器    │
│  动作执行器     │←── 读取 ────  │   Claude AI     │
└─────────────────┘   state.txt    └─────────────────┘
       ↕                                      ↕
    %USERPROFILE%\dst-ai-sync\ (同步目录)
```

### 通信流程

1. **游戏 → AI**: 外部脚本写入 `state.txt`
2. **AI 服务器**: chokidar 监听到变化，读取状态
3. **AI 处理**: 调用 Claude API 决策
4. **AI → 游戏**: 写入 `cmd.txt`
5. **外部脚本**: 读取并执行指令

---

## 目录结构

```
Don't Starve Together ai/
├── dst-ai-mcp-server/        # MCP 服务器
│   ├── src/
│   │   ├── sync/             # 文件同步层
│   │   └── tools/            # MCP 工具
│   └── package.json
│
├── dst_scripts/              # DST 游戏脚本参考
│   ├── actions.lua           # 动作定义
│   ├── components/           # 组件脚本
│   └── prefabs/              # 预制体脚本
│
├── docs/                     # 文档
│   ├── index.md              # 文档索引
│   ├── communication-protocol.md  # 通信协议
│   └── scripts.md            # 脚本说明
│
└── scripts/                  # 工具脚本
```

---

## 外部资源

### DST API 文档

- **[DST API Docs (Fandom)](https://dst-api-docs.fandom.com/wiki/Home)** - 完整的组件列表和 API 参考
- **[DST API Web Docs (GitHub)](https://github.com/vietnd69/dst-api-webdocs)** - 教程和示例
- **[Klei Modding Forum](https://forums.kleientertainment.com/forums/forum/79-dont-star-together-mods-and-tools/)** - 官方论坛

---

## 开发命令

```bash
# 配置 MCP 服务器
npm run setup-mcp

# 启动游戏和 MCP 服务器
npm run start-game

# 开发模式（文件监听）
npm run dev-mode

# 健康检查
npm run health-check

# 清理构建
npm run clean-build
```

---

## MCP 工具

| 工具 | 说明 |
|------|------|
| `get_game_state` | 获取当前游戏状态 |
| `send_action` | 发送动作指令到游戏 |
| `get_ai_status` | 获取 AI 控制器状态 |
| `enable_ai` | 启用 AI 自动模式 |
| `disable_ai` | 禁用 AI 自动模式 |
