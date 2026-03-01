# DST Mod API 快速参考

本文档提供 DST Mod 开发中常用的 API 速查。

---

## 全局变量

| 变量 | 类型 | 说明 |
|------|------|------|
| `ThePlayer` | EntityScript | 当前控制的玩家实例 |
| `TheWorld` | EntityScript | 世界实例 |
| `TheSim` | Simulation | 模拟系统，用于查找实体 |
| `TheInput` | Input | 输入系统 |
| `CONSOLE_ENABLED` | bool | 控制台是否启用 |

---

## 玩家组件

### 生命值
```lua
inst.components.health:GetCurrent()         -- 当前生命值
inst.components.health:GetMax()             -- 最大生命值
inst.components.health:GetPercent()         -- 百分比 (0-1)
inst.components.health:SetPercent(amount)   -- 设置百分比
inst.components.health:IsInvincible()       -- 是否无敌
inst.components.health:DoDelta(amount)      -- 增减生命值
```

### 饥饿值
```lua
inst.components.hunger:GetCurrent()         -- 当前饥饿值
inst.components.hunger:GetMax()             -- 最大饥饿值
inst.components.hunger:GetPercent()         -- 百分比 (0-1)
inst.components.hunger:SetPercent(amount)   -- 设置百分比
inst.components.hunger:DoDelta(amount)      -- 增减饥饿值
```

### 理智值
```lua
inst.components.sanity:GetCurrent()         -- 当前理智值
inst.components.sanity:GetMax()             -- 最大理智值
inst.components.sanity:GetPercent()         -- 百分比 (0-1)
inst.components.sanity:SetPercent(amount)   -- 设置百分比
inst.components.sanity:DoDelta(amount)      -- 增减理智值
```

### 移动
```lua
inst.components.locomotor:GoToPoint(Point(x, y, z))  -- 移动到坐标
inst.components.locomotor:WalkForward()               -- 向前走
inst.components.locomotor:Stop()                      -- 停止移动
inst.components.locomotor:IsMoving()                  -- 是否正在移动
```

### 背包/物品
```lua
inst.components.inventory:Equip(item)           -- 装备物品
inst.components.inventory:Unequip(slot)          -- 卸下装备 (hands/head/body)
inst.components.inventory:FindItem(prefab)       -- 查找物品
inst.components.inventory:GetNumItems()          -- 物品数量
inst.components.inventory:GiveItem(item)         -- 给予物品
inst.components.inventory:RemoveItem(item)       -- 移除物品
inst.components.inventory:DropItem(item)         -- 丢弃物品
```

### 位置
```lua
inst:GetPosition()                    -- 返回 x, y, z 坐标
inst.Transform:GetWorldPosition()     -- 同上
inst:GetPosition():Dist(other)        -- 计算距离
```

### 其他常用方法
```lua
inst:GetDisplayName()                 -- 获取显示名称
inst:HasTag("tag_name")               -- 检查是否有标签
inst:AddTag("tag_name")               -- 添加标签
inst:RemoveTag("tag_name")            -- 移除标签
inst:PushEvent("event_name", data)    -- 触发事件
```

---

## 世界状态

```lua
TheWorld.state.cycles                    -- 经过的天数
TheWorld.state.time                      -- 当天时间 (0-1)
TheWorld.state.season                    -- 季节 ("autumn", "winter", "spring", "summer")
TheWorld.state.isday                     -- 是否白天
TheWorld.state.isnight                   -- 是否夜晚
TheWorld.state.isdusk                    -- 是否黄昏
TheWorld.state.remainingtimeinphase      -- 当前阶段剩余时间
TheWorld.state.phase                     -- 当前阶段 ("day", "night", "dusk")
TheWorld.state.temperature               -- 温度
TheWorld.state.snowlevel                 -- 雪量
TheWorld.state.rainlevel                 -- 雨量
TheWorld.state.israining                 -- 是否下雨
TheWorld.state.issnowing                 -- 是否下雪
```

---

## 实体查找

```lua
-- 基本查找
local ents = TheSim:FindEntities(x, y, z, radius)

-- 带标签过滤
local ents = TheSim:FindEntities(x, y, z, radius, nil, nil, {"tag1", "tag2"})

-- 排除特定标签
local ents = TheSim:FindEntities(x, y, z, radius, {"exclude_tag"}, nil, nil)
```

### 常用实体标签

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
| `"carrot"` | 胡萝卜 |
| `"flower"` | 花朵 |
| `"grass"` | 草 |
| `"sapling"` | 树苗 |
| `"monster"` | 怪物 |
| `"animal"` | 动物 |
| `"pig"` | 猪 |
| `"rabbit"` | 兔子 |
| `"spider"` | 蜘蛛 |
| `"structure"` | 建筑 |
| `"wall"` | 墙 |
| `"campfire"` | 营火 |
| `"firepit"` | 石头火坑 |

