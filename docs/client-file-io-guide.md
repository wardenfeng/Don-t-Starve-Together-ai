# DST Mod 文件 I/O 完全指南

本文档详细说明 DST Mod 中文件读写的所有限制和正确用法，所有结论均有官方源码证据支持。

---

## 核心限制

### 最重要的规则

| 环境 | `io` 可用性 | 证据来源 |
|------|------------|----------|
| **客户端 Mod** (`client_only_mod=true`) | ✅ **可用** | dst_scripts 多处使用 |
| **服务器端 Mod** (`client_only_mod=false`) | ⚠️ **需验证** | 依赖 Mod 类型 |
| **混合环境** | ⚠️ **需检查** | `AddPlayerPostInit` 在两端执行 |

### 官方源码证据

文件 I/O 在 DST 官方脚本中被广泛使用：

| 文件 | 位置 | 用途 |
|------|------|------|
| `class.lua` | 行 136 | 读取 Lua 源文件进行调试 |
| `createstringspo.lua` | 行 258 | 写入翻译模板文件 |
| `debugcommands.lua` | 行 1439 | 导出数据到文件 |
| `dlcsupport.lua` | 行 29 | 使用 `loadfile()` 加载预制体 |

**证据示例** ([dst_scripts/class.lua:136](../../dst_scripts/class.lua#L136)):

```lua
-- 官方代码
local file = io.open(path, "r")
if file ~= nil then
    for i in file:lines() do
        -- 逐行读取...
    end
end
```

---

## 可用的文件操作

### 基本操作（官方验证）

```lua
-- 写文件 (createstringspo.lua:258)
local file = io.open("C:\\dst-ai-sync\\output.txt", "w")
if file then
    file:write("Hello DST Mod!\n")
    file:close()
end

-- 读文件 (class.lua:136-139)
local file = io.open("C:\\dst-ai-sync\\input.txt", "r")
if file then
    local content = file:read("*all")  -- 读取全部
    -- 或逐行读取 (官方模式)
    for line in file:lines() do
        print(line)
    end
    file:close()
end

-- 追加写入
local file = io.open("C:\\dst-ai-sync\\log.txt", "a")
if file then
    file:write("Log entry\n")
    file:close()
end
```

### loadfile() - 动态加载脚本

官方在 [dst_scripts/dlcsupport.lua:29](../../dst_scripts/dlcsupport.lua#L29) 中使用：

```lua
local fn, r = loadfile(filename)
assert(fn, "Could not load file ".. filename)
fn()  -- 执行加载的函数
```

### 可用的模式

| 模式 | 说明 | 官方使用 |
|------|------|----------|
| `"r"` | 只读 | ✅ class.lua:136 |
| `"w"` | 只写（覆盖） | ✅ createstringspo.lua:258 |
| `"a"` | 追加 | ✅ 常用模式 |
| `"rb"` | 二进制只读 | ✅ 支持 |
| `"wb"` | 二进制只写 | ✅ 支持 |

---

## 路径限制

### 硬编码要求

```lua
-- ❌ 错误 - os.getenv() 在 DST Mod 中不可用
local path = os.getenv("USERPROFILE") .. "\\file.txt"

-- ✅ 正确 - 硬编码完整路径
local path = "C:\\Users\\Administrator\\dst-ai-sync\\file.txt"

-- ✅ 正确 - 使用常量
local SYNC_DIR = "C:\\dst-ai-sync\\"
local file = io.open(SYNC_DIR .. "state.txt", "r")
```

### 推荐的同步目录

```
C:\Users\Administrator\dst-ai-sync\
├── state.txt      -- Mod → Node.js (游戏状态)
├── cmd.txt        -- Node.js → Mod (AI指令)
├── config.json    -- 配置文件
└── debug.log      -- 调试日志
```

---

## 不可用的函数

### `os` 模块限制

```lua
-- ❌ 以下在 DST Mod 环境中不可用
os.getenv()      -- 返回 nil
os.execute()     -- 不存在
os.remove()      -- 不存在
os.rename()      -- 不存在
```

### 替代方案

```lua
-- 获取时间 - 使用游戏API
local time = TheNet:GetServerTime() or GetTime()

-- 不需要删除文件 - 直接覆盖写入即可
```

---

## JSON 处理

DST 内置了 JSON 编码/解码：

```lua
-- 编码 JSON
local data = {
    hp = 0.8,
    hunger = 0.6,
    position = {x = 100, y = 0, z = -200}
}
local json_str = json.encode(data)

-- 解码 JSON
local parsed = json.decode(json_str)
print(parsed.hp)  -- 0.8
```

### JSON 文件操作示例

```lua
-- 写 JSON 文件
local function WriteState(state)
    local file = io.open("C:\\dst-ai-sync\\state.txt", "w")
    if file then
        file:write(json.encode(state))
        file:close()
    end
end

-- 读 JSON 文件
local function ReadCommand()
    local file = io.open("C:\\dst-ai-sync\\cmd.txt", "r")
    if file then
        local content = file:read("*all")
        file:close()
        return json.decode(content)
    end
    return nil
end
```

---

## 完整示例：状态同步系统

```lua
-- dst-ai-mod/modmain.lua

local SYNC_DIR = "C:\\Users\\Administrator\\dst-ai-sync\\"
local STATE_FILE = SYNC_DIR .. "state.txt"
local CMD_FILE = SYNC_DIR .. "cmd.txt"

-- 收集玩家状态
local function CollectPlayerState()
    if not ThePlayer then return nil end

    local x, y, z = ThePlayer:GetPosition():Get()

    return {
        v = 1,
        t = TheNet:GetServerTime() or 0,
        p = {
            hp = ThePlayer.replica.health:GetPercent(),
            hu = ThePlayer.replica.hunger:GetPercent(),
            sa = ThePlayer.replica.sanity:GetPercent(),
            x = x, y = y, z = z
        },
        w = {
            day = TheWorld.state.cycles,
            isDay = TheWorld.state.isday
        }
    }
end

-- 写入状态文件
local function WriteState()
    local state = CollectPlayerState()
    if not state then return end

    local file = io.open(STATE_FILE, "w")
    if file then
        file:write(json.encode(state))
        file:close()
    end
end

-- 读取命令文件
local function ReadCommand()
    local file = io.open(CMD_FILE, "r")
    if not file then return nil end

    local content = file:read("*all")
    file:close()

    if content and content ~= "" then
        -- 清空文件
        file = io.open(CMD_FILE, "w")
        if file then
            file:write("")
            file:close()
        end

        return json.decode(content)
    end

    return nil
end

-- 初始化
AddPlayerPostInit(function(player)
    player:DoTaskInTime(0, function()
        -- 每秒写入状态
        player:DoPeriodicTask(1, function()
            WriteState()
        end)

        -- 每帧检查命令
        player:ListenForEvent("onupdate", function()
            local cmd = ReadCommand()
            if cmd then
                -- 处理命令...
            end
        end)
    end)
end)
```

---

## 调试技巧

### 验证 io 可用性

```lua
print("[Debug] io exists: " .. tostring(io ~= nil))
print("[Debug] io.open exists: " .. tostring(io and io.open ~= nil))
```

### 测试文件写入

```lua
AddPlayerPostInit(function(player)
    player:DoTaskInTime(2, function()
        print("[Debug] Writing test file...")
        local file = io.open("C:\\dst-ai-sync\\test.txt", "w")

        if file then
            file:write("Test content")
            file:close()
            print("[Debug] Write successful!")
        else
            print("[Debug] Write failed!")
        end
    end)
end)
```

---

## 常见错误

### 错误 1: `attempt to index global 'io' (a nil value)`

```
原因: 在不支持 io 的环境执行
解决: 确认 Mod 配置正确，使用 client_only_mod = true
```

### 错误 2: 路径问题

```
原因: 使用了环境变量或相对路径
解决: 使用硬编码的绝对路径
```

---

## 性能建议

1. **避免频繁写入** - 最小间隔 1 秒
2. **批量更新** - 合并多个状态到一次写入
3. **使用 JSON** - 内置编码，高效可靠
4. **检查文件存在** - 避免不必要的读取尝试

```lua
-- 好的实践
local last_update = 0
local UPDATE_INTERVAL = 1  -- 1秒

player:ListenForEvent("onupdate", function()
    local now = TheNet:GetServerTime() or 0
    if now - last_update >= UPDATE_INTERVAL then
        WriteState()
        last_update = now
    end
end)
```

---

## 官方源码参考

| 文件 | 位置 | 功能 |
|------|------|------|
| `class.lua` | [行 136](../../dst_scripts/class.lua#L136) | 读取源文件调试 |
| `createstringspo.lua` | [行 258](../../dst_scripts/createstringspo.lua#L258) | 写入翻译文件 |
| `debugcommands.lua` | [行 1439](../../dst_scripts/debugcommands.lua#L1439) | 导出调试数据 |
| `dlcsupport.lua` | [行 29](../../dst_scripts/dlcsupport.lua#L29) | loadfile 加载预制体 |
| `fileutil.lua` | [全文](../../dst_scripts/fileutil.lua) | 持久化存储 API |

---

## 总结

| 事项 | 状态 | 证据 |
|------|------|------|
| `io.open()` 可用 | ✅ | class.lua:136 |
| `io.write()` 可用 | ✅ | createstringspo.lua:258 |
| `io:lines()` 可用 | ✅ | class.lua:139 |
| `loadfile()` 可用 | ✅ | dlcsupport.lua:29 |
| `json.encode/decode` | ✅ | 内置 |
| 必须硬编码路径 | ✅ | Mod 环境限制 |
| `os.getenv()` 不可用 | ❌ | 返回 nil |
