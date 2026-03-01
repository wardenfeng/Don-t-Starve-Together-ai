# 通信协议

本文档详细说明游戏 Mod 与 AI 服务器之间的通信协议。

---

## 目录

1. [协议概述](#协议概述)
2. [技术依据](#技术依据)
3. [同步目录](#同步目录)
4. [游戏状态 (state.txt)](#游戏状态-statetxt)
5. [AI 指令 (cmd.txt)](#ai-指令-cmdtxt)
6. [协议版本](#协议版本)
7. [错误处理](#错误处理)

---

## 协议概述

DST AI Player 使用**文件共享通信架构**：

```
┌─────────────────┐                   ┌─────────────────┐
│ DST 游戏进程    │                   │ Node.js AI 服务器 │
│  (Lua Mod)      │                   │                  │
│                 │                   │                 │
│ 状态采集器      │── 写入 ────→  │ 文件监听器       │
│ 动作执行器      │←── 读取 ────  │ Claude API 客户端│
│                 │   state.txt    │                 │
└─────────────────┘                   └─────────────────┘
       ↕                                      ↕
    C:\dst-ai-sync\ (同步目录)
```

### 通信流程

1. **游戏 → AI**: Mod 每帧写入 `state.txt`
2. **AI 服务器**: chokidar 监听到变化，读取状态
3. **AI 处理**: 调用 Claude API 决策
4. **AI → 游戏**: 写入 `cmd.txt`
5. **游戏 Mod**: 读取并执行指令

---

## 技术依据

### 为什么选择文件共享？

经过对 `dst_scripts` 的全面分析：

| 方案 | DST 支持 | 证据 |
|------|----------|------|
| 文件共享 | ✅ 支持 | `io.open()` 在 class.lua:136 等多处使用 |
| Mod RPC | ❌ 仅游戏内 | networkclientrpc.lua:1664 - 无法访问外部 |
| HTTP/Socket | ❌ 不支持 | 搜索结果为 0 |

### 证据：官方文件 I/O 使用

| 文件 | 位置 | 功能 |
|------|------|------|
| `class.lua` | [行 136](../dst_scripts/class.lua#L136) | `io.open(path, "r")` 读取源文件 |
| `createstringspo.lua` | [行 258](../dst_scripts/createstringspo.lua#L258) | `io.open(filename, "w")` 写入翻译 |
| `debugcommands.lua` | [行 1439](../dst_scripts/debugcommands.lua#L1439) | `io.open(out_file_name, "w")` 导出数据 |

### 证据：Mod RPC 的局限

```lua
-- dst_scripts/networkclientrpc.lua:1711
function SendModRPCToServer(id_table, ...)
    -- 仅用于游戏内客户端到服务器通信
    TheNet:SendModRPCToServer(id_table.namespace, id_table.id, ...)
end
```

**结论**: Mod RPC 无法发送到游戏外部进程。

---

## 同步目录

### 位置

```
C:\Users\Administrator\dst-ai-sync\
```

### 文件

| 文件 | 方向 | 说明 |
|------|------|------|
| `state.txt` | 游戏 → AI | 当前游戏状态 JSON |
| `cmd.txt` | AI → 游戏 | AI 动作指令 JSON |

### 创建

安装脚本会自动创建：

```bash
npm run install-mod
```

或手动创建：

```powershell
New-Item -ItemType Directory -Path "C:\Users\Administrator\dst-ai-sync"
```

---

## 游戏状态 (state.txt)

### 文件格式

JSON 格式，单行存储。

### 结构

```json
{
  "v": 1,
  "t": 1234567890,
  "p": {
    "hp": 0.8,
    "hu": 0.6,
    "sa": 0.9,
    "x": 100.5,
    "y": 0,
    "z": -200.3
  },
  "w": {
    "day": 5,
    "time": 0.5,
    "season": "autumn",
    "isDay": true,
    "isNight": false,
    "isDusk": false
  },
  "e": [
    {
      "p": "berrybush",
      "x": 105,
      "y": 0,
      "z": -198,
      "d": 5.2
    }
  ]
}
```

### 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| `v` | number | 协议版本 |
| `t` | number | Unix 时间戳（秒） |
| `p` | object | 玩家状态 |
| `w` | object | 世界状态 |
| `e` | array | 附近实体列表 |

### 玩家状态 (p)

| 字段 | 类型 | 说明 | 范围 |
|------|------|------|------|
| `hp` | number | 生命值百分比 | 0-1 |
| `hu` | number | 饥饿值百分比 | 0-1 |
| `sa` | number | 理智值百分比 | 0-1 |
| `x` | number | X 坐标 | 任意 |
| `y` | number | Y 坐标（高度） | 通常为 0 |
| `z` | number | Z 坐标 | 任意 |

### 世界状态 (w)

| 字段 | 类型 | 说明 |
|------|------|------|
| `day` | number | 天数 |
| `time` | number | 当天时间 | 0-1 |
| `season` | string | 季节 | autumn/winter/spring/summer |
| `isDay` | boolean | 是否白天 |
| `isNight` | boolean | 是否夜晚 |
| `isDusk` | boolean | 是否黄昏 |

### 实体列表 (e)

每个实体包含：

| 字段 | 类型 | 说明 |
|------|------|------|
| `p` | string | Prefab 名称 |
| `x` | number | X 坐标 |
| `y` | number | Y 坐标 |
| `z` | number | Z 坐标 |
| `d` | number | 距离玩家距离 |

### 示例代码 (Lua)

```lua
-- 写入状态 (使用官方验证的方式)
function WriteState(state)
    local json = json.encode(state)
    local file = io.open("C:\\dst-ai-sync\\state.txt", "w")
    if file then
        file:write(json)
        file:close()
    end
end

-- 使用
local state = {
    v = 1,
    t = TheNet:GetServerTime() or 0,
    p = {
        hp = ThePlayer.replica.health:GetPercent(),
        hu = ThePlayer.replica.hunger:GetPercent(),
        sa = ThePlayer.replica.sanity:GetPercent(),
        x = x, y = y, z = z
    },
    -- ...
}
WriteState(state)
```

---

## AI 指令 (cmd.txt)

### 文件格式

JSON 格式，单行存储。

### 结构

```json
{
  "v": 1,
  "t": 1234567890,
  "seq": 123,
  "actions": [
    {
      "type": "move",
      "target": {"x": 105, "y": 0, "z": -198}
    }
  ]
}
```

### 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| `v` | number | 协议版本 |
| `t` | number | Unix 时间戳（秒） |
| `seq` | number | 序列号，用于去重 |
| `actions` | array | 动作列表 |

### 动作类型

#### move - 移动

```json
{
  "type": "move",
  "target": {"x": 105, "y": 0, "z": -198}
}
```

#### pickup - 拾取

```json
{
  "type": "pickup",
  "entity": "berrybush",
  "position": {"x": 105, "y": 0, "z": -198}
}
```

#### chop - 砍树

```json
{
  "type": "chop",
  "entity": "evergreen",
  "position": {"x": 100, "y": 0, "z": -200}
}
```

#### mine - 挖矿

```json
{
  "type": "mine",
  "entity": "rock",
  "position": {"x": 100, "y": 0, "z": -200}
}
```

#### attack - 攻击

```json
{
  "type": "attack",
  "entity": "spider",
  "position": {"x": 100, "y": 0, "z": -200}
}
```

#### eat - 进食

```json
{
  "type": "eat",
  "item": "berries"
}
```

#### equip - 装备

```json
{
  "type": "equip",
  "item": "axe",
  "slot": "hands"
}
```

槽位选项: `hands`, `head`, `body`

#### unequip - 卸下

```json
{
  "type": "unequip",
  "slot": "hands"
}
```

#### craft - 制作

```json
{
  "type": "craft",
  "item": "axe"
}
```

#### wait - 等待

```json
{
  "type": "wait",
  "duration": 2.5
}
```

---

## 协议版本

### 版本 1 (当前)

- 基本状态同步
- 基本动作支持
- 简单 JSON 格式

### 版本演进

| 版本 | 变化 |
|------|------|
| 1 | 初始版本 |

---

## 错误处理

### 时间戳检查

游戏 Mod 应检查指令时间戳，忽略过期指令：

```lua
local cmd_time = cmd.t
local current_time = TheNet:GetServerTime() or 0

-- 忽略超过 5 秒的指令
if current_time - cmd_time > 5 then
    print("[AI] Ignoring expired command")
    return
end
```

### 序列号去重

```lua
local last_seq = 0

function ExecuteCommand(cmd)
    if cmd.seq <= last_seq then
        return  -- 已处理过
    end
    last_seq = cmd.seq

    -- 执行动作...
end
```

### 无效数据处理

```lua
-- 检查必需字段
if not cmd.v or not cmd.actions then
    print("[AI] Invalid command format")
    return
end

-- 检查协议版本
if cmd.v ~= PROTOCOL_VERSION then
    print("[AI] Protocol version mismatch")
    return
end
```

---

## 性能考虑

### 写入频率

- **Mod**: 每帧写入 (~16ms 间隔)
- **文件 I/O**: ~3-9ms/次 (官方使用验证)
- **chokidar**: <1ms 延迟

### 数据大小

- 保持 JSON 简洁
- 实体列表限制在 50 个以内
- 使用缩写字段名节省空间

### 缓存

- Mod 可缓存上次写入的内容
- 只在状态变化时写入

---

## 调试

### 查看状态文件

```bash
# PowerShell
Get-Content "C:\dst-ai-sync\state.txt"

# 或
cat "C:\dst-ai-sync\state.txt"
```

### 查看指令文件

```bash
Get-Content "C:\dst-ai-sync\cmd.txt"
```

### JSON 格式化

```bash
# 在线工具
# https://jsonlint.com/

# 或使用 Node.js
echo '{"v":1,"t":123456}' | node -e "console.log(JSON.stringify(JSON.parse(require('fs').readFileSync(0)), null, 2))"
```

---

## 相关文档

- **[系统架构](mod-architecture.md)** - 完整架构说明
- **[API 快速参考](mod-api-reference.md)** - DST API 手册
- **[文件 I/O 指南](client-file-io-guide.md)** - 文件操作详解
