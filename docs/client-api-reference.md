# DST Mod API 可用性完整参考

本文档详细列出 DST Mod 开发中所有 API 的可用性（客户端 vs 服务器端）。

---

## 沙盒环境限制对比

| API/功能 | 客户端 | 服务器端 | 说明 |
|----------|--------|----------|------|
| `io.open()` | ✅ | ❌ | 文件I/O仅客户端可用 |
| `io.write()` | ✅ | ❌ |  |
| `io.read()` | ✅ | ❌ |  |
| `os.time()` | ❌ | ❌ | 需用游戏内时间API |
| `os.date()` | ❌ | ❌ |  |
| `os.getenv()` | ❌ | ❌ |  |
| `_G` | ❌ | ❌ | 全局表受限 |
| `rawget()` | ❌ | ❌ |  |
| `rawset()` | ❌ | ❌ |  |
| `pcall()` | ❌ | ❌ |  |
| `xpcall()` | ❌ | ❌ |  |
| `getfenv()` | ❌ | ❌ |  |
| `setfenv()` | ❌ | ❌ |  |
| `loadstring()` | ❌ | ❌ |  |
| `load()` | ❌ | ❌ |  |
| `dofile()` | ❌ | ❌ | 使用 `require()` 代替 |
| `GetTimeRealMS()` | ❌ | ❌ |  |

### 可用的全局函数

| 函数 | 客户端 | 服务器端 |
|------|--------|----------|
| `print()` | ✅ | ✅ |
| `require()` | ✅ | ✅ |
| `type()` | ✅ | ✅ |
| `tostring()` | ✅ | ✅ |
| `tonumber()` | ✅ | ✅ |
| `pairs()` | ✅ | ✅ |
| `ipairs()` | ✅ | ✅ |
| `table.*` | ✅ | ✅ |
| `string.*` | ✅ | ✅ |
| `math.*` | ✅ | ✅ |
| `next()` | ✅ | ✅ |
| `unpack()` | ✅ | ✅ |

---

## 全局变量

| 变量 | 客户端 | 服务器端 | 类型 | 说明 |
|------|--------|----------|------|------|
| `ThePlayer` | ✅ | ❌ | EntityScript | 当前控制的玩家（仅客户端） |
| `TheWorld` | ✅ | ✅ | EntityScript | 世界实例 |
| `TheSim` | ✅ | ✅ | Simulation | 模拟系统 |
| `TheInput` | ✅ | ❌ | Input | 输入系统 |
| `TheNet` | ✅ | ✅ | Networking | 网络系统 |
| `CONSOLE_ENABLED` | ✅ | ✅ | bool | 控制台是否启用 |
| `MOD_RPC` | ✅ | ✅ | table | Mod RPC命名空间 |

---

## 客户端检测方法

### 方法1：检查 ThePlayer
```lua
if ThePlayer then
    -- 在客户端环境
end
```

### 方法2：检查 TheNet
```lua
if TheNet and not TheNet:GetIsServer() then
    -- 在客户端环境
end
```

### 方法3：组合检查
```lua
local function IsClient()
    if ThePlayer then return true end
    if TheNet and not TheNet:GetIsServer() then return true end
    return false
end
```

---

## 玩家组件 API

### 生命值 (health)
| 方法 | 客户端 | 服务器端 | 说明 |
|------|--------|----------|------|
| `inst.components.health:GetCurrent()` | ✅ (replica) | ✅ | 当前生命值 |
| `inst.components.health:GetMax()` | ✅ (replica) | ✅ | 最大生命值 |
| `inst.components.health:GetPercent()` | ✅ (replica) | ✅ | 百分比 (0-1) |
| `inst.components.health:SetPercent(amount)` | ❌ | ✅ | 设置百分比 |
| `inst.components.health:DoDelta(amount)` | ❌ | ✅ | 增减生命值 |
| `inst.components.health:IsInvincible()` | ✅ (replica) | ✅ | 是否无敌 |
| `inst.components.health:IsDead()` | ✅ (replica) | ✅ | 是否死亡 |

> **注意**: 客户端通过 `inst.replica.health` 访问，服务器端通过 `inst.components.health`

