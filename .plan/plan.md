# DST AI 玩家系统 - 文件共享方案

## Context
创建一个让AI自动玩饥荒联机版游戏的系统。采用**文件共享通信**架构：Lua Mod通过文件I/O与Node.js AI服务器通信，调用Claude API进行智能决策。无需DLL注入，无需C++编译，纯实现。

---

## 系统架构

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                   游戏电脑                                      │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                          DST 游戏进程                                     │   │
│  │                                                                          │   │
│  │  ┌────────────────────────────────────────────────────────────────┐    │   │
│  │  │                       Lua AI Mod                               │    │   │
│  │  │                                                                │    │   │
│  │  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐     │    │   │
│  │  │  │ 状态采集器    │  │ 动作执行器    │  │ 文件通信层       │     │    │   │
│  │  │  │              │  │              │  │                  │     │    │   │
│  │  │  │ - 玩家状态   │  │ - 移动       │  │ - 写入 state.txt  │     │    │   │
│  │  │  │ - 周围实体   │  │ - 采集       │  │ - 读取 cmd.txt    │     │    │   │
│  │  │  │ - 世界信息   │  │ - 战斗       │  │ - 轮询检测       │     │    │   │
│  │  │  └──────────────┘  └──────────────┘  └──────────────────┘     │    │   │
│  │  └────────────────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                    ↕ 文件读写                                  │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                         同步目录 (C:\dst-ai-sync\)                         │   │
│  │                                                                          │   │
│  │  state.txt  ←── 游戏写入 (状态)                                          │   │
│  │  cmd.txt    ←── 服务器写入 (命令)                                        │   │
│  │  status.txt ←── 服务器写入 (连接状态)                                    │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘
                                    ↕
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              Node.js AI 服务器                                  │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                              文件监听层                                   │   │
│  │  - 监听 state.txt 变化                                                 │   │
│  │  - 触发 AI 决策                                                        │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                              AI 决策层                                    │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐         │   │
│  │  │ 状态解析     │  │Claude API   │  │ 决策输出               │         │   │
│  │  │             │→ │             │→ │                         │         │   │
│  │  │ 缓存历史     │  │智能决策     │  │ 写入 cmd.txt          │         │   │
│  │  └─────────────┘  └─────────────┘  └─────────────────────────┘         │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 项目目录结构

```
Don't Starve Together ai/
│
├── dst-ai-mod/                    # Lua Mod (放入游戏mods目录)
│   ├── modinfo.lua                # Mod配置
│   ├── modmain.lua                # 入口文件
│   └── scripts/
│       ├── ai/
│       │   ├── core/
│       │   │   ├── controller.lua      # AI主控制器
│       │   │   ├── state_collector.lua # 状态采集
│       │   │   └── action_executor.lua # 动作执行
│       │   ├── communication/
│       │   │   ├── file_bridge.lua      # 文件通信桥接
│       │   │   └── protocol.lua         # 通信协议定义
│       │   └── utils/
│       │       └── text_serializer.lua  # 文本序列化工具
│       │
└── dst-ai-server/                 # Node.js AI服务器
    ├── package.json
    ├── tsconfig.json
    ├── .env.example                # 环境变量模板
    └── src/
        ├── main.ts                  # 程序入口
        ├── config/
        │   └── config.ts             # 配置管理
        ├── communication/
        │   ├── file-watcher.ts       # 文件监听器
        │   └── protocol.ts           # 通信协议
        ├── ai/
        │   ├── claude/
        │   │   ├── client.ts          # Claude API客户端
        │   │   └── prompt.ts          # 提示词模板
        │   ├── decision/
        │   │   ├── engine.ts          # 决策引擎
        │   │   └── context.ts          # 上下文管理
        │   └── state/
        │       └── manager.ts         # 状态管理器
        └── types/
            └── index.ts               # 类型定义
```

---

## 通信协议设计

### 协议原则

1. **简单文本格式** - 易于调试，JSON解析开销
2. **增量更新** - 只发送变化的数据
3. **轻量级** - 最小化文件大小
4. **容错性** - 部分数据缺失不崩溃

### 文件定义

#### 1. state.txt (游戏 → AI服务器)

```
格式：JSON (单行，便于快速读写)

{
  "v": 1,                    // 协议版本
  "t": 1234567890,           // 时间戳
  "p": {                     // 玩家状态
    "hp": 0.8,               // 生命值 (0-1)
    "hu": 0.6,               // 饥饿值 (0-1)
    "sa": 0.9,               // 理智值 (0-1)
    "pos": [100.5, 0, -200.3] // 位置 [x, y, z]
  },
  "w": {                     // 世界状态
    "day": 5,                // 天数
    "time": 0.5,             // 时间 (0-1)
    "season": "summer",      // 季节
    "isDay": true            // 是否白天
  },
  "e": [                     // 附近实体 (最多20个)
    {"p": "berrybush", "pos": [105, 0, -198], "d": 5.2},
    {"p": "carrot", "pos": [102, 0, -201], "d": 3.1}
  ],
  "inv": [                   // 背包物品 (槽位:数量)
    {"s": 1, "item": "flint", "n": 2},
    {"s": 2, "item": "twigs", "n": 5}
  ]
}
```

