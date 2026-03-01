# DST 游戏脚本参考

本文档总结从 `dst_scripts` 目录中探索到的 Don't Starve Together 游戏核心脚本知识。

---

## 目录

1. [scripts.zip 概述](#scriptszip-概述)
2. [文件 I/O 能力](#文件-io-能力)
3. [网络通信限制](#网络通信限制)
4. [Mod 系统](#mod-系统)
5. [常用 API 参考](#常用-api-参考)
6. [源文件位置索引](#源文件位置索引)

---

## scripts.zip 概述

### 基本信息

- **位置**: `C:\Program Files (x86)\Steam\steamapps\common\Don't Starve Together\data\databundles\scripts.zip`
- **大小**: ~270MB
- **文件数**: 3939 个 Lua 文件
- **用途**: 包含游戏的所有核心脚本逻辑

### 主要目录结构

```
scripts/
├── main.lua              # 游戏入口
├── actions.lua           # 动作定义 (257KB)
├── constants.lua         # 游戏常量
├── entityscript.lua      # 实体基类
├── stategraph.lua        # 状态机
├── components/           # 组件系统 (500+ 组件)
├── prefabs/              # 游戏对象预制体
├── stategraphs/          # 状态图实现
├── brains/               # AI 大脑
├── map/                  # 地图生成
├── widgets/              # UI 组件
└── screens/              # 界面屏幕
```

---

## 文件 I/O 能力

### 可用的文件操作

| 操作 | 函数 | 证据文件 | 行号 |
|------|------|----------|------|
| 读取文件 | `io.open(path, "r")` | class.lua | 136 |
| 写入文件 | `io.open(path, "w")` | createstringspo.lua | 258 |
| 逐行读取 | `file:lines()` | class.lua | 139 |
| 加载脚本 | `loadfile(path)` | dlcsupport.lua | 29 |
| 读取全部 | `file:read("*all")` | 多处使用 | - |

### 官方使用示例

**读取源文件** ([class.lua:136](../../dst_scripts/class.lua#L136)):
```lua
local file = io.open(path, "r")
if file ~= nil then
    for i in file:lines() do
        -- 处理每一行
    end
end
```

**写入翻译文件** ([createstringspo.lua:258](../../dst_scripts/createstringspo.lua#L258)):
```lua
local file = io.open(filename, "w")
file:write("msgid \"\"\n")
file:write("msgstr \"\"\n")
```

**动态加载预制体** ([dlcsupport.lua:29](../../dst_scripts/dlcsupport.lua#L29)):
```lua
local fn, r = loadfile(filename)
assert(fn, "Could not load file ".. filename)
fn()  -- 执行加载的函数
```

### 持久化存储 API

| 函数 | 用途 | 文件 |
|------|------|------|
| `TheSim:CheckPersistentStringExists()` | 检查文件存在 | fileutil.lua:82 |
| `TheSim:SetPersistentString()` | 写入持久化数据 | - |
| `ErasePersistentString()` | 删除持久化数据 | fileutil.lua:38 |

**注意**: 这些是游戏专用的存档 API，不适用于 Mod 与外部程序通信。

---

## 网络通信限制

### 搜索结果分析

| 搜索项 | 匹配数 | 结论 |
|--------|--------|------|
| `socket` | 0 | 无 socket 库 |
| `http\.get` | 0 | 无 HTTP 客户端 |
| `tcp`/`udp` | 0 | 无网络协议支持 |
| `ws://` | 0 | 无 WebSocket |

### Mod RPC 系统

Mod RPC ([networkclientrpc.lua:1664](../../dst_scripts/networkclientrpc.lua#L1664)) **仅用于游戏内通信**：

```lua
function AddModRPCHandler(namespace, name, fn)
    -- 注册 RPC 处理器
    MOD_RPC[namespace] = MOD_RPC[namespace] or {}
    MOD_RPC_HANDLERS[namespace] = MOD_RPC_HANDLERS[namespace] or {}
    -- ...
end

function SendModRPCToServer(id_table, ...)
    -- 发送到游戏服务器
    TheNet:SendModRPCToServer(id_table.namespace, id_table.id, ...)
end
```

**限制**: Mod RPC 无法发送到游戏外部的 Node.js 进程。

### 结论

**文件 I/O 是 Mod 与外部程序通信的唯一可行方式。**

---

## Mod 系统

### Mod 工具函数 ([modutil.lua](../../dst_scripts/modutil.lua))

| 函数 | 说明 |
|------|------|
| `AddModRPCHandler()` | 注册 Mod RPC |
| `AddPlayerPostInit()` | 玩家初始化钩子 |
| `AddPrefabPostInit()` | Prefab 初始化钩子 |
| `AddComponentPostInit()` | 组件初始化钩子 |
| `AddUpdateFunction()` | 每帧更新钩子 |
| `GetModConfigData()` | 获取 Mod 配置 |

### Mod 加载流程

```
mods.lua
    ↓
ModIndex:BeginStartupSequence()
    ↓
加载 modinfo.lua
    ↓
加载 modmain.lua
    ↓
执行 PostInit 函数
```

### Mod 配置 ([modindex.lua](../../dst_scripts/modindex.lua))

```lua
self.savedata = {
    known_mods = {},      -- 已知 Mod
    known_api_version = 0, -- API 版本
    -- ...
}
```

---

## 常用 API 参考

### 全局变量

| 变量 | 类型 | 说明 |
|------|------|------|
| `ThePlayer` | EntityScript | 当前玩家（仅客户端） |
| `TheWorld` | EntityScript | 世界实例 |
| `TheSim` | Simulation | 模拟系统 |
| `TheNet` | Networking | 网络系统 |
| `TheInput` | Input | 输入系统（仅客户端） |

### 玩家组件

| 组件 | 方法 | 说明 |
|------|------|------|
| `health` | `GetPercent()` | 生命值百分比 |
| `hunger` | `GetPercent()` | 饥饿值百分比 |
| `sanity` | `GetPercent()` | 理智值百分比 |
| `locomotor` | `GoToPoint()` | 移动到位置 |
| `inventory` | `FindItem()` | 查找物品 |
| `combat` | `DoAttack()` | 执行攻击 |

### 世界状态

```lua
TheWorld.state.cycles        -- 天数
TheWorld.state.time          -- 时间 (0-1)
TheWorld.state.season        -- 季节
TheWorld.state.isday         -- 是否白天
TheWorld.state.isnight       -- 是否夜晚
```

### 实体查找

```lua
-- 查找范围内实体
local ents = TheSim:FindEntities(x, y, z, radius)

-- 按标签过滤
local ents = TheSim:FindEntities(x, y, z, radius, nil, nil, {"tag"})
```

### 动作系统

```lua
-- 创建动作
local action = BufferedAction(inst, target, ACTIONS.CHOP)
inst.components.locomotor:PushAction(action, true)
```

---

## 源文件位置索引

### 核心系统

| 功能 | 文件 | 关键内容 |
|------|------|----------|
| 游戏入口 | main.lua | 启动流程 |
| 实体系统 | entityscript.lua | EntityScript 类 |
| 状态机 | stategraph.lua | 状态图基类 |
| 动作定义 | actions.lua | ACTIONS 表 |
| 调试命令 | consolecommands.lua | c_* 命令 |

### 组件系统

| 组件 | 文件 | 说明 |
|------|------|------|
| health | components/health.lua | 生命值 |
| hunger | components/hunger.lua | 饥饿值 |
| sanity | components/sanity.lua | 理智值 |
| locomotor | components/locomotor.lua | 移动 |
| inventory | components/inventory.lua | 背包 |
| combat | components/combat.lua | 战斗 |

### Mod 相关

| 功能 | 文件 | 说明 |
|------|------|------|
| Mod 工具 | modutil.lua | Mod 开发函数 |
| Mod 索引 | modindex.lua | Mod 管理 |
| Mod 加载 | mods.lua | Mod 加载流程 |
| Mod RPC | networkclientrpc.lua | RPC 系统 |

### 文件 I/O 证据

| 功能 | 文件 | 行号 |
|------|------|------|
| 读取文件 | class.lua | 136 |
| 写入文件 | createstringspo.lua | 258 |
| 导出数据 | debugcommands.lua | 1439 |
| 加载脚本 | dlcsupport.lua | 29 |
| 持久化 | fileutil.lua | 全文 |

---

## 学习建议

### 查找 API 的方法

1. **确定功能类型**
   - 组件方法 → `components/`
   - 游戏对象 → `prefabs/`
   - AI 逻辑 → `brains/`

2. **搜索关键字**
   ```bash
   # 在 dst_scripts 中搜索
   grep -r "GetPercent" components/
   grep -r "locomotor" components/
   ```

3. **查看示例**
   - 官方预制体是最佳参考
   - `prefabs/wilson.lua` - 玩家实现
   - `prefabs/spider.lua` - 生物 AI

### 推荐阅读顺序

1. `entityscript.lua` - 理解实体基类
2. `components/health.lua` - 理解组件系统
3. `brains/spiderbrain.lua` - 理解 AI
4. `stategraphs/SGwilson.lua` - 理解状态机

---

## 相关文档

- **[API 快速参考](mod-api-reference.md)** - 速查手册
- **[文件 I/O 指南](client-file-io-guide.md)** - 文件操作详解
- **[系统架构](mod-architecture.md)** - 项目架构说明
