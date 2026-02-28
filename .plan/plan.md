# DST AI 玩家系统 - MCP Server 方案

## Context
创建一个让AI自动玩饥荒联机版游戏的系统。采用**文件共享 + MCP协议**架构：Lua Mod通过文件I/O与MCP服务器通信，大模型通过MCP工具调用获取游戏状态并下达指令。

---

## 系统架构

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                   游戏电脑                                      │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                          DST 游戏进程                                     │   │
│  │  ┌────────────────────────────────────────────────────────────────┐    │   │
│  │  │                       Lua AI Mod                               │    │   │
│  │  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐     │    │   │
│  │  │  │ 状态采集器    │  │ 动作执行器    │  │ 文件通信层       │     │    │   │
│  │  │  └──────────────┘  └──────────────┘  └──────────────────┘     │    │   │
│  │  └────────────────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                    ↕ 文件读写                                  │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                      同步目录 (C:\dst-ai-sync\)                           │
│  │  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐              │   │
│  │  │ state.txt    │    │ cmd.txt      │    │ status.txt   │              │   │
│  │  └──────────────┘    └──────────────┘    └──────────────┘              │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘
                                    ↕ 文件读写
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              MCP Server 进程                                    │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                           MCP 服务器                                     │   │
│  │                                                                          │   │
│  │  ┌────────────────────────────────────────────────────────────────┐    │   │
│  │  │                       工具层 (Tools)                            │    │   │
│  │  │                                                                │    │   │
│  │  │  get_game_state()    send_action()    get_ai_status()         │    │   │
│  │  │  enable_ai()         disable_ai()     watch_game()            │    │   │
│  │  └────────────────────────────────────────────────────────────────┘    │   │
│  │                              ↕                                          │   │
│  │  ┌────────────────────────────────────────────────────────────────┐    │   │
│  │  │                       文件同步层                                │    │   │
│  │  │                                                                │    │   │
│  │  │  chokidar 监听    状态缓存    命令队列    心跳管理               │    │   │
│  │  └────────────────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘
                                    ↕ MCP Protocol (stdio/SSE)
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              AI 大模型 (Claude/GPT等)                          │
│                        通过MCP工具调用获取状态并决策                            │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 数据流向
1. **游戏状态采集**: Lua Mod采集状态写入state.txt
2. **文件变化检测**: chokidar监听到变化，更新内部缓存
3. **MCP工具调用**: 大模型调用`get_game_state`获取状态
4. **AI决策**: 大模型分析状态，调用`send_action`发送命令
5. **命令执行**: Lua Mod读取cmd.txt，执行游戏动作

### 与原方案差异
| 原方案 | MCP方案 |
|--------|---------|
| 服务器主动调用Claude API | 大模型通过MCP工具调用 |
| 决策在服务器端完成 | 决策由调用的大模型完成 |
| 需要API密钥 | 无需API密钥 |
| 单一AI模型 | 可接入任何支持MCP的模型 |

---

## 项目目录结构

```
Don't Starve Together ai/
├── dst-ai-mod/              # Lua Mod (放入游戏mods目录)
│   ├── modinfo.lua          # Mod元数据
│   ├── modmain.lua          # 入口文件
│   └── scripts/ai/
│       ├── core/
│       │   ├── controller.lua      # AI主控制器
│       │   ├── state_collector.lua # 状态采集
│       │   └── action_executor.lua # 动作执行
│       └── communication/
│           └── file_bridge.lua     # 文件I/O抽象层
│
└── dst-ai-mcp-server/       # MCP服务器 (新增)
    ├── src/
    │   ├── index.ts             # 服务器入口
    │   ├── tools/               # MCP工具定义
    │   │   ├── game-state.ts    # get_game_state
    │   │   ├── action.ts        # send_action
    │   │   ├── control.ts       # enable/disable_ai
    │   │   └── watch.ts         # watch_game (流式)
    │   ├── sync/                # 文件同步层
    │   │   ├── file-watcher.ts  # chokidar监听
    │   │   ├── state-cache.ts   # 状态缓存管理
    │   │   ├── command-queue.ts # 命令队列
    │   │   └── heartbeat.ts     # 心跳管理
    │   └── types/
    │       └── game.ts          # 类型定义
    ├── package.json
    └── .env                    # 环境变量
```