#### 2. cmd.txt (AI服务器 → 游戏)

```
格式：JSON (单行)

{
  "v": 1,                    // 协议版本
  "t": 1234567890,           // 时间戳
  "seq": 123,                // 序列号 (防重复执行)
  "actions": [               // 动作队列
    {"type": "move", "target": [105, 0, -198]},
    {"type": "pickup", "entity": "berrybush_105_-198"}
  ]
}
```

#### 3. status.txt (AI服务器 → 游戏，心跳)

```
格式：纯文本

CONNECTED
或
DISCONNECTED
```

---

## 核心模块设计

### 1. 文件通信桥接 (Lua)

**文件**: `dst-ai-mod/scripts/ai/communication/file_bridge.lua`

```lua
-- 文件通信桥接模块
-- 负责与外部AI服务器的文件通信

local FileBridge = Class(function(self, inst, config)
    self.inst = inst
    self.sync_dir = config.sync_dir or "C:\\\\dst-ai-sync\\\\"

    -- 文件路径
    self.files = {
        state_out = self.sync_dir .. "state.txt",
        cmd_in = self.sync_dir .. "cmd.txt",
        status_in = self.sync_dir .. "status.txt"
    }

    -- 状态
    self.last_cmd_seq = -1      -- 上次执行的命令序列号
    self.last_write_time = 0     -- 上次写入时间
    self.write_interval = 0.2    -- 写入间隔 (秒)
    self.is_connected = false    -- 服务器连接状态

    -- 创建同步目录
    self:EnsureSyncDirectory()
end)

-- 确保同步目录存在
function FileBridge:EnsureSyncDirectory()
    -- DST的io.open不能创建目录，需要预先存在
    -- 如果目录不存在，记录错误
    local test_file = io.open(self.files.state_out, "r")
    if test_file then
        test_file:close()
        self.is_connected = true
    else
        print("[DST AI] Warning: Sync directory not found: " .. self.sync_dir)
        print("[DST AI] Please create the directory first")
        self.is_connected = false
    end
end

-- 写入状态文件
function FileBridge:WriteState(state_data)
    local current_time = GetTime()

    -- 限制写入频率
    if current_time - self.last_write_time < self.write_interval then
        return false
    end
    self.last_write_time = current_time

    -- 序列化状态
    local json_str = self:SerializeState(state_data)

    -- 写入文件
    local file = io.open(self.files.state_out, "w")
    if not file then
        return false
    end

    file:write(json_str)
    file:close()

    return true
end

-- 读取命令文件
function FileBridge:ReadCommand()
    -- 检查连接状态
    self:CheckConnection()
    if not self.is_connected then
        return nil
    end

    local file = io.open(self.files.cmd_in, "r")
    if not file then
        return nil
    end

    local content = file:read("*all")
    file:close()

    if not content or content == "" then
        return nil
    end

    -- 解析命令
    local success, cmd = pcall(function()
        return self:DeserializeCommand(content)
    end)

    if success and cmd then
        -- 检查序列号，避免重复执行
        if cmd.seq and cmd.seq <= self.last_cmd_seq then
            return nil  -- 已执行过
        end

        if cmd.seq then
            self.last_cmd_seq = cmd.seq
        end

        return cmd
    end

    return nil
end

-- 检查服务器连接状态
function FileBridge:CheckConnection()
    local file = io.open(self.files.status_in, "r")
    if not file then
        self.is_connected = false
        return
    end

    local status = file:read("*all")
    file:close()

    self.is_connected = (status == "CONNECTED")
end

-- 序列化状态 (简化JSON)
function FileBridge:SerializeState(state)
    -- 手动构建JSON字符串
    local parts = {}

    -- 基本信息
    table.insert(parts, "\"v\":1")
    table.insert(parts, "\"t\":" .. GetTimeRealMS())

    -- 玩家状态
    table.insert(parts, "\"p\":{")
    table.insert(parts, "\"hp\":" .. math.floor(state.player.health * 100) / 100)
    table.insert(parts, ",\"hu\":" .. math.floor(state.player.hunger * 100) / 100)
    table.insert(parts, ",\"sa\":" .. math.floor(state.player.sanity * 100) / 100)
    table.insert(parts, ",\"pos\":[" .. state.player.position.x .. ",0," .. state.player.position.z .. "]")
    table.insert(parts, "}")

    -- 世界状态
    table.insert(parts, "\"w\":{")
    table.insert(parts, "\"day\":" .. (state.world.day or 0))
    table.insert(parts, ",\"time\":" .. math.floor((state.world.time or 0) * 100) / 100)
    table.insert(parts, ",\"season\":\"" .. (state.world.season or "unknown") .. "\"")
    table.insert(parts, ",\"isDay\":" .. tostring(state.world.isday))
    table.insert(parts, "}")

    return "{" .. table.concat(parts, ",") .. "}"
end

-- 反序列化命令 (简化JSON解析)
function FileBridge:DeserializeCommand(json_str)
    -- 使用DST内置的lume.jsondecode (如果可用)
    if lume and lume.jsondecode then
        return lume.jsondecode(json_str)
    end

    -- 简单的JSON解析 (只解析我们需要的字段)
    local cmd = {
        actions = {},
        seq = nil
    }

    -- 提取序列号
    local seq_match = json_str:match('"seq"%s*:%s*(%d+)')
    if seq_match then
        cmd.seq = tonumber(seq_match)
    end

    -- 提取动作
    local actions_start = json_str:match('"actions"%s*:%s*%[')
    if actions_start then
        -- 简单解析动作列表
        for action_str in json_str:gmatch('{([^}]*)}') do
            local action = self:ParseAction(action_str)
            if action then
                table.insert(cmd.actions, action)
            end
        end
    end

    return cmd
end

-- 解析单个动作
function FileBridge:ParseAction(action_str)
    local type_match = action_str:match('"type"%s*:%s*"([^"]*)"')
    if not type_match then
        return nil
    end

    local action = {
        type = type_match
    }

    -- 解析目标位置
    if type_match == "move" then
        local target_str = action_str:match('"target"%s*:%s*%[([%d%.%-]+)%s*,%s*([%d%.%-]+)%s*,%s*([%d%.%-]+)')
        if target_str then
            action.target = {
                x = tonumber(target_str),
                y = tonumber(action_str:match(',%s*([%d%.%-]+)', 4)) or 0,
                z = tonumber(action_str:match(',%s*([%d%.%-]+)', 5))
            }
        end
    end

    -- 解析实体引用
    local entity = action_str:match('"entity"%s*:%s*"([^"]*)"')
    if entity then
        action.entity = entity
    end

    return action
end

return FileBridge
```

