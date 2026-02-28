# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 在此代码库中工作时提供指导。

## 项目概述

这是一个让AI自动玩饥荒联机版游戏的系统。采用**文件共享通信架构**：

- **游戏端**：Lua Mod，负责写入游戏状态到文件，并从文件读取AI指令
- **AI服务器**：Node.js服务器，使用chokidar监听文件变化，通过Claude API处理状态，输出指令

## 系统架构

```
DST 游戏进程 (Lua Mod)                  Node.js AI 服务器
┌─────────────────┐                   ┌─────────────────┐
│ 状态采集器      │── 写入 ────→  │ chokidar 监听器  │
│ 动作执行器      │←── 读取 ────  │ Claude API 客户端 │
│ 文件通信层      │   state.txt    │  决策引擎        │
└─────────────────┘                   └─────────────────┘
       ↕                                      ↕
    C:\dst-ai-sync\ (同步目录)
```

## 项目结构

```
Don't Starve Together ai/
├── dst-ai-mod/              # Lua Mod (放入游戏mods目录)
│   ├── modinfo.lua          # Mod元数据
│   ├── modmain.lua          # 入口文件，AI初始化
│   └── scripts/
│       └── ai/
│           ├── core/
│           │   ├── controller.lua      # AI主控制器
│           │   ├── state_collector.lua # 状态采集（玩家/世界/实体）
│           │   └── action_executor.lua # 动作执行（移动/攻击等）
│           └── communication/
│               └── file_bridge.lua     # 文件I/O抽象层
│
└── dst-ai-server/            # Node.js AI服务器
    ├── src/
    │   ├── main.ts              # 程序入口
    │   ├── communication/
    │   │   └── file-watcher.ts       # chokidar文件监听器
    │   └── ai/
    │       ├── claude/
    │       │   └── client.ts          # Claude API客户端
│       └── decision/
    │           └── engine.ts          # 决策逻辑
    └── package.json
```

## 通信协议

### state.txt (游戏 → AI服务器)

```json
{
  "v": 1,
  "t": 1234567890,
  "p": {"hp": 0.8, "hu": 0.6, "sa": 0.9, "pos": [100.5, 0, -200.3]},
  "w": {"day": 5, "time": 0.5, "season": "summer", "isDay": true},
  "e": [{"p": "berrybush", "pos": [105, 0, -198], "d": 5.2}]
}
```

### cmd.txt (AI服务器 → 游戏)

```json
{
  "v": 1,
  "t": 1234567890,
  "seq": 123,
  "actions": [{"type": "move", "target": [105, 0, -198]}]
}
```

## 关键配置

- **同步目录**：`C:\dst-ai-sync\` (需手动创建)
- **Lua更新间隔**：1帧 (~16ms) - 最大响应速度
- **Node.js文件监听**：chokidar (事件驱动, <1ms延迟)
- **总延迟**：~500-2000ms (Claude API调用占主导)

## 开发命令

### AI服务器 (Node.js)

```bash
cd dst-ai-server
npm install
npm start              # 启动服务器
npm run dev            # 开发模式（自动重载）
```

### 环境配置

在 `dst-ai-server/` 创建 `.env` 文件：
```
ANTHROPIC_API_KEY=你的api_key
SYNC_DIR=C:\dst-ai-sync\
```

### Lua Mod安装

1. 将 `dst-ai-mod/` 复制到DST mods目录
2. 在游戏设置中启用Mod
3. 创建 `C:\dst-ai-sync\` 目录
4. 进入游戏前先启动AI服务器

## 游戏内命令

打开控制台 (~) 使用：
- `ai_status()` - 显示AI统计信息
- `ai_enable()` - 启用AI控制
- `ai_disable()` - 禁用AI控制

## 动作类型

| 类型 | 说明 |
|------|------|
| `move` | 移动到目标位置 |
| `pickup` | 拾取物品 |
| `chop` | 砍伐树木 |
| `mine` | 挖掘岩石 |
| `attack` | 攻击敌人 |
| `eat` | 进食 |
| `equip` | 装备物品 |
| `wait` | 等待 |

## DST游戏API参考

实现/修改游戏交互时使用这些API：

**玩家状态获取**：
- `inst.components.health:GetPercent()` - 生命值
- `inst.components.hunger:GetPercent()` - 饥饿值
- `inst.components.sanity:GetPercent()` - 理智值
- `inst.Transform:GetWorldPosition()` - 返回 x, y, z 坐标

**实体发现**：
- `TheSim:FindEntities(x, y, z, radius)` - 查找范围内实体

**动作执行**：
- `inst.components.locomotor:GoToPoint(Point(x, y, z))` - 移动
- `BufferedAction(inst, target, ACTIONS.PICKUP)` - 创建动作
- `inst.components.locomotor:PushAction(action, true)` - 执行动作

**世界状态**：
- `TheWorld.state.cycles` - 天数
- `TheWorld.state.time` - 时间 (0-1)
- `TheWorld.state.season` - 季节字符串
- `TheWorld.state.isday / .isnight / .isdusk` - 白天/夜晚/黄昏

## 性能说明

- Lua文件I/O速度约 3-9ms/次
- 1帧轮询最大延迟约16ms
- chokidar使用OS事件，开销可忽略
- Claude API是主要瓶颈 (500-2000ms)，文件I/O不是瓶颈