---

## MCP工具设计

### 1. get_game_state

获取当前游戏状态的完整快照。

**输入参数**: 无

**返回结构**:
```json
{
  "success": true,
  "timestamp": 1234567890,
  "state": {
    "player": {
      "health": 0.85,
      "hunger": 0.62,
      "sanity": 0.95,
      "position": {"x": 100.5, "y": 0, "z": -200.3}
    },
    "world": {
      "day": 5,
      "time": 0.5,
      "season": "summer",
      "isDay": true,
      "moonPhase": "full"
    },
    "nearby": [
      {"prefab": "berrybush", "distance": 5.2, "position": {...}},
      {"prefab": "evergreen", "distance": 8.1, "position": {...}}
    ],
    "inventory": [
      {"prefab": "axe", "count": 1},
      {"prefab": "berry", "count": 12}
    ]
  }
}
```

**实现逻辑**:
- 从状态缓存读取最新数据
- 如果缓存为空或过期，主动读取state.txt
- 解析JSON并验证格式
- 返回结构化状态对象

---

### 2. send_action

向游戏发送单个或批量动作指令。

**输入参数**:
```json
{
  "actions": [
    {"type": "move", "target": {"x": 105, "y": 0, "z": -198}},
    {"type": "chop", "entity": "evergreen"}
  ]
}
```

**返回结构**:
```json
{
  "success": true,
  "sequence": 123,
  "sent": 2,
  "message": "Commands sent successfully"
}
```

**实现逻辑**:
- 生成递增序列号
- 为每个动作添加时间戳
- 序列化为JSON格式
- 原子写入cmd.txt文件
- 更新命令队列记录

---

### 3. get_ai_status

获取AI控制器状态和统计信息。

**输入参数**: 无

**返回结构**:
```json
{
  "enabled": true,
  "connected": true,
  "stats": {
    "cycles": 1523,
    "actionsExecuted": 856,
    "errors": 3
  },
  "lastUpdate": 1234567890
}
```

**实现逻辑**:
- 读取status.txt判断服务器连接
- 从内部缓存获取统计信息
- 统计信息由Lua Mod定期写入stats.txt
- 返回合并后的状态对象

---

### 4. enable_ai / disable_ai

控制AI自动模式的开启/关闭。

**输入参数**: 无

**返回结构**:
```json
{
  "success": true,
  "enabled": true,
  "message": "AI control enabled"
}
```

**实现逻辑**:
- 写入control.txt文件
- 内容为 "ENABLE" 或 "DISABLE"
- Lua Mod监听此文件变化
- 返回操作结果

---

### 5. watch_game (流式工具)

持续监听游戏状态变化，实时推送更新。

**输入参数**:
```json
{
  "interval": 1000,
  "onChange": true
}
```

**返回**: Server-Sent Events流

**实现逻辑**:
- 注册chokidar监听器
- state.txt变化时触发
- 通过SSE推送新状态
- 客户端断开时清理监听器

---

## 文件同步层设计

### 1. 文件监听器

**职责**: 监听同步目录的所有文件变化

**实现逻辑**:
- 使用chokidar创建监听实例
- 监听三个文件：state.txt, cmd.txt, status.txt
- 每个文件变化触发对应的事件回调
- 提供watch()方法启动监听
- 提供close()方法停止监听

**事件映射**:
| 文件 | 事件 | 触发操作 |
|------|------|----------|
| state.txt | change | 更新状态缓存 |
| cmd.txt | change | 清空已发送命令 |
| status.txt | change | 更新连接状态 |

---

### 2. 状态缓存管理

**职责**: 管理游戏状态的内存缓存

**实现逻辑**:
- 维护lastState变量存储最新状态
- 维护lastTimestamp记录更新时间
- 提供get()方法读取缓存
- 提供set()方法更新缓存
- 提供isExpired()判断缓存是否过期
- 过期时间默认5秒

**优势**:
- 减少磁盘I/O
- 快速响应get_game_state调用
- 支持轮询场景

---

### 3. 命令队列

**职责**: 管理待发送和已发送的命令