### 2. AI主控制器 (Lua)

**文件**: `dst-ai-mod/scripts/ai/core/controller.lua`

```lua
-- AI主控制器
-- 协调状态采集、通信和动作执行

local FileBridge = require("ai/communication/file_bridge")
local StateCollector = require("ai/core/state_collector")
local ActionExecutor = require("ai/core/action_executor")

local AIController = Class(function(self, inst, config)
    self.inst = inst
    self.config = config or {}

    -- 初始化组件
    self.file_bridge = FileBridge(inst, config)
    self.state_collector = StateCollector(inst)
    self.action_executor = ActionExecutor(inst)

    -- 控制状态
    self.enabled = false
    self.update_interval = self.config.update_interval or 10  -- 帧间隔
    self.frame_count = 0

    -- 统计信息
    self.stats = {
        cycles = 0,
        actions_executed = 0,
        errors = 0
    }
end)

-- 启用AI控制器
function AIController:Enable()
    self.enabled = true
    self.frame_count = 0

    -- 监听游戏更新事件
    self.inst:ListenForEvent("onupdate", function()
        if self.enabled then
            self:OnUpdate()
        end
    end)

    print("[DST AI] ========== Controller Enabled ==========")
    print("[DST AI] Update Interval: " .. self.update_interval .. " frames")
    print("[DST AI] Sync Directory: " .. self.file_bridge.sync_dir)
end)

-- 禁用AI控制器
function AIController:Disable()
    self.enabled = false
    print("[DST AI] Controller Disabled")
end)

-- 游戏更新回调
function AIController:OnUpdate()
    self.frame_count = self.frame_count + 1

    -- 控制更新频率
    if self.frame_count < self.update_interval then
        return
    end
    self.frame_count = 0

    -- 执行AI循环
    self:AICycle()
end

-- AI主循环
function AIController:AICycle()
    self.stats.cycles = self.stats.cycles + 1

    -- 1. 采集游戏状态
    local state = self.state_collector:CollectState()
    if not state then
        return
    end

    -- 2. 通过文件发送状态
    local written = self.file_bridge:WriteState(state)
    if not written then
        return
    end

    -- 3. 读取AI命令
    local cmd = self.file_bridge:ReadCommand()
    if not cmd then
        return
    end

    -- 4. 执行动作
    if cmd.actions and #cmd.actions > 0 then
        for _, action in ipairs(cmd.actions) do
            self:ExecuteAction(action)
        end
    end
end

-- 执行单个动作
function AIController:ExecuteAction(action)
    local success, err = pcall(function()
        return self.action_executor:Execute(action)
    end)

    if success then
        self.stats.actions_executed = self.stats.actions_executed + 1
    else
        self.stats.errors = self.stats.errors + 1
        print("[DST AI] Action error: " .. tostring(err))
    end
end

-- 获取统计信息
function AIController:GetStats()
    return self.stats
end

-- 重置统计
function AIController:ResetStats()
    self.stats = {
        cycles = 0,
        actions_executed = 0,
        errors = 0
    }
end

return AIController
```

### 3. 状态采集器 (Lua)

**文件**: `dst-ai-mod/scripts/ai/core/state_collector.lua`

