# DST Mod 文件 I/O 完全指南

本文档详细说明 DST Mod 中文件读写的所有限制和正确用法。

---

## 核心限制

### 最重要的规则

| 环境 | `io` 可用性 | 说明 |
|------|------------|------|
| **客户端 Mod** (`client_only_mod=true`) | ✅ **可用** | 可以读写文件 |
| **服务器端 Mod** (`client_only_mod=false`) | ❌ **不可用** | `io` 是 `nil` |
| **混合环境** | ⚠️ **需检查** | `AddPlayerPostInit` 在两端执行 |

### 为什么服务器端 `io` 不可用？

```
单人游戏架构：
┌─────────────────┐         ┌─────────────────┐
│   客户端进程    │         │   服务器进程    │
│                 │         │                 │
│  io = ✅ 可用   │         │  io = ❌ nil    │
│  ThePlayer可用  │         │  ThePlayer=nil  │
│  渲染/UI        │         │  游戏逻辑       │
└─────────────────┘         └─────────────────┘
```

---

## 客户端检测

### 必须的检查代码

```lua
-- 方法1: 检查 ThePlayer
local function IsClient()
    return ThePlayer ~= nil
end

-- 方法2: 检查 TheNet
local function IsClient()
    return TheNet and not TheNet:GetIsServer()
end

-- 方法3: 组合检查（推荐）
local function IsClient()
    if ThePlayer then return true end
    if TheNet and not TheNet:GetIsServer() then return true end
    return false
end

-- 使用示例
AddPlayerPostInit(function(player)
    -- 这个钩子在客户端和服务器都会执行！
    if not IsClient() then
        return  -- 跳过服务器端
    end

    -- 安全地使用 io
    local file = io.open("C:\\path\\file.txt", "w")
    -- ...
end)
```

### 为什么需要检查？

```lua
-- 错误示例 - 会崩溃！
AddPlayerPostInit(function(player)
    local file = io.open("test.txt", "w")  -- 服务器端崩溃: io is nil
end)

-- 正确示例 - 安全检查
AddPlayerPostInit(function(player)
    if not IsClient() then return end  -- 跳过服务器端
    local file = io.open("test.txt", "w")  -- 安全
end)
```

---

## 可用的文件操作

### 基本操作

```lua
-- 写文件
local file = io.open("C:\\dst-ai-sync\\output.txt", "w")
if file then
    file:write("Hello DST Mod!\n")
    file:write("Line 2\n")
    file:close()
end

-- 读文件
local file = io.open("C:\\dst-ai-sync\\input.txt", "r")
if file then
    local content = file:read("*all")  -- 读取全部
    -- 或逐行读取
    -- for line in file:lines() do
    --     print(line)
    -- end
    file:close()
end

-- 追加写入
local file = io.open("C:\\dst-ai-sync\\log.txt", "a")
if file then
    file:write(os.date("%Y-%m-%d %H:%M:%S") .. " Log entry\n")
    file:close()
end
```

### 可用的模式

| 模式 | 说明 | 服务器端 |
|------|------|----------|
| `"r"` | 只读 | ❌ |
| `"w"` | 只写（覆盖） | ❌ |
| `"a"` | 追加 | ❌ |
| `"rb"` | 二进制只读 | ❌ |
| `"wb"` | 二进制只写 | ❌ |

---

## 路径限制

### 硬编码要求

```lua
-- ❌ 错误 - 不能使用环境变量
local path = os.getenv("USERPROFILE") .. "\\file.txt"  -- os.getenv 不可用

-- ❌ 错误 - 不能动态构建路径
local base_dir = "%USERPROFILE%\\Documents"
local path = base_dir .. "\\file.txt"

-- ✅ 正确 - 硬编码完整路径
local path = "C:\\Users\\Administrator\\dst-ai-sync\\file.txt"

-- ✅ 正确 - 使用配置目录
local SYNC_DIR = "C:\\dst-ai-sync\\"
local file = io.open(SYNC_DIR .. "state.txt", "r")
```

### 推荐的同步目录

```
C:\dst-ai-sync\
├── state.txt      -- Mod → Node.js (游戏状态)
├── cmd.txt        -- Node.js → Mod (AI指令)
├── config.json    -- 配置文件
└── debug.log      -- 调试日志
```

---

## 不可用的函数

### `os` 模块限制

```lua
-- ❌ 以下都不可用
os.time()        -- 返回 nil
os.date()        -- 返回 nil
os.getenv()      -- 返回 nil
os.execute()     -- 不存在
os.remove()      -- 不存在
os.rename()      -- 不存在
os.tmpname()     -- 不存在
```