### 饥饿值 (hunger)
| 方法 | 客户端 | 服务器端 | 说明 |
|------|--------|----------|------|
| `inst.components.hunger:GetCurrent()` | ✅ (replica) | ✅ | 当前饥饿值 |
| `inst.components.hunger:GetMax()` | ✅ (replica) | ✅ | 最大饥饿值 |
| `inst.components.hunger:GetPercent()` | ✅ (replica) | ✅ | 百分比 |
| `inst.components.hunger:SetPercent(amount)` | ❌ | ✅ | 设置百分比 |
| `inst.components.hunger:DoDelta(amount)` | ❌ | ✅ | 增减饥饿值 |

### 理智值 (sanity)
| 方法 | 客户端 | 服务器端 | 说明 |
|------|--------|----------|------|
| `inst.components.sanity:GetCurrent()` | ✅ (replica) | ✅ | 当前理智值 |
| `inst.components.sanity:GetMax()` | ✅ (replica) | ✅ | 最大理智值 |
| `inst.components.sanity:GetPercent()` | ✅ (replica) | ✅ | 百分比 |
| `inst.components.sanity:SetPercent(amount)` | ❌ | ✅ | 设置百分比 |
| `inst.components.sanity:DoDelta(amount)` | ❌ | ✅ | 增减理智值 |

### 移动 (locomotor)
| 方法 | 客户端 | 服务器端 | 说明 |
|------|--------|----------|------|
| `inst.components.locomotor:GoToPoint(pos)` | ❌ | ✅ | 移动到坐标（需RPC） |
| `inst.components.locomotor:WalkForward()` | ❌ | ✅ | 向前走 |
| `inst.components.locomotor:Stop()` | ❌ | ✅ | 停止移动 |
| `inst.components.locomotor:IsMoving()` | ✅ | ✅ | 是否正在移动 |
| `inst.components.locomotor:GetSpeedMultiplier()` | ✅ | ✅ | 获取速度倍率 |

> **客户端移动**: 需要发送RPC到服务器执行移动

### 背包/物品 (inventory)
| 方法 | 客户端 | 服务器端 | 说明 |
|------|--------|----------|------|
| `inst.components.inventory:Equip(item)` | ❌ | ✅ | 装备物品（需RPC） |
| `inst.components.inventory:Unequip(slot)` | ❌ | ✅ | 卸下装备 |
| `inst.components.inventory:FindItem(prefab)` | ✅ (replica) | ✅ | 查找物品 |
| `inst.components.inventory:GetNumItems()` | ✅ (replica) | ✅ | 物品数量 |
| `inst.components.inventory:GiveItem(item)` | ❌ | ✅ | 给予物品 |
| `inst.components.inventory:RemoveItem(item)` | ❌ | ✅ | 移除物品 |
| `inst.components.inventory:DropItem(item)` | ❌ | ✅ | 丢弃物品 |
| `inst.components.inventory:GetItemByName(name)` | ✅ (replica) | ✅ | 按名称查找 |

### 战斗 (combat)
| 方法 | 客户端 | 服务器端 | 说明 |
|------|--------|----------|------|
| `inst.components.combat:CanAttack(target)` | ✅ | ✅ | 是否可攻击 |
| `inst.components.combat:GetAttackRange()` | ✅ | ✅ | 攻击范围 |
| `inst.components.combat:DoAttack(target)` | ❌ | ✅ | 执行攻击（需RPC） |
| `inst.components.combat:GetTarget()` | ✅ | ✅ | 获取当前目标 |

---

## 世界状态 API

| 属性 | 客户端 | 服务器端 | 说明 |
|------|--------|----------|------|
| `TheWorld.state.cycles` | ✅ | ✅ | 经过的天数 |
| `TheWorld.state.time` | ✅ | ✅ | 当天时间 (0-1) |
| `TheWorld.state.season` | ✅ | ✅ | 季节 |
| `TheWorld.state.isday` | ✅ | ✅ | 是否白天 |
| `TheWorld.state.isnight` | ✅ | ✅ | 是否夜晚 |
| `TheWorld.state.isdusk` | ✅ | ✅ | 是否黄昏 |
| `TheWorld.state.phase` | ✅ | ✅ | 当前阶段 |
| `TheWorld.state.temperature` | ✅ | ✅ | 温度 |
| `TheWorld.state.israining` | ✅ | ✅ | 是否下雨 |
| `TheWorld.state.issnowing` | ✅ | ✅ | 是否下雪 |
| `TheWorld.state.remainingtimeinphase` | ✅ | ✅ | 当前阶段剩余时间 |