```lua
-- 状态采集器
-- 负责从游戏中采集AI需要的所有状态信息

local StateCollector = Class(function(self, inst)
    self.inst = inst

    -- 缓存配置
    self.scan_radius = 20        -- 扫描周围实体的半径
    self.max_entities = 15        -- 最多采集实体数量
end)

-- 采集完整游戏状态
function StateCollector:CollectState()
    local player = self.inst

    -- 采集玩家状态
    local player_state = self:CollectPlayerState(player)
    if not player_state then
        return nil
    end

    -- 采集世界状态
    local world_state = self:CollectWorldState()

    -- 采集附近实体
    local entities = self:CollectNearbyEntities(player)

    -- 采集背包物品
    local inventory = self:CollectInventory(player)

    return {
        player = player_state,
        world = world_state,
        entities = entities,
        inventory = inventory
    }
end

-- 采集玩家状态
function StateCollector:CollectPlayerState(player)
    -- 检查玩家是否有效
    if not player or not player:IsValid() then
        return nil
    end

    -- 获取位置
    local x, y, z = player.Transform:GetWorldPosition()

    -- 获取状态
    local state = {
        position = {
            x = math.floor(x * 10) / 10,  -- 保留1位小数
            y = math.floor(y * 10) / 10,
            z = math.floor(z * 10) / 10
        },
        health = 1.0,
        hunger = 1.0,
        sanity = 1.0
    }

    -- 生命值
    if player.components.health then
        state.health = player.components.health:GetPercent()
    end

    -- 饥饿值
    if player.components.hunger then
        state.hunger = player.components.hunger:GetPercent()
    end

    -- 理智值
    if player.components.sanity then
        state.sanity = player.components.sanity:GetPercent()
    end

    -- 当前动作 (如果有)
    if player.bufferedaction then
        state.current_action = player.bufferedaction.action.id
    end

    return state
end

-- 采集世界状态
function StateCollector:CollectWorldState()
    local world = TheWorld
    if not world then
        return {}
    end

    local state = world.state or {}

    return {
        day = state.cycles or 0,
        time = state.time or 0,
        season = state.season or "unknown",
        isday = state.isday or false,
        isnight = state.isnight or false,
        isdusk = state.isdusk or false,
        moonphase = state.moonphase or 0
    }
end

-- 采集附近实体
function StateCollector:CollectNearbyEntities(player)
    local entities = {}

    local x, y, z = player.Transform:GetWorldPosition()

    -- 使用游戏内置的实体查找
    local ents = TheSim:FindEntities(x, y, z, self.scan_radius)

    local count = 0
    for _, ent in ipairs(ents) do
        if count >= self.max_entities then
            break
        end

        -- 跳过玩家自己
        if ent ~= player and ent.entity and ent.entity:IsVisible() then
            local entity_info = self:CollectEntityInfo(ent, player)
            if entity_info then
                table.insert(entities, entity_info)
                count = count + 1
            end
        end
    end

    return entities
end)

-- 采集单个实体信息
function StateCollector:CollectEntityInfo(ent, player)
    local px, py, pz = player.Transform:GetWorldPosition()
    local ex, ey, ez = ent.Transform:GetWorldPosition()

    -- 计算距离
    local distance = math.sqrt((ex - px)^2 + (ez - pz)^2)

    local info = {
        prefab = ent.prefab or "unknown",
        position = {
            x = math.floor(ex * 10) / 10,
            y = math.floor(ey * 10) / 10,
            z = math.floor(ez * 10) / 10
        },
        distance = math.floor(distance * 10) / 10
    }

    -- 收集标签 (用于判断实体类型)
    local tags = ent:GetTags()
    if tags then
        local relevant_tags = {}
        for _, tag in ipairs(tags) do
            -- 只收集有用的标签
            if tag:sub(1, 2) ~= "_" then  -- 跳过内部标签
                table.insert(relevant_tags, tag)
            end
        end
        info.tags = relevant_tags
    end

    -- 特殊处理：采集类资源
    if ent.components.pickable then
        info.can_pick = true
        info.product = ent.components.pickable.product
    end

    -- 特殊处理：可砍伐
    if ent.components.workable then
        info.can_work = true
        info.work_action = ent.components.workable.action
    end

    -- 特殊处理：可攻击
    if ent.components.health and ent.components.combat then
        info.can_attack = true
        info.hostile = true
    end

    return info
end)

-- 采集背包物品
function StateCollector:CollectInventory(player)
    local inventory = {}

    if player.components.inventory then
        local items = player.components.inventory:GetItems()
        for _, item in ipairs(items) do
            table.insert(inventory, {
                slot = item.components.inventoryitem and item.components.inventoryitem:GetSlotNum(),
                prefab = item.prefab,
                stack = item.components.stackable and item.components.stackable:StackSize() or 1
            })
        end
    end

    -- 装备栏
    if player.components.inventory and player.components.inventory:GetEquippedItem() then
        local equipped = player.components.inventory:GetEquippedItem()
        inventory.equipped = {
            prefab = equipped.prefab
        }
    end

    return inventory
end

return StateCollector
```

### 4. 动作执行器 (Lua)

**文件**: `dst-ai-mod/scripts/ai/core/action_executor.lua`