### 替代方案

```lua
-- 获取时间 - 使用游戏API
local time = TheNet:GetServerTime() or GetTime()

-- 删除文件 - 使用Lua
os.remove() 不可用，需要用其他方式或避免删除
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
    if not IsClient() then return end

    local file = io.open("C:\\dst-ai-sync\\state.txt", "w")
    if file then
        file:write(json.encode(state))
        file:close()
    end
end

-- 读 JSON 文件
local function ReadCommand()
    if not IsClient() then return nil end

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

## 安全实践

### 1. 总是检查环境

```lua
local function SafeFileWrite(path, content)
    -- 检查是否在客户端
    if not IsClient() then
        print("[Mod] Not on client, skipping file write")
        return false
    end

    -- 检查 io 是否可用
    if not io then
        print("[Mod] io not available")
        return false
    end

    -- 执行写入
    local file = io.open(path, "w")
    if file then
        file:write(content)
        file:close()
        return true
    end

    return false
end
```

### 2. 错误处理

```lua
-- 由于 pcall 不可用，需要手动检查
local function SafeFileRead(path)
    if not IsClient() then return nil end

    local file = io.open(path, "r")
    if not file then
        print("[Mod] Failed to open: " .. path)
        return nil
    end

    local content = file:read("*all")
    file:close()
    return content
end
```

### 3. 文件锁定处理

```lua
-- 简单的"先读后删"模式（如果对方遵循约定）
local function ReadAndClear(path)
    if not IsClient() then return nil end

    -- 读取
    local file = io.open(path, "r")
    if not file then return nil end

    local content = file:read("*all")
    file:close()

    -- 清空（写入空内容）
    file = io.open(path, "w")
    if file then
        file:write("")
        file:close()
    end

    return content
end
```

---

## 完整示例：状态同步系统

```lua
-- dst-ai-mod/modmain.lua

local SYNC_DIR = "C:\\dst-ai-sync\\"
local STATE_FILE = SYNC_DIR .. "state.txt"
local CMD_FILE = SYNC_DIR .. "cmd.txt"

-- 客户端检测
local function IsClient()
    return ThePlayer ~= nil or (TheNet and not TheNet:GetIsServer())
end

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
            x = x,
            y = y,
            z = z
        },
        w = {
            day = TheWorld.state.cycles,
            isDay = TheWorld.state.isday
        }
    }
end

-- 写入状态文件
local function WriteState()
    if not IsClient() then return end

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
    if not IsClient() then return nil end

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

-- 定期更新状态
AddPlayerPostInit(function(player)
    player:DoTaskInTime(0, function()
        if not IsClient() then return end

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

### 1. 验证 io 可用性

```lua
print("[Debug] io exists: " .. tostring(io ~= nil))
print("[Debug] io.open exists: " .. tostring(io and io.open ~= nil))
print("[Debug] IsClient: " .. tostring(IsClient()))
```

### 2. 测试文件写入

```lua
AddPlayerPostInit(function(player)
    player:DoTaskInTime(2, function()
        if not IsClient() then
            print("[Debug] Skipping - not client")
            return
        end

        print("[Debug] Writing test file...")
        local file = io.open("C:\\dst-ai-sync\\test.txt", "w")
        print("[Debug] io.open result: " .. tostring(file))

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

### 3. 验证文件内容

```lua
-- 写入后立即读取验证
local file = io.open("C:\\dst-ai-sync\\test.txt", "r")
if file then
    local content = file:read("*all")
    print("[Debug] File content: " .. content)
    file:close()
end
```

---

## 常见错误

### 错误 1: `attempt to index global 'io' (a nil value)`

```
原因: 在服务器端执行了 io 操作
解决: 添加 IsClient() 检查
```

### 错误 2: 文件写入成功但读取为空

```
原因: 服务器端跳过了写入，客户端读取时文件不存在
解决: 确保只在客户端执行文件操作
```

### 错误 3: 路径问题

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

## 总结

| 事项 | 状态 |
|------|------|
| 客户端 `io` 可用 | ✅ |
| 服务器端 `io` 可用 | ❌ |
| `AddPlayerPostInit` 在两端执行 | ⚠️ 需检查 |
| 必须硬编码路径 | ✅ |
| `os` 模块基本不可用 | ❌ |
| `json.encode/decode` | ✅ |
| `pcall` 不可用 | ❌ |

**记住**: 总是先检查 `IsClient()` 再使用 `io` 操作！