**实现逻辑**:
- 维护pending队列存储待发送命令
- 维护sent队列存储已发送命令
- 维护sequence计数器
- 提供enqueue()方法添加命令
- 提供dequeue()方法取出命令
- 提供acknowledge()方法确认执行

**防重复机制**:
- 每个命令携带递增序列号
- Lua Mod记录已执行的最大序列号
- 重复序列号的命令被忽略

---

### 4. 心跳管理

**职责**: 维护与游戏的双向心跳检测

**实现逻辑**:
- 服务器每秒写入status.txt = "CONNECTED"
- Lua Mod每秒读取status.txt
- 如果文件不存在或内容不对，标记未连接
- 提供isConnected()方法查询状态
- 提供start()和stop()方法控制心跳

---

## 通信协议

### state.txt (游戏 → MCP服务器)

```json
{
  "v": 1,
  "t": 1234567890,
  "p": {
    "hp": 0.85,
    "hu": 0.62,
    "sa": 0.95,
    "pos": [100.5, 0, -200.3]
  },
  "w": {
    "day": 5,
    "time": 0.5,
    "season": "summer",
    "isDay": true
  },
  "e": [
    {"p": "berrybush", "pos": [105, 0, -198], "d": 5.2}
  ],
  "i": [
    {"p": "axe", "n": 1},
    {"p": "berry", "n": 12}
  ]
}
```

字段简写: p=player, w=world, e=entities, i=inventory

### cmd.txt (MCP服务器 → 游戏)

```json
{
  "v": 1,
  "t": 1234567890,
  "seq": 123,
  "a": [
    {"type": "move", "target": [105, 0, -198]},
    {"type": "pickup", "entity": "berrybush"}
  ]
}
```

字段简写: a=actions

### status.txt (服务器心跳)

内容: "CONNECTED"

### control.txt (MCP服务器 → 游戏)

内容: "ENABLE" 或 "DISABLE"

### stats.txt (游戏 → MCP服务器)

```json
{
  "enabled": true,
  "cycles": 1523,
  "actions": 856,
  "errors": 3
}
```

---

## Lua Mod 核心模块

### 1. 文件通信桥接

**职责**: 封装文件I/O操作

**核心功能**:
- WriteState(): 将状态对象序列化为JSON并写入
- ReadCommand(): 读取命令文件并解析JSON
- CheckControl(): 检查control.txt并响应控制命令
- WriteStats(): 定期写入统计信息
- 序列号去重机制

**实现要点**:
- 手动构建JSON字符串（无外部库）
- 写入频率限制（默认10帧一次）
- 序列号记录防止重复执行

---

### 2. AI主控制器

**职责**: 协调状态采集和动作执行

**核心功能**:
- 每N帧触发一次AI循环
- 采集状态 → 写入文件 → 读取命令 → 执行动作
- 监听control.txt响应enable/disable
- 维护统计信息

**工作流程**:
```
OnUpdate (每帧)
  ↓
[达到间隔?]
  ↓
CollectState → WriteState
  ↓
ReadControl → [有控制命令?] → 处理
  ↓
ReadCommand → [有新命令?] → ExecuteAction
  ↓
UpdateStats
```

---

### 3. 状态采集器

**职责**: 从游戏采集状态信息

**采集内容**:
- 玩家：位置、生命值、饥饿值、理智值
- 世界：天数、时间、季节、昼夜、月相
- 实体：附近15个实体的类型、位置、距离
- 背包：物品列表和数量

**优化策略**:
- 实体按距离排序
- 限制实体数量
- 坐标保留1位小数

---

### 4. 动作执行器

**职责**: 执行AI命令

**支持动作**:
- move: 移动到位置
- pickup: 拾取物品
- chop: 砍树
- mine: 挖矿
- attack: 攻击
- eat: 进食
- equip: 装备
- wait: 等待

**实现方法**:
- 根据type字段路由
- 使用BufferedAction创建动作
- 通过locomotor执行

---

## MCP服务器实现

### 入口文件 (index.ts)

**职责**: 初始化并启动MCP服务器

**启动流程**:
1. 读取环境变量（SYNC_DIR等）
2. 验证同步目录存在
3. 初始化文件同步层
4. 注册所有MCP工具
5. 启动stdio通信
6. 启动心跳