```lua
-- 动作执行器
-- 负责执行AI决策的动作指令

local ActionExecutor = Class(function(self, inst)
    self.inst = inst

    -- 动作配置
    self.action_timeout = 5       -- 动作超时时间 (秒)
    self.current_action = nil     -- 当前执行的动作
end)

-- 执行动作
function ActionExecutor:Execute(action)
    if not action or not action.type then
        return false
    end

    -- 根据动作类型分发
    local handlers = {
        move = self.DoMove,
        walk = self.DoMove,
        pickup = self.DoPickup,
        chop = self.DoChop,
        mine = self.DoMine,
        attack = self.DoAttack,
        eat = self.DoEat,
        equip = self.DoEquip,
        wait = self.DoWait
    }

    local handler = handlers[action.type]
    if handler then
        return handler(self, action)
    end

    print("[DST AI] Unknown action type: " .. action.type)
    return false
end)

-- 移动动作
function ActionExecutor:DoMove(action)
    if not action.target then
        return false
    end

    local player = self.inst
    if not player.components.locomotor then
        return false
    end

    local target = Point(action.target.x, action.target.y or 0, action.target.z)
    player.components.locomotor:GoToPoint(target)

    return true
end)

-- 采集动作
function ActionExecutor:DoPickup(action)
    local player = self.inst

    -- 查找目标实体
    local target = self:FindEntityByRef(action.entity, action.target)
    if not target then
        return false
    end

    -- 执行采集
    if player.components.inventory then
        -- 使用BufferAction执行采集
        local bufferedaction = BufferedAction(player, target, ACTIONS.PICKUP)
        if bufferedaction then
            player.components.locomotor:PushAction(bufferedaction, true)
            return true
        end
    end

    return false
end)

-- 砍伐动作
function ActionExecutor:DoChop(action)
    local player = self.inst
    local target = self:FindEntityByRef(action.entity, action.target)

    if not target or not target.components.workable then
        return false
    end

    local bufferedaction = BufferedAction(player, target, ACTIONS.CHOP)
    if bufferedaction then
        player.components.locomotor:PushAction(bufferedaction, true)
        return true
    end

    return false
end

-- 挖掘动作
function ActionExecutor:DoMine(action)
    local player = self.inst
    local target = self:FindEntityByRef(action.entity, action.target)

    if not target or not target.components.workable then
        return false
    end

    local bufferedaction = BufferedAction(player, target, ACTIONS.MINE)
    if bufferedaction then
        player.components.locomotor:PushAction(bufferedaction, true)
        return true
    end

    return false
end)

-- 攻击动作
function ActionExecutor:DoAttack(action)
    local player = self.inst
    local target = self:FindEntityByRef(action.entity, action.target)

    if not target or not player.components.combat then
        return false
    end

    player.components.combat:StartAttack(target)
    return true
end

-- 进食动作
function ActionExecutor:DoEat(action)
    local player = self.inst
    local target = self:FindEntityByRef(action.item, action.target)

    if not target or not player.components.eater then
        return false
    end

    player.components.eater:Eat(target)
    return true
end

-- 装备动作
function ActionExecutor:DoEquip(action)
    local player = self.inst
    if not player.components.inventory then
        return false
    end

    -- 在背包中查找物品
    local item = self:FindItemInInventory(action.item)
    if item then
        player.components.inventory:Equip(item)
        return true
    end

    return false
end

-- 等待动作
function ActionExecutor:DoWait(action)
    -- 不做任何事
    return true
end)

-- 根据引用查找实体
function ActionExecutor:FindEntityByRef(ref, position)
    if not ref and not position then
        return nil
    end

    local player = self.inst
    local px, py, pz = player.Transform:GetWorldPosition()

    -- 如果有位置，优先按位置查找
    if position then
        local ents = TheSim:FindEntities(position.x, position.y or 0, position.z, 3)
        for _, ent in ipairs(ents) do
            if ent ~= player and ent.entity and ent.entity:IsVisible() then
                -- 验证prefab是否匹配
                if not ref or ent.prefab == ref then
                    return ent
                end
            end
        end
    end

    -- 如果有ref，按prefab查找最近的
    if ref then
        local prefab_name = ref:match("^[^_]+")  -- 提取prefab名称
        local ents = TheSim:FindEntities(px, py, pz, 10)
        for _, ent in ipairs(ents) do
            if ent.prefab == prefab_name then
                return ent
            end
        end
    end

    return nil
end

-- 在背包中查找物品
function ActionExecutor:FindItemInInventory(item_prefab)
    local player = self.inst
    if not player.components.inventory then
        return nil
    end

    local items = player.components.inventory:GetItems()
    for _, item in ipairs(items) do
        if item.prefab == item_prefab then
            return item
        end
    end

    return nil
end

return ActionExecutor
```

### 5. Mod入口

**文件**: `dst-ai-mod/modmain.lua`

