# DST AI Player - 系统架构

本文档详细说明 DST AI Player 的系统架构设计。

---

## 目录

1. [架构概述](#架构概述)
2. [通信架构](#通信架构)
3. [游戏端架构](#游戏端架构)
4. [AI 服务器架构](#ai-服务器架构)
5. [数据流](#数据流)
6. [性能分析](#性能分析)

---

## 架构概述

DST AI Player 采用**文件共享通信架构**，让 AI 控制饥荒联机版游戏角色。

### 设计原则

1. **解耦合**: 游戏端与 AI 端独立运行
2. **简单可靠**: 使用文件作为中间介质
3. **跨进程**: 不需要修改游戏网络协议
4. **可调试**: 所有通信数据可查看

### 架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                         用户电脑                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────┐              ┌─────────────────────┐   │
│  │   DST 游戏进程      │              │   Node.js 进程      │   │
│  │                     │              │                     │   │
│  │  ┌───────────────┐  │              │  ┌───────────────┐  │   │
│  │  │ 状态采集器    │  │              │  │ 文件监听器    │  │   │
│  │  │ 1帧/次 ~16ms  │  │              │  │ chokidar <1ms │  │   │
│  │  └───────┬───────┘  │              │  └───────┬───────┘  │   │
│  │          │ 写入     │              │          │ 读取     │   │
│  │          ▼          │              │          ▼          │   │
│  │  ┌───────────────┐  │              │  ┌───────────────┐  │   │
│  │  │ 动作执行器    │  │              │  │ Claude API    │  │   │
│  │  │ 读取指令      │◄─┼──────────────┼──┤ 决策引擎      │  │   │
│  │  └───────────────┘  │              │  │ 500-2000ms   │  │   │
│  │                     │              │  └───────────────┘  │   │
│  │  Lua Mod            │              │  TypeScript        │   │
│  └─────────────────────┘              └─────────────────────┘   │
│                                          ▲          │          │
│                                          │          │ 写入     │
│                                  ┌───────┴──────────┴───────┐  │
│                                  │     同步目录             │  │
│                                  │  dst-ai-sync/            │  │
│                                  │  ├── state.txt           │  │
│                                  │  └── cmd.txt             │  │
│                                  └──────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 通信架构

### 为什么选择文件共享？

| 方案 | 优点 | 缺点 | 选择 |
|------|------|------|------|
| 文件共享 | 简单、可调试、跨进程 | 延迟较高 | ✅ 采用 |
| 管道 (Named Pipe) | 低延迟 | 复杂、调试困难 | ❌ |
| 网络套接字 | 跨机器 | 需要、防火墙 | ❌ |
| 共享内存 | 最低延迟 | 复杂、不稳定 | ❌ |
| 修改游戏网络 | 理想方案 | 需要反编译、不可维护 | ❌ |

### 同步目录

```
C:\Users\Administrator\dst-ai-sync\
├── state.txt     # 游戏状态 (游戏 → AI)
└── cmd.txt       # AI 指令 (AI → 游戏)
```

### 通信延迟

| 环节 | 延迟 |
|------|------|
| Mod 状态采集 | ~1ms |
| 文件写入 (io.write) | ~3-9ms |
| chokidar 事件 | <1ms |
| 文件读取 | ~1-3ms |
| Claude API 调用 | **500-2000ms** |
| 指令执行 | ~1ms |
| **总计** | **~500-2200ms** |

**结论**: Claude API 是主要瓶颈，文件 I/O 不是问题。

---

## 游戏端架构

### 目录结构

```
dst-ai-mod/
├── modinfo.lua                 # Mod 元数据
├── modmain.lua                 # 入口文件
└── scripts/
    └── ai/
        ├── core/
        │   ├── controller.lua           # AI 主控制器
        │   ├── state_collector.lua      # 状态采集
        │   └── action_executor.lua      # 动作执行
        └── communication/
            └── file_bridge.lua          # 文件 I/O 抽象
```

### 模块职责

#### controller.lua - 主控制器

```lua
职责：
- 初始化 AI 系统
- 协调状态采集和动作执行
- 管理执行循环
- 处理错误和重试

关键函数：
- Init()       -- 初始化
- OnUpdate()   -- 每帧调用
- Shutdown()   -- 清理
```

#### state_collector.lua - 状态采集

```lua
职责：
- 采集玩家状态 (HP, 饥饿, 理智, 位置)
- 采集世界状态 (天数, 时间, 季节)
- 发现附近实体
- 序列化为 JSON

关键函数：
- CollectPlayerState()    -- 玩家状态
- CollectWorldState()     -- 世界状态
- FindNearbyEntities()    -- 实体发现
- WriteToFile()           -- 写文件
```

#### action_executor.lua - 动作执行

```lua
职责：
- 读取 AI 指令
- 解析动作类型
- 调用 DST API 执行
- 处理执行失败

关键函数：
- ReadCommand()           -- 读指令
- ExecuteMove()           -- 移动
- ExecutePickup()         -- 拾取
- ExecuteChop()           -- 砍树
- ExecuteAttack()         -- 攻击
```

#### file_bridge.lua - 文件桥接

```lua
职责：
- 抽象文件 I/O
- 处理路径
- 错误处理

关键函数：
- ReadStateFile()         -- 读取状态
- WriteCommandFile()      -- 写入指令
```

---

## AI 服务器架构

### 目录结构

```
dst-ai-mcp-server/
├── src/
│   ├── index.ts                  # 程序入口
│   ├── communication/
│   │   └── file-watcher.ts       # chokidar 文件监听
│   └── ai/
│       ├── claude/
│       │   └── client.ts         # Claude API 客户端
│       └── decision/
│           └── engine.ts         # 决策引擎
├── package.json
└── tsconfig.json
```

### 模块职责

#### index.ts - 入口

```typescript
职责：
- 启动服务器
- 初始化组件
- 处理信号

关键函数：
- main()           -- 主函数
- shutdown()       -- 优雅关闭
```

#### file-watcher.ts - 文件监听

```typescript
职责：
- 使用 chokidar 监听文件变化
- 读取状态文件
- 触发决策引擎

关键函数：
- watch()          -- 开始监听
- onStateChange()  -- 状态变化回调
```

#### client.ts - Claude API

```typescript
职责：
- 调用 Claude API
- 发送游戏状态
- 接收 AI 决策
- 错误处理和重试

关键函数：
- decide()         -- 获取决策
- formatPrompt()   -- 格式化提示词
```

#### engine.ts - 决策引擎

```typescript
职责：
- 解析游戏状态
- 格式化 Claude 提示词
- 解析 Claude 响应
- 写入指令文件

关键函数：
- processState()   -- 处理状态
- writeCommand()   -- 写指令
```

---

## 数据流

### 完整流程

```
1. Mod 采集状态
   └─> state_collector.lua:Collect()

2. 写入 state.txt
   └─> file_bridge.lua:WriteState()
       └─> io.open("state.txt", "w")

3. chokidar 检测变化
   └─> file-watcher.ts:onStateChange()

4. 读取 state.txt
   └─> fs.readFile("state.txt")

5. 发送到 Claude API
   └─> client.ts:decide(state)

6. Claude 处理 (500-2000ms)
   └─> 返回动作序列

7. 写入 cmd.txt
   └─> engine.ts:writeCommand()

8. Mod 读取指令
   └─> action_executor.lua:ReadCommand()

9. 执行动作
   └─> inst.components.locomotor:PushAction()
```

### 状态数据格式

```json
// state.txt
{
  "v": 1,
  "t": 1234567890,
  "p": {"hp": 0.8, "hu": 0.6, "sa": 0.9, "x": 100, "y": 0, "z": -200},
  "w": {"day": 5, "time": 0.5, "season": "autumn"},
  "e": [{"p": "berrybush", "x": 105, "y": 0, "z": -198, "d": 5.2}]
}
```

### 指令数据格式

```json
// cmd.txt
{
  "v": 1,
  "t": 1234567890,
  "seq": 123,
  "actions": [{"type": "move", "target": {"x": 105, "y": 0, "z": -198}}]
}
```

---

## 性能分析

### 延迟分解

| 组件 | 时间 | 占比 |
|------|------|------|
| 文件 I/O (写) | ~5ms | <1% |
| 文件 I/O (读) | ~2ms | <1% |
| chokidar | <1ms | <1% |
| Claude API | 500-2000ms | **95%+** |
| 动作执行 | ~1ms | <1% |

### 优化建议

1. **Claude API** - 主要瓶颈
   - 使用更快的模型 (Haiku)
   - 减少提示词长度
   - 缓存常见决策

2. **文件 I/O** - 不是瓶颈
   - 当前后续已经足够快
   - 优化收益有限

3. **动作执行** - 不是瓶颈
   - DST API 调用很快
   - 延迟可忽略

### 并发处理

```
游戏循环 (60 FPS)
    ↓
每帧采集状态 (~1ms)
    ↓
写入文件 (~5ms)
    ↓
...继续游戏...
    ↓
读取指令 (当可用) (~2ms)
    ↓
执行动作 (~1ms)
```

AI 服务器独立运行，不阻塞游戏。

---

## 错误处理

### 游戏端

| 错误 | 处理 |
|------|------|
| 文件写入失败 | 记录日志，跳过 |
| 文件读取失败 | 使用上次状态 |
| 指令格式错误 | 记录日志，忽略 |
| 动作执行失败 | 记录日志，继续 |

### AI 服务器

| 错误 | 处理 |
|------|------|
| 文件读取失败 | 记录日志，等待下次 |
| Claude API 失败 | 重试 (最多3次) |
| 指令写入失败 | 记录日志，重试 |
| 网络超时 | 使用默认策略 |

---

## 扩展性

### 支持更多游戏

架构可扩展到其他游戏：

1. **游戏端**: 实现 Mod 插件
2. **AI 端**: 适配新游戏状态格式
3. **协议**: 定义新的 state/cmd 格式

### 支持多个 AI 模型

```typescript
// 客户端抽象
interface AIClient {
    decide(state: GameState): Promise<Action[]>;
}

class ClaudeClient implements AIClient { }
class OpenAIClient implements AIClient { }
class LocalLLMClient implements AIClient { }
```

---

## 相关文档

- **[通信协议](communication-protocol.md)** - 详细协议说明
- **[API 快速参考](mod-api-reference.md)** - DST API 手册
- **[开发指南](mod-development-guide.md)** - Mod 开发教程
