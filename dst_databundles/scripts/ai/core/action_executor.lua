-- DST AI Player - 动作执行器
-- 将 AI 命令转换为游戏内操作

local PROTOCOL = require("ai/communication/protocol")
local PREFAB_ALIASES = require("ai/data/prefab_aliases")

local ActionExecutor = Class(function(self, inst)
    self.inst = inst
    self.current_action = nil
    self.action_queue = {}

    -- 统计信息
    self.stats = {
        executed = 0,
        failed = 0,
        by_type = {}
    }
end

-- 执行动作
function ActionExecutor:Execute(action)
    if not action or not action.type then
        PROTOCOL.error("Invalid action: missing type")
        self.stats.failed = self.stats.failed + 1
        return false
    end

    local action_type = action.type:lower()

    -- 查找对应的执行函数
    local execute_fn = self["Execute_" .. action_type]
    if not execute_fn then
        PROTOCOL.error("Unknown action type: " .. action_type)
        self.stats.failed = self.stats.failed + 1
        return false
    end

    PROTOCOL.log("Executing action: " .. action_type)

    -- 执行动作
    local success, err = pcall(execute_fn, self, action)

    if success then
        self.stats.executed = self.stats.executed + 1

        -- 统计动作类型
        if not self.stats.by_type[action_type] then
            self.stats.by_type[action_type] = 0
        end
        self.stats.by_type[action_type] = self.stats.by_type[action_type] + 1

        return true
    else
        PROTOCOL.error("Action failed: " .. tostring(err))
        self.stats.failed = self.stats.failed + 1
        return false
    end
end

-- ========== 动作实现函数 ==========

-- 移动到位置
function ActionExecutor:Execute_move(action)
    if not action.target then
        return false
    end

    local pos = Vector3(action.target.x or 0, action.target.y or 0, action.target.z or 0)

    if self.inst.components.locomotor then
        self.inst.components.locomotor:GoToPoint(pos)
        return true
    end

    return false
end

-- 拾取物品
function ActionExecutor:Execute_pickup(action)
    local entity = self:FindEntityByRef(action.entity, action.position)

    if not entity then
        PROTOCOL.log("Entity not found for pickup: " .. tostring(action.entity))
        return false
    end

    -- 检查是否是可拾取物品
    if entity.components.inventoryitem and not entity.components.inventoryitem:IsHeld() then
        -- 尝试拾取
        if self.inst.components.inventory then
            -- 使用玩家控制器的拾取动作
            local pickup_action = BufferedAction(self.inst, entity, ACTIONS.PICKUP)
            self.inst.components.locomotor:PushAction(pickup_action, true)
            return true
        end
    end

    return false
end

-- 砍伐
function ActionExecutor:Execute_chop(action)
    local entity = self:FindEntityByRef(action.entity, action.position, "choppable")

    if not entity then
        PROTOCOL.log("Choppable entity not found")
        return false
    end

    -- 检查是否需要工具
    if not self:HasToolForAction("chop") then
        PROTOCOL.log("No axe equipped for chopping")
        return false
    end

    local chop_action = BufferedAction(self.inst, entity, ACTIONS.CHOP)
    self.inst.components.locomotor:PushAction(chop_action, true)
    return true
end

-- 挖矿
function ActionExecutor:Execute_mine(action)
    local entity = self:FindEntityByRef(action.entity, action.position, "mineable")

    if not entity then
        PROTOCOL.log("Mineable entity not found")
        return false
    end

    -- 检查是否需要工具
    if not self:HasToolForAction("mine") then
        PROTOCOL.log("No pickaxe equipped for mining")
        return false
    end

    local mine_action = BufferedAction(self.inst, entity, ACTIONS.MINE)
    self.inst.components.locomotor:PushAction(mine_action, true)
    return true
end

-- 挖掘
function ActionExecutor:Execute_dig(action)
    local entity = self:FindEntityByRef(action.entity, action.position, "diggable")

    if not entity then
        PROTOCOL.log("Diggable entity not found")
        return false
    end

    -- 检查是否需要工具
    if not self:HasToolForAction("dig") then
        PROTOCOL.log("No shovel equipped for digging")
        return false
    end

    local dig_action = BufferedAction(self.inst, entity, ACTIONS.DIG)
    self.inst.components.locomotor:PushAction(dig_action, true)
    return true
end

-- 攻击
function ActionExecutor:Execute_attack(action)
    local entity = self:FindEntityByRef(action.entity, action.position, "hostile")

    if not entity then
        -- 尝试查找任何可攻击的实体
        entity = self:FindNearestEntityWithTag("hostile", 20)
    end

    if not entity then
        PROTOCOL.log("Target not found for attack")
        return false
    end

    local attack_action = BufferedAction(self.inst, entity, ACTIONS.ATTACK)
    self.inst.components.locomotor:PushAction(attack_action, true)
    return true
end

-- 进食
function ActionExecutor:Execute_eat(action)
    local item_name = action.item

    -- 如果没有指定物品，自动选择可吃的食物
    if not item_name then
        item_name = self:FindEdibleItem()
    else
        item_name = PREFAB_ALIASES[item_name] or item_name
    end

    if not item_name then
        PROTOCOL.log("No edible item found")
        return false
    end

    -- 在背包中查找食物
    local food = self:FindItemInInventory(item_name)
    if not food then
        PROTOCOL.log("Food not found in inventory: " .. item_name)
        return false
    end

    -- 使用玩家控制器执行进食
    if self.inst.components.eater then
        local eat_action = BufferedAction(self.inst, food, ACTIONS.EAT)
        self.inst.components.locomotor:PushAction(eat_action, true)
        return true
    end

    return false
end

-- 装备物品
function ActionExecutor:Execute_equip(action)
    if not action.item then
        return false
    end

    local item_name = PREFAB_ALIASES[action.item] or action.item
    local slot = action.slot or "hands"

    -- 在背包中查找物品
    local item = self:FindItemInInventory(item_name)
    if not item then
        PROTOCOL.log("Item not found in inventory: " .. item_name)
        return false
    end

    -- 获取装备槽位
    local equip_slot = PROTOCOL.GetDSTEquipSlot(slot)

    -- 装备物品
    if self.inst.components.inventory then
        local equip_action = BufferedAction(self.inst, item, ACTIONS.EQUIP)
        -- 设置装备槽位
        if equip_action then
            self.inst.components.inventory:Equip(item, equip_slot)
            return true
        end
    end

    return false
end

-- 卸下装备
function ActionExecutor:Execute_unequip(action)
    local slot = action.slot or "hands"
    local equip_slot = PROTOCOL.GetDSTEquipSlot(slot)

    if self.inst.components.inventory then
        local item = self.inst.components.inventory:GetEquippedItem(equip_slot)
        if item then
            self.inst.components.inventory:Unequip(item)
            return true
        end
    end

    return false
end

-- 制作物品
function ActionExecutor:Execute_craft(action)
    if not action.item then
        return false
    end

    local item_name = PREFAB_ALIASES[action.item] or action.item

    -- 检查是否有制作台
    if self.inst.components.builder then
        local recipe = GetRecipe(item_name)
        if not recipe then
            PROTOCOL.log("Unknown recipe: " .. item_name)
            return false
        end

        -- 检查是否有材料
        if self.inst.components.builder:CanBuild(item_name) then
            -- 制作物品
            local buff = self.inst.components.bufferedaction
            if buff and buff.action == ACTIONS.BUILD then
                -- 正在建造中
                return true
            end

            self.inst.components.builder:MakeRecipe(recipe, self.inst:GetPosition())
            return true
        else
            PROTOCOL.log("Cannot craft " .. item_name .. ": missing materials")
            return false
        end
    end

    return false
end

-- 放置建筑
function ActionExecutor:Execute_build(action)
    if not action.item then
        return false
    end

    local item_name = PREFAB_ALIASES[action.item] or action.item
    local pos = action.position

    if not pos then
        PROTOCOL.log("No position specified for build")
        return false
    end

    local build_pos = Vector3(pos.x, pos.y or 0, pos.z)

    if self.inst.components.builder then
        local recipe = GetRecipe(item_name)
        if not recipe then
            PROTOCOL.log("Unknown recipe: " .. item_name)
            return false
        end

        if self.inst.components.builder:CanBuild(item_name) then
            -- 放置建筑
            self.inst.components.builder:MakeRecipeAt(recipe, build_pos)
            return true
        else
            PROTOCOL.log("Cannot build " .. item_name .. ": missing materials")
            return false
        end
    end

    return false
end

-- 等待
function ActionExecutor:Execute_wait(action)
    local duration = action.duration or 1

    -- 使用定时器等待
    self.inst:DoTaskInTime(duration, function()
        PROTOCOL.log("Wait completed")
    end

    return true
end

-- 跟随实体
function ActionExecutor:Execute_follow(action)
    if not action.entity then
        return false
    end

    local entity = self:FindEntityByRef(action.entity, action.position)
    if not entity then
        PROTOCOL.log("Entity not found for follow: " .. tostring(action.entity))
        return false
    end

    -- 跟随实体
    if self.inst.components.locomotor then
        self.inst.components.locomotor:FollowEntity(entity)
        return true
    end

    return false
end

-- 复活
function ActionExecutor:Execute_revive(action)
    -- 检查是否是幽灵状态
    if not self.inst:HasTag("ghost") then
        PROTOCOL.log("Not a ghost, no revive needed")
        return false
    end

    -- 查找复活道具
    local telltale = self:FindItemInInventory("reviver")
    if not telltale then
        PROTOCOL.log("No revival item found")
        return false
    end

    -- 使用复活道具
    if self.inst.components.playercontroller then
        -- 尝试找到最近的活着的玩家
        local players = TheSim:FindEntities(self.inst:GetPosition():Get(), 30, {"player"})
        for _, player in ipairs(players) do
            if player ~= self.inst and not player:HasTag("ghost") then
                local revive_action = BufferedAction(self.inst, player, ACTIONS.REVIVE)
                self.inst.components.locomotor:PushAction(revive_action, true)
                return true
            end
        end
    end

    return false
end

-- ========== 辅助函数 ==========

-- 根据引用查找实体
function ActionExecutor:FindEntityByRef(entity_ref, position, tag)
    if not entity_ref and not position then
        return nil
    end

    local player_pos = self.inst:GetPosition()
    local search_pos = position or player_pos
    local search_radius = 20

    -- 构建查找标签
    local must_tags = nil
    local cant_tags = { "INLIMBO", "NOCLICK", "FX" }

    if tag then
        must_tags = { tag }
    end

    -- 查找实体
    local entities = TheSim:FindEntities(
        search_pos.x or player_pos.x,
        search_pos.y or 0,
        search_pos.z or player_pos.z,
        search_radius,
        nil, -- any tag
        must_tags,
        cant_tags
    )

    -- 根据 prefab 名称匹配
    if entity_ref then
        local target_prefab = PREFAB_ALIASES[entity_ref] or entity_ref

        for _, ent in ipairs(entities) do
            if ent.prefab == target_prefab then
                return ent
            end
        end
    end

    -- 如果没有找到，返回第一个可用的实体
    if #entities > 0 then
        return entities[1]
    end

    return nil
end

-- 查找最近的带标签实体
function ActionExecutor:FindNearestEntityWithTag(tag, radius)
    local pos = self.inst:GetPosition()
    local entities = TheSim:FindEntities(pos.x, 0, pos.z, radius or 20, { tag }, nil, { "INLIMBO" })

    if #entities > 0 then
        return entities[1]
    end

    return nil
end

-- 检查是否有工具
function ActionExecutor:HasToolForAction(action)
    local tool_map = {
        chop = "axe",
        mine = "pickaxe",
        dig = "shovel"
    }

    local tool = tool_map[action]
    if not tool then
        return true -- 不需要工具
    end

    -- 检查装备槽
    local equipped = self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if equipped and equipped.prefab == tool then
        return true
    end

    -- 检查背包中是否有工具
    local tool_item = self:FindItemInInventory(tool)
    return tool_item ~= nil
end

-- 在背包中查找物品
function ActionExecutor:FindItemInInventory(item_name)
    if not self.inst.components.inventory then
        return nil
    end

    local target_name = PREFAB_ALIASES[item_name] or item_name

    local items = self.inst.components.inventory:FindItems(function(item)
        return item.prefab == target_name
    end

    if #items > 0 then
        return items[1]
    end

    return nil
end

-- 查找可吃的食物
function ActionExecutor:FindEdibleItem()
    if not self.inst.components.inventory then
        return nil
    end

    local food_items = self.inst.components.inventory:FindItems(function(item)
        return item.components.editable ~= nil or item.components.edible ~= nil
    end

    if #food_items > 0 then
        return food_items[1].prefab
    end

    return nil
end

-- 获取统计信息
function ActionExecutor:GetStats()
    return {
        executed = self.stats.executed,
        failed = self.stats.failed,
        by_type = self.stats.by_type
    }
end

return ActionExecutor