```lua
-- DST AI Mod - 主入口
-- 版本: 0.1.0
-- 描述: 通过文件共享与Claude AI通信，实现AI自动玩饥荒

local AIController = require("ai/core/controller")

-- 全局AI控制器实例
local GLOBAL_AI_CONTROLLERS = {}

-- 配置
local CONFIG = {
    sync_dir = "C:\\\\dst-ai-sync\\\\",        -- 同步目录
    update_interval = 1,                       -- 更新间隔(帧) - 每帧检查，最低延迟!
    debug_mode = true                           -- 调试模式
}

-- 初始化AI控制器
AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then
        return  -- 只在服务器端运行
    end

    -- 监听玩家生成事件
    inst:ListenForEvent("ms_newspawn", function()
        -- 创建AI控制器
        local controller = AIController(inst, CONFIG)

        -- 启用AI
        controller:Enable()

        -- 保存到全局表
        GLOBAL_AI_CONTROLLERS[inst] = controller

        -- 打印启动信息
        print("[DST AI] =======================================")
        print("[DST AI] DST AI Mod Loaded!")
        print("[DST AI] Sync Directory: " .. CONFIG.sync_dir)
        print("[DST AI] =======================================")
    end)

    -- 监听玩家移除事件
    inst:ListenForEvent("onremove", function()
        if GLOBAL_AI_CONTROLLERS[inst] then
            GLOBAL_AI_CONTROLLERS[inst]:Disable()
            GLOBAL_AI_CONTROLLERS[inst] = nil
        end
    end)
end)

-- 调试控制台命令
if TheNet:GetIsServer() then
    -- ai_status() - 显示AI状态
    function ai_status()
        local player = ThePlayer
        if player and GLOBAL_AI_CONTROLLERS[player] then
            local stats = GLOBAL_AI_CONTROLLERS[player]:GetStats()
            print("[DST AI] Status:")
            print("  Cycles: " .. stats.cycles)
            print("  Actions Executed: " .. stats.actions_executed)
            print("  Errors: " .. stats.errors)
        else
            print("[DST AI] No active AI controller")
        end
    end

    -- ai_enable() - 启用AI
    function ai_enable()
        local player = ThePlayer
        if player and not GLOBAL_AI_CONTROLLERS[player] then
            local controller = AIController(player, CONFIG)
            controller:Enable()
            GLOBAL_AI_CONTROLLERS[player] = controller
            print("[DST AI] AI Enabled")
        end
    end

    -- ai_disable() - 禁用AI
    function ai_disable()
        local player = ThePlayer
        if player and GLOBAL_AI_CONTROLLERS[player] then
            GLOBAL_AI_CONTROLLERS[player]:Disable()
            GLOBAL_AI_CONTROLLERS[player] = nil
            print("[DST AI] AI Disabled")
        end
    end
end
```

**文件**: `dst-ai-mod/modinfo.lua`

```lua
name = "DST AI Player (Claude)"
description = "AI-controlled player using Claude API via file sharing. Requires dst-ai-server running."
author = "AI Assistant"
version = "0.1.0"

forumthread = ""
api_version = 10

dst_compatible = true
all_clients_require_mod = false
client_only_mod = true

icon_atlas = "modicon.xml"
icon = "modicon.tex"

server_filter_tags = {"AI", "automation"}

-- 配置选项
configuration_options = {
    {
        name = "ai_enabled",
        label = "Enable AI",
        hover = "Enable AI control on spawn",
        options = {
            {description = "Disabled", data = false},
            {description = "Enabled", data = true}
        },
        default = false
    },
    {
        name = "update_interval",
        label = "Update Interval",
        hover = "AI update interval (in frames, 30 frames = ~0.5s)",
        options = {
            {description = "Fast (10 frames)", data = 10},
            {description = "Normal (30 frames)", data = 30},
            {description = "Slow (60 frames)", data = 60}
        },
        default = 30
    },
    {
        name = "debug_mode",
        label = "Debug Mode",
        hover = "Show debug messages",
        options = {
            {description = "Off", data = false},
            {description = "On", data = true}
        },
        default = false
    }
}
```

---

## Node.js AI服务器

### 1. 文件监听器 (使用chokidar)

**文件**: `dst-ai-server/src/communication/file-watcher.ts`