**实现逻辑**:
- 使用@mcp/sdk创建Server实例
- 遍历tools目录注册所有工具
- 设置stdio传输
- 处理信号优雅退出

---

### 工具实现模式

每个工具遵循统一模式：

```typescript
// 工具定义
const tool = {
  name: "tool_name",
  description: "工具描述",
  inputSchema: {
    type: "object",
    properties: { /* 参数定义 */ }
  }
};

// 处理函数
async function handler(args: any) {
  try {
    // 1. 验证参数
    // 2. 执行业务逻辑
    // 3. 返回结果
  } catch (error) {
    return { success: false, error: error.message };
  }
}
```

---

## 使用方式

### 1. 安装

```bash
# 游戏端
# 1. 创建同步目录 C:\dst-ai-sync\
# 2. 将dst-ai-mod复制到DST mods目录

# MCP服务器
cd dst-ai-mcp-server
npm install
npm run build
```

### 2. 配置

创建 `.env`:
```
SYNC_DIR=C:\dst-ai-sync\
UPDATE_INTERVAL=10
SCAN_RADIUS=20
```

### 3. 启动MCP服务器

```bash
npm start
```

### 4. 配置Claude Desktop

在 `claude_desktop_config.json` 添加:

```json
{
  "mcpServers": {
    "dst-ai": {
      "command": "node",
      "args": ["C:\\path\\to\\dst-ai-mcp-server\\dist\\index.js"],
      "env": {
        "SYNC_DIR": "C:\\dst-ai-sync\\"
      }
    }
  }
}
```

### 5. 使用示例

在Claude中:
```
请帮我查看当前游戏状态，然后去采集一些浆果
```

Claude会自动:
1. 调用 get_game_state 获取状态
2. 分析附近是否有浆果丛
3. 调用 send_action 发送移动和采集命令

---

## 延迟分析

### 原方案 (服务器调用Claude API)

| 阶段 | 耗时 | 说明 |
|------|------|------|
| 游戏状态采集 + 写入 | ~10ms | 内存 + 磁盘 |
| chokidar检测 + 读取 | ~5ms | OS事件 + 磁盘 |
| **Claude API调用** | **500-2000ms** | **网络 + 模型推理** |
| 写入cmd.txt | ~5ms | 磁盘I/O |
| 游戏读取执行 | ~1ms | 内存 |
| **总计** | **~520-2020ms** | |

### MCP方案 (Claude通过MCP直接调用)

| 阶段 | 耗时 | 说明 |
|------|------|------|
| 游戏状态采集 + 写入 | ~10ms | 内存 + 磁盘 |
| chokidar检测 + 读取 | ~5ms | OS事件 + 磁盘 |
| MCP工具调用 (stdio) | ~5-10ms | 本地进程通信 |
| **Claude模型推理** | **500-2000ms** | **依然存在** |
| send_action写入 | ~5ms | 磁盘I/O |
| 游戏读取执行 | ~1ms | 内存 |
| **总计** | **~525-2030ms** | |

### 延迟对比

| 方案 | 文件I/O | 网络延迟 | 模型推理 | 总计 |
|------|---------|----------|----------|------|
| 原方案 | ~20ms | ~50-200ms | 500-2000ms | ~570-2220ms |
| MCP方案 | ~20ms | 0 | 500-2000ms | ~520-2020ms |
| **节省** | - | **50-200ms** | - | **~50-200ms** |

**结论**: MCP方案节省的主要是API网络延迟，模型推理时间依然存在。但MCP方案的优势在于：
- 无需API密钥和配额限制
- 可接入任何支持MCP的模型
- Claude能看到更完整的上下文（直接对话而非服务器转发）

---

## 关键文件

| 文件 | 作用 |
|------|------|
| index.ts | MCP服务器入口 |
| file-watcher.ts | 文件监听 |
| state-cache.ts | 状态缓存 |
| game-state.ts | get_game_state工具 |
| action.ts | send_action工具 |
| control.ts | enable/disable工具 |
| controller.lua | AI主控制器 |
| file_bridge.lua | 文件通信 |
