# DST Mod API 快速参考

## 全局变量

| 变量 | 类型 | 说明 |
|------|------|------|
| `ThePlayer` | EntityScript | 当前控制的玩家实例 |
| `TheWorld` | EntityScript | 世界实例 |
| `TheSim` | Simulation | 模拟系统，用于查找实体 |
| `TheInput` | Input | 输入系统 |
| `CONSOLE_ENABLED` | bool | 控制台是否启用 |

## 玩家组件

### 生命值
```lua
inst.components.health:GetCurrent()         -- 当前生命值
inst.components.health:GetMax()             -- 最大生命值
inst.components.health:GetPercent()         -- 百分比 (0-1)
inst.components.health:SetPercent(amount)   -- 设置百分比
inst.components.health:IsInvincible()       -- 是否无敌
```

### 饥饿值
```lua
inst.components.hunger:GetCurrent()         -- 当前饥饿值
inst.components.hunger:GetMax()             -- 最大饥饿值
inst.components.hunger:GetPercent()         -- 百分比 (0-1)
inst.components.hunger:SetPercent(amount)   -- 设置百分比
```

### 理智值
```lua
inst.components.sanity:GetCurrent()         -- 当前理智值
inst.components.sanity:GetMax()             -- 最大理智值
inst.components.sanity:GetPercent()         -- 百分比 (0-1)
inst.components.sanity:SetPercent(amount)   -- 设置百分比
```

### 移动
```lua
inst.components.locomotor:GoToPoint(Point(x, y, z))  -- 移动到坐标
inst.components.locomotor:WalkForward()               -- 向前走
inst.components.locomotor:Stop()                      -- 停止移动
```

### 背包/物品
```lua
inst.components.inventory:Equip(item)           -- 装备物品
inst.components.inventory:Unequip(slot)          -- 卸下装备 (hands/head/body)
inst.components.inventory:FindItem(prefab)       -- 查找物品
inst.components.inventory:GetNumItems()          -- 物品数量
inst.components.inventory:GiveItem(item)         -- 给予物品
```

### 动作
```lua
inst.components.playeractioncreator:DoAction(inst, action, target)  -- 执行动作
BufferedAction(inst, target, ACTIONS.PICK)        -- 创建拾取动作
BufferedAction(inst, target, ACTIONS.CHOP)        -- 创建砍伐动作
```

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
```

## 实体查找

```lua
-- 查找附近实体
local ents = TheSim:FindEntities(x, y, z, radius)
-- 或带标签过滤
local ents = TheSim:FindEntities(x, y, z, radius, nil, nil, {"tag1", "tag2"})

-- 常用标签
-- "pickable" - 可拾取
-- "tree" - 树
-- "rock" - 岩石
-- "berry" - 浆果
-- "monster" - 怪物
-- "animal" - 动物
-- "structure" - 建筑
```

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
    -- dt是帧间隔时间
end)

-- 网络消息
AddModRPCHandler(modname, "rpc_name", function(player, ...)
    -- 处理RPC调用
end)
```

## 坐标系统

- **X**: 东西方向（正数为东，负数为西）
- **Y**: 高度（通常为0）
- **Z**: 南北方向（正数为北，负数为南）
- 原点(0,0,0)是世界中心
- 每个地块(tile)约4个单位

## 时间

```lua
-- 获取实际时间秒数（服务器端）
TheNet:GetServerTime() or GetTime()
```

## 距离计算

```lua
distsq(inst1, inst2)                      -- 两实体距离平方
inst:GetDistanceSqToInst(target)          -- 到目标距离平方
inst:GetPosition():Dist(target_pos)       -- 距离
```

## 文件操作 (DST环境中)

```lua
-- 写文件
local file = io.open("path", "w")
file:write("content")
file:close()

-- 读文件
local file = io.open("path", "r")
local content = file:read("*all")
file:close()

-- DST环境限制：只能写游戏目录下，路径必须硬编码
```

## 网络同步

```lua
-- 发送RPC
SendModRPCToServer(MOD_RPC.modname.rpc_name, ...)

-- 设置网络变量
inst.entity:SetParent(...)        -- 设置父实体
inst.entity:Hide()                -- 隐藏实体
inst.entity:Show()                -- 显示实体
```

## 动作类型 (ACTIONS)

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
```