```typescript
import chokidar from 'chokidar';
import fs from 'fs/promises';
import path from 'path';
import { EventEmitter } from 'events';

export interface WatcherConfig {
  syncDir: string;
  stateFile: string;
  cmdFile: string;
  statusFile: string;
}

export class FileWatcher extends EventEmitter {
  private config: WatcherConfig;
  private watcher?: chokidar.FSWatcher;
  private lastStateHash = '';

  constructor(config: Partial<WatcherConfig> = {}) {
    super();

    this.config = {
      syncDir: config.syncDir || 'C:\\dst-ai-sync\\',
      stateFile: 'state.txt',
      cmdFile: 'cmd.txt',
      statusFile: 'status.txt'
    };
  }

  async start() {
    // 确保目录存在
    await fs.mkdir(this.config.syncDir, { recursive: true });

    // 写入连接状态
    await this.writeStatus('CONNECTED');

    // 使用chokidar监听state.txt
    const statePath = this.getStatePath();

    this.watcher = chokidar.watch(statePath, {
      persistent: true,
      ignoreInitial: true,
      awaitWriteFinish: true,      // 等待写操作完成
      usePolling: false             // 使用原生事件，不轮询
    });

    // 监听变化事件
    this.watcher.on('change', (path) => {
      this.onStateChange();
    });

    // 监听错误
    this.watcher.on('error', (error) => {
      console.error('[FileWatcher] Error:', error);
    });

    // 监听就绪
    this.watcher.on('ready', () => {
      console.log('[FileWatcher] Watching:', statePath);
    });

    console.log(`[FileWatcher] Started. Sync dir: ${this.config.syncDir}`);
  }

  stop() {
    if (this.watcher) {
      this.watcher.close();
      this.watcher = undefined;
    }
    this.writeStatus('DISCONNECTED');
  }

  private getStatePath() {
    return path.join(this.config.syncDir, this.config.stateFile);
  }

  private getCmdPath() {
    return path.join(this.config.syncDir, this.config.cmdFile);
  }

  private getStatusPath() {
    return path.join(this.config.syncDir, this.config.statusFile);
  }

  private async onStateChange() {
    try {
      const content = await fs.readFile(this.getStatePath(), 'utf-8');

      // 简单hash检查，避免重复处理
      const hash = this.simpleHash(content);
      if (hash === this.lastStateHash) {
        return;
      }
      this.lastStateHash = hash;

      // 发送状态事件
      this.emit('state', content);

    } catch (error) {
      // 文件可能正在写入，忽略
    }
  }

  // 写入命令文件
  async writeCommand(cmd: Command): Promise<void> {
    const cmdPath = this.getCmdPath();
    const json = JSON.stringify(cmd);  // 紧凑JSON
    await fs.writeFile(cmdPath, json);
  }

  // 写入状态文件
  private async writeStatus(status: string): Promise<void> {
    const statusPath = this.getStatusPath();
    await fs.writeFile(statusPath, status);
  }

  // 简单字符串hash
  private simpleHash(str: string): number {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      hash = ((hash << 5) - hash) + str.charCodeAt(i);
      hash |= 0;
    }
    return hash;
  }
}

export interface Command {
  v: number;
  t: number;
  seq: number;
  actions: Action[];
}

export interface Action {
  type: 'move' | 'walk' | 'pickup' | 'chop' | 'mine' | 'attack' | 'eat' | 'equip' | 'wait';
  target?: [number, number, number];
  entity?: string;
  item?: string;
}
```

**package.json** - 添加chokidar依赖：

```json
{
  "name": "dst-ai-server",
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "start": "tsx src/main.ts",
    "dev": "tsx watch src/main.ts"
  },
  "dependencies": {
    "@anthropic-ai/sdk": "^0.27.0",
    "chokidar": "^4.0.1"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "tsx": "^4.7.0"
  }
}
```

### 2. Claude客户端

**文件**: `dst-ai-server/src/ai/claude/client.ts`

```typescript
import Anthropic from '@anthropic-ai/sdk';

export interface ClaudeConfig {
  apiKey: string;
  model?: string;
  maxTokens?: number;
}

export class ClaudeClient {
  private client: Anthropic;
  private config: Required<Pick<ClaudeConfig, 'model' | 'maxTokens'>>;

  constructor(config: ClaudeConfig) {
    this.config = {
      model: config.model || 'claude-3-5-sonnet-20241022',
      maxTokens: config.maxTokens || 1024
    };

    this.client = new Anthropic({
      apiKey: config.apiKey
    });
  }

  async decide(gameState: GameState): Promise<Action[]> {
    const prompt = this.buildPrompt(gameState);

    const response = await this.client.messages.create({
      model: this.config.model,
      max_tokens: this.config.maxTokens,
      messages: [
        {
          role: 'user',
          content: prompt
        }
      ]
    });

    // 解析Claude的响应
    return this.parseResponse(response.content[0].text);
  }

  private buildPrompt(state: GameState): string {
    return `You are playing Don't Starve Together. Decide your next action.

Current State:
- Health: ${Math.floor(state.player.hp * 100)}%
- Hunger: ${Math.floor(state.player.hu * 100)}%
- Sanity: ${Math.floor(state.player.sa * 100)}%
- Position: [${state.player.pos.join(', ')}]
- Day: ${state.w.day}
- Season: ${state.w.season}
- Is Day: ${state.w.isDay}

Nearby Entities:
${this.formatEntities(state.e)}

Inventory:
${this.formatInventory(state.inv)}

Respond with a JSON array of actions. Available action types:
- move: Move to position
- pickup: Pick up item
- chop: Chop tree
- mine: Mine rock
- attack: Attack enemy
- eat: Eat food

Response format:
{"actions":[{"type":"move","target":[x,y,z]}]}`;
  }

  private formatEntities(entities: Entity[]): string {
    if (!entities || entities.length === 0) {
      return 'None';
    }

    return entities.map(e =>
      `- ${e.p} at [${e.pos.join(', ')}] (distance: ${e.d})`
    ).join('\n');
  }

  private formatInventory(inv: Inventory): string {
    if (!inv || inv.length === 0) {
      return 'Empty';
    }

    return inv.map(i =>
      `- ${i.item} x${i.stack}`
    ).join('\n');
  }

  private parseResponse(text: string): Action[] {
    // 提取JSON
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      return [{ type: 'wait' }];
    }

    try {
      const parsed = JSON.parse(jsonMatch[0]);
      return parsed.actions || [{ type: 'wait' }];
    } catch {
      return [{ type: 'wait' }];
    }
  }
}

export interface GameState {
  player: {
    hp: number;
    hu: number;
    sa: number;
    pos: [number, number, number];
  };
  w: {
    day: number;
    time: number;
    season: string;
    isDay: boolean;
  };
  e?: Entity[];
  inv?: Inventory[];
}

export interface Entity {
  p: string;        // prefab
  pos: [number, number, number];
  d: number;        // distance
}

export interface Inventory {
  item: string;
  stack: number;
}

export interface Action {
  type: string;
  target?: [number, number, number];
  entity?: string;
  item?: string;
}
```