---

## 实体查找 API

| 方法 | 客户端 | 服务器端 | 说明 |
|------|--------|----------|------|
| `TheSim:FindEntities(x, y, z, radius)` | ✅ | ✅ | 基本查找 |
| `TheSim:FindEntities(x, y, z, radius, nil, nil, {"tag"})` | ✅ | ✅ | 按标签查找 |
| `TheSim:FindEntities(x, y, z, radius, {"exclude"})` | ✅ | ✅ | 排除标签 |

> **注意**: 客户端只能看到已"知晓"的实体，范围可能受限

---

## 实体属性和方法

| 方法/属性 | 客户端 | 服务器端 | 说明 |
|-----------|--------|----------|------|
| `ent.prefab` | ✅ | ✅ | Prefab 名称 |
| `ent.GUID` | ✅ | ✅ | 全局唯一 ID |
| `ent:GetPosition()` | ✅ | ✅ | 位置 |
| `ent.Transform:GetWorldPosition()` | ✅ | ✅ | 位置 |
| `ent:IsValid()` | ✅ | ✅ | 是否有效 |
| `ent:HasTag("tag")` | ✅ | ✅ | 是否有标签 |
| `ent:AddTag("tag")` | ❌ | ✅ | 添加标签 |
| `ent:RemoveTag("tag")` | ❌ | ✅ | 移除标签 |
| `ent:PushEvent("event", data)` | ❌ | ✅ | 触发事件 |
| `ent:GetDisplayName()` | ✅ | ✅ | 显示名称 |
| `ent.userid` | ✅ | ✅ | 用户ID（玩家） |

---

## 常用钩子函数

| 钩子 | 客户端 | 服务器端 | 说明 |
|------|--------|----------|------|
| `AddPlayerPostInit(fn)` | ✅ | ✅ | 玩家初始化后（两端都执行） |
| `AddWorldPostInit(fn)` | ✅ | ✅ | 世界初始化后 |
| `AddPrefabPostInit(name, fn)` | ✅ | ✅ | Prefab初始化后 |
| `AddUpdateFunction(fn)` | ✅ | ✅ | 每帧更新 |
| `AddComponentPostInit(name, fn)` | ✅ | ✅ | 组件初始化后 |
| `AddModRPCHandler(mod, name, fn)` | ✅ | ✅ | RPC处理器 |

---

## 网络通信 (RPC)

### 客户端发送到服务器
```lua
SendModRPCToServer(MOD_RPC[modname]["rpc_name"], arg1, arg2, ...)
```
- **可用性**: 客户端 ✅
- **用途**: 客户端请求服务器执行动作

### 服务器发送到客户端
```lua
SendModRPCToClient(MOD_RPC[modname]["rpc_name"], player_id, arg1, arg2, ...)
```
- **可用性**: 服务器 ✅
- **用途**: 服务器向客户端发送通知

### 注册RPC处理器
```lua
AddModRPCHandler(modname, "rpc_name", function(player, ...)
    -- 处理RPC
end)
```

---

## 客户端专用 API

| API | 说明 |
|-----|------|
| `ThePlayer` | 当前玩家实例 |
| `TheInput` | 输入系统 |
| `io.*` | 文件I/O |
| `SendModRPCToServer()` | 发送RPC到服务器 |
| `ThePlayer.replica.*` | 组件副本（只读） |

---

## 服务器端专用 API

| API | 说明 |
|-----|------|
| `TheNet:GetIsServer()` | 检查是否服务器 |
| `TheNet:GetServerTime()` | 服务器时间 |
| `inst.components.*:Set*()` | 修改游戏状态 |
| `inst.components.*:DoDelta()` | 执行状态变更 |
| `SendModRPCToClient()` | 发送RPC到客户端 |

---

## 文件 I/O（仅客户端）

```lua
-- 写文件
local file = io.open("C:\\path\\to\\file.txt", "w")
if file then
    file:write("content")
    file:close()
end

-- 读文件
local file = io.open("C:\\path\\to\\file.txt", "r")
if file then
    local content = file:read("*all")
    file:close()
end
```

**限制**:
- 必须使用硬编码绝对路径
- 不能使用 `os.getenv()`
- 仅客户端可用

---

## 客户端控制角色的正确方式

由于客户端不能直接修改游戏状态，需要通过RPC：