### 实体属性

```lua
ent.prefab                  -- Prefab 名称
ent.GUID                    -- 全局唯一 ID
ent:GetPosition()           -- 位置
ent:IsValid()               -- 是否有效
ent:HasTag("tag")           -- 是否有标签
ent.components.health       -- 生命值组件（如果有）
```

---

## 常用钩子函数

```lua
-- 玩家初始化后
AddPlayerPostInit(function(inst)
    -- 修改玩家
end)

-- 世界初始化后
AddWorldPostInit(function(inst)
    -- 修改世界
end)

-- Prefab初始化后
AddPrefabPostInit("prefab_name", function(inst)
    -- 修改特定prefab
end)

-- 每帧更新
AddUpdateFunction(function(dt)
    -- dt是帧间隔时间（秒）
end)

-- 组件初始化后
AddComponentPostInit("component_name", function(cmp)
    -- 修改组件
end)

-- 网络消息 RPC
AddModRPCHandler(modname, "rpc_name", function(player, ...)
    -- 处理RPC调用
end)
```

---

## 坐标系统

- **X**: 东西方向（正数为东，负数为西）
- **Y**: 高度（通常为0）
- **Z**: 南北方向（正数为北，负数为南）
- 原点(0,0,0)是世界中心
- 每个地块(tile)约4个单位

```lua
-- 创建坐标点
local pos = Point(x, y, z)
local pos = Vector3(x, y, z)

-- 获取坐标
local x, y, z = inst:GetPosition():Get()
```

---

## 距离计算

```lua
distsq(inst1, inst2)                      -- 两实体距离平方
inst:GetDistanceSqToInst(target)          -- 到目标距离平方
inst:GetPosition():Dist(target_pos)       -- 距离
```

---

## 时间

```lua
-- 获取服务器时间
TheNet:GetServerTime() or GetTime()
```

---

## 文件操作 (DST环境)

> **注意**: DST Mod 沙盒环境限制，只能访问特定目录

```lua
-- 写文件
local file = io.open("path", "w")
if file then
    file:write("content")
    file:close()
end

-- 读文件
local file = io.open("path", "r")
if file then
    local content = file:read("*all")
    file:close()
end
```

**限制**:
- 服务器端 `io` 不可用
- 路径必须硬编码（不能用 `os.getenv()`）
- 建议设置 `client_only_mod = true`

---

## 动作系统

### 创建动作

```lua
-- 创建拾取动作
local action = BufferedAction(inst, target, ACTIONS.PICK)
inst.components.locomotor:PushAction(action, true)

-- 创建砍树动作
local action = BufferedAction(inst, target, ACTIONS.CHOP)
inst.components.locomotor:PushAction(action, true)

-- 创建攻击动作
local action = BufferedAction(inst, target, ACTIONS.ATTACK)
inst.components.locomotor:PushAction(action, true)
```

### 可用动作 (ACTIONS)

| 动作 | 说明 |
|------|------|
| `ACTIONS.PICK` | 拾取 |
| `ACTIONS.CHOP` | 砍树 |
| `ACTIONS.MINE` | 挖矿 |
| `ACTIONS.DIG` | 挖掘 |
| `ACTIONS.ATTACK` | 攻击 |
| `ACTIONS.EAT` | 进食 |
| `ACTIONS.DROP` | 丢弃 |
| `ACTIONS.LOOKAT` | 观察 |
| `ACTIONS.WALKTO` | 走到 |
| `ACTIONS.BUILD` | 建造 |
| `ACTIONS.COOK` | 烹饪 |
| `ACTIONS.HARVEST` | 收获 |
| `ACTIONS.EQUIP` | 装备 |

---

## 网络同步

```lua
-- 发送RPC到服务器
SendModRPCToServer(MOD_RPC.modname.rpc_name, arg1, arg2, ...)

-- 发送RPC到客户端
SendModRPCToClient(MOD_RPC.modname.rpc_name, player_id, arg1, arg2, ...)
```

---

## 调试

```lua
-- 输出到日志
print("Debug message")

-- 输出到控制台
print(ThePlayer:GetDisplayName())

-- 日志位置
-- 客户端: %USERPROFILE%\Documents\Klei\DoNotStarveTogether\client_log.txt
-- 服务器: <cluster>\Master\server_log.txt
```

---

## 沙盒环境限制

| 函数/变量 | 客户端 | 服务器 |
|-----------|--------|--------|
| `io` | ✅ | ❌ |
| `os` | 部分可用 | ❌ |
| `_G` | ❌ | ❌ |
| `rawget` | ❌ | ❌ |
| `pcall` | ❌ | ❌ |
| `GetTimeRealMS()` | ❌ | ❌ |

**建议**: 使用 `client_only_mod = true` 以获得更多 API 访问权限。