### 3. 主程序

**文件**: `dst-ai-server/src/main.ts`

```typescript
import { FileWatcher } from './communication/file-watcher.js';
import { ClaudeClient } from './ai/claude/client.js';

// 配置
const CONFIG = {
  syncDir: process.env.SYNC_DIR || 'C:\\dst-ai-sync\\',
  anthropicKey: process.env.ANTHROPIC_API_KEY || ''
};

// 序列号计数器
let sequence = 0;

async function main() {
  console.log('======================================');
  console.log('  DST AI Server');
  console.log('======================================');
  console.log(`Sync Directory: ${CONFIG.syncDir}`);

  if (!CONFIG.anthropicKey) {
    console.error('Error: ANTHROPIC_API_KEY not set!');
    console.log('Please set environment variable or create .env file');
    process.exit(1);
  }

  // 初始化Claude客户端
  const claude = new ClaudeClient({
    apiKey: CONFIG.anthropicKey
  });

  // 初始化文件监听器
  const watcher = new FileWatcher({
    syncDir: CONFIG.syncDir,
    pollInterval: 50
  });

  // 监听状态变化
  watcher.on('state', async (stateJson: string) => {
    try {
      const state = JSON.parse(stateJson);

      console.log(`\n[${new Date().toLocaleTimeString()}] State received`);
      console.log(`  Health: ${Math.floor(state.player.hp * 100)}%`);
      console.log(`  Hunger: ${Math.floor(state.player.hu * 100)}%`);

      // 调用Claude API决策
      const actions = await claude.decide(state);

      // 写入命令
      sequence++;
      await watcher.writeCommand({
        v: 1,
        t: Date.now(),
        seq: sequence,
        actions: actions
      });

      console.log(`  Actions: ${actions.map(a => a.type).join(', ')}`);

    } catch (error) {
      console.error('Error processing state:', error);
    }
  });

  // 启动监听
  await watcher.start();

  console.log('\nServer started. Press Ctrl+C to stop.\n');

  // 优雅退出
  process.on('SIGINT', () => {
    console.log('\nShutting down...');
    watcher.stop();
    process.exit(0);
  });
}

main().catch(console.error);
```

### 4. package.json

```json
{
  "name": "dst-ai-server",
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "start": "tsx src/main.ts",
    "dev": "tsx watch src/main.ts"
  },
  "dependencies": {
    "@anthropic-ai/sdk": "^0.27.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "tsx": "^4.7.0"
  }
}
```

---

## 使用指南

### 1. 安装准备

```bash
# 安装Node.js (如果还没有)
# 下载: https://nodejs.org/

# 克隆/创建项目目录
cd "C:\Users\Administrator\Desktop\Don't Starve Together ai"

# 安装依赖
cd dst-ai-server
npm install
```

### 2. 配置环境变量

```bash
# 创建 .env 文件
echo ANTHROPIC_API_KEY=your_api_key_here > .env
```

### 3. 启动顺序

```
1. 创建同步目录
   mkdir C:\dst-ai-sync

2. 启动AI服务器
   cd dst-ai-server
   npm start

3. 启动饥荒联机版游戏

4. 创建世界并进入游戏
   AI将自动接管控制
```

### 4. 调试

游戏内控制台命令：
```
ai_status()  - 查看AI状态
ai_enable()  - 启用AI
ai_disable() - 禁用AI
```

---

## 延迟分析 (优化后)

| 组件 | 方式 | 延迟 |
|------|------|------|
| chokidar监听 | OS原生事件 | <1ms |
| Claude API | 网络请求 | 500-2000ms |
| 写入cmd.txt | 同步写入 | 1-5ms |
| Lua轮询读取 | **每1帧 (~16ms)** | 0-16ms |

**总延迟**: 500ms ~ 2020ms
- **最坏情况** (Claude慢 + Lua轮询): ~2020ms
- **最好情况** (Claude快 + Lua即时): ~500ms
- **平均情况**: ~1250ms

**关键优化**: 1帧轮询将Lua端延迟从160ms降至最高16ms，几乎消除了通信延迟感。

---

## Critical Files

**Lua Mod**:
- `dst-ai-mod/modmain.lua` - 入口
- `dst-ai-mod/scripts/ai/core/controller.lua` - AI控制器
- `dst-ai-mod/scripts/ai/communication/file_bridge.lua` - 文件通信
- `dst-ai-mod/scripts/ai/core/state_collector.lua` - 状态采集
- `dst-ai-mod/scripts/ai/core/action_executor.lua` - 动作执行

**Node.js Server**:
- `dst-ai-server/src/main.ts` - 入口
- `dst-ai-server/src/communication/file-watcher.ts` - 文件监听
- `dst-ai-server/src/ai/claude/client.ts` - Claude API客户端