### 1. 定义RPC（服务器端执行）
```lua
-- 在 modmain.lua 中
AddModRPCHandler(modname, "MoveToPosition", function(player, x, y, z)
    if player and player.components.locomotor then
        player.components.locomotor:GoToPoint(Point(x, y, z))
    end
end)
```

### 2. 客户端调用RPC
```lua
-- 客户端代码
local x, y, z = ThePlayer:GetPosition():Get()
SendModRPCToServer(MOD_RPC[modname]["MoveToPosition"], x + 10, y, z)
```

---

## 调试工具

### 控制台命令（客户端）
```lua
-- 显示玩家位置
print(ThePlayer:GetPosition())

-- 查找附近实体
local x, y, z = ThePlayer:GetPosition():Get()
local ents = TheSim:FindEntities(x, y, z, 20)
for _, ent in ipairs(ents) do
    print(ent.prefab, ent:GetPosition())
end
```

### 日志位置
- 客户端: `%USERPROFILE%\Documents\Klei\DoNotStarveTogether\client_log.txt`
- 服务器: `<cluster>\Master\server_log.txt`

---

## 常用实体标签

| 标签 | 说明 |
|------|------|
| `"pickable"` | 可拾取物品 |
| `"tree"` | 树木 |
| `"evergreen"` | 常青树 |
| `"deciduous"` | 桦树 |
| `"rock"` | 岩石 |
| `"rocky"` | 矿石 |
| `"berry"` | 浆果丛 |
| `"berrybush"` | 浆果灌木 |
| `"grass"` | 草 |
| `"sapling"` | 树苗 |
| `"monster"` | 怪物 |
| `"animal"` | 动物 |
| `"pig"` | 猪 |
| `"spider"` | 蜘蛛 |
| `"structure"` | 建筑 |
| `"campfire"` | 营火 |
| `"firepit"` | 石头火坑 |
| `"wall"` | 墙 |
| `"chest"` | 箱子 |
| `"inventoryitem"` | 物品 |

---

## 时间 API

| 方法 | 客户端 | 服务器端 | 说明 |
|------|--------|----------|------|
| `TheNet:GetServerTime()` | ✅ | ✅ | 服务器时间 |
| `GetTime()` | ✅ | ✅ | 游戏时间 |
| `GetTimeRealTime()` | ❌ | ❌ | 不使用 |
| `TheWorld.state.cycles` | ✅ | ✅ | 天数 |
| `TheWorld.state.time` | ✅ | ✅ | 当天时间 (0-1) |

---

## 动作系统 (ACTIONS)

### 客户端可用（只读）
```lua
ACTIONS.PICK        -- 拾取
ACTIONS.CHOP        -- 砍树
ACTIONS.MINE        -- 挖矿
ACTIONS.DIG         -- 挖掘
ACTIONS.ATTACK      -- 攻击
ACTIONS.EAT         -- 进食
ACTIONS.DROP        -- 丢弃
ACTIONS.LOOKAT      -- 观察
ACTIONS.WALKTO      -- 走到
ACTIONS.BUILD       -- 建造
ACTIONS.COOK        -- 烹饪
ACTIONS.HARVEST     -- 收获
ACTIONS.EQUIP       -- 装备
```

### 执行动作（需服务器端或RPC）
```lua
local action = BufferedAction(inst, target, ACTIONS.CHOP)
inst.components.locomotor:PushAction(action, true)
```

---

## 开发建议

### 客户端 Mod 适用场景
- ✅ UI 显示和增强
- ✅ 状态监控和日志
- ✅ 文件I/O操作
- ✅ 本地数据收集
- ✅ 辅助功能

### 服务器端 Mod 适用场景
- ✅ 游戏逻辑修改
- ✅ 新实体/物品添加
- ✅ 世界生成修改
- ✅ 多人同步功能

### 混合方案（推荐）
使用 `client_only_mod = false` + RPC通信：
- 客户端：收集状态、文件I/O、UI显示
- 服务器：执行动作、修改游戏状态
- RPC：客户端与服务器通信

---

## 快速检查清单

开发前确认：
- [ ] 确定Mod类型（客户端/服务器/混合）
- [ ] 检查API在目标环境是否可用
- [ ] 客户端Mod需要 `IsClient()` 检查
- [ ] 文件I/O仅客户端可用
- [ ] 状态修改仅服务器可用
- [ ] 使用RPC进行客户端→服务器通信
