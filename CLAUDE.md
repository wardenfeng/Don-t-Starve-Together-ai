# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 在此代码库中工作时提供指导。

## 项目概述

这是一个让AI通过MCP协议与《饥荒联机版》游戏通信的系统。采用**文件共享通信架构**：

- **MCP服务器**：Node.js服务器，提供游戏状态查询和动作发送的MCP工具
- **游戏端**：通过外部Mod或脚本写入游戏状态到文件，并从文件读取AI指令

## 系统架构

```
游戏进程                          同步目录              MCP服务器
┌─────────────────┐                              ┌─────────────────┐
│ 状态写入器      │── 写入 ────→  state.txt      │ 状态缓存        │
│ 动作执行器      │←── 读取 ────  cmd.txt        │ 命令队列        │
└─────────────────┘                              └─────────────────┘
                       %USERPROFILE%\dst-ai-sync\
```

## 项目结构

```
Don't Starve Together ai/
├── dst_scripts/              # DST 游戏脚本参考
│   ├── actions.lua           # 动作定义
│   ├── components/           # 组件脚本
│   ├── prefabs/              # 预制体脚本
│   └── ...
│
├── dst-ai-mcp-server/        # Node.js MCP服务器
│   ├── src/
│   │   ├── index.ts          # 服务器入口
│   │   ├── sync/             # 文件同步层
│   │   │   ├── file-watcher.ts    # 文件监听
│   │   │   ├── state-cache.ts     # 状态缓存
│   │   │   └── command-queue.ts   # 命令队列
│   │   └── tools/            # MCP工具
│   │       ├── game-state.ts      # get_game_state
│   │       ├── action.ts          # send_action
│   │       └── control.ts         # enable_ai/disable_ai
│   └── package.json
│
├── docs/                     # 文档
│   ├── client-api-reference.md    # 客户端API参考
│   ├── client-file-io-guide.md    # 文件IO指南
│   └── communication-protocol.md  # 通信协议
│
└── scripts/                  # 工具脚本
```

## 通信协议

### state.txt (游戏 → MCP服务器)

```json
{
  "v": 1,
  "t": 1234567890,
  "p": {"hp": 0.8, "hu": 0.6, "sa": 0.9, "pos": [100.5, 0, -200.3]},
  "w": {"day": 5, "time": 0.5, "season": "summer", "isDay": true},
  "e": [{"p": "berrybush", "pos": [105, 0, -198], "d": 5.2}]
}
```

### cmd.txt (MCP服务器 → 游戏)

```json
{
  "v": 1,
  "t": 1234567890,
  "seq": 123,
  "actions": [{"type": "move", "target": [105, 0, -198]}]
}
```

## 关键配置

- **同步目录**：`%USERPROFILE%\dst-ai-sync\` (需手动创建)
- **Node.js文件监听**：chokidar (事件驱动, <1ms延迟)
- **状态缓存TTL**：5000ms

## 开发命令

```bash
# 安装依赖
npm install

# 构建MCP服务器
npm run build

# 启动MCP服务器（开发模式）
npm run dev

# 启动MCP服务器（生产模式）
npm start
```

## MCP工具

### get_game_state

获取当前游戏状态。

### send_action

发送动作指令到游戏。

支持的动作类型：
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

## DST 脚本参考

dst_scripts/ 目录包含DST游戏的Lua脚本，用于参考和理解游戏API：

- **actions.lua** - 所有游戏动作定义
- **components/** - 组件系统实现
- **prefabs/** - 游戏实体预制体
- **stategraphs/** - 状态机定义
