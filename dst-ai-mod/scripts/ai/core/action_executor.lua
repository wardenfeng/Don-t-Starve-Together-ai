-- 动作执行器
-- 将AI命令转换为DST游戏内的实际操作

local ActionExecutor = Class(function(self, inst)
    self.inst = inst
    self.current_action = nil
    self.last_action_time = 0
    self.action_timeout = 5  -- 动作超时时间（秒）

    -- 统计
    self.stats = {
        executed = 0,
        failed = 0,
        by_type = {}
    }
end)

-- 执行动作
function ActionExecutor:Execute(action)
    if not action or not action.type then
        self:RecordFailure("invalid_action")
        return false, "Invalid action"
    end

    local action_type = action.type

    -- 初始化统计
    if not self.stats.by_type[action_type] then
        self.stats.by_type[action_type] = 0
    end

    -- 幽灵状态下只能执行复活动作
    if self.inst:HasTag("ghost") then
        if action_type == "revive" then
            return self:ExecuteRevive(action)
        end
        self:RecordFailure(action_type)
        return false, "Ghost state - can only revive"
    end

    -- 路由到具体执行函数
    local handlers = {
        move = self.ExecuteMove,
        pickup = self.ExecutePickup,
        chop = self.ExecuteChop,
        mine = self.ExecuteMine,
        dig = self.ExecuteDig,
        attack = self.ExecuteAttack,
        eat = self.ExecuteEat,
        equip = self.ExecuteEquip,
        unequip = self.ExecuteUnequip,
        craft = self.ExecuteCraft,
        build = self.ExecuteBuild,
        wait = self.ExecuteWait,
        follow = self.ExecuteFollow
    }

    local handler = handlers[action_type]
    if not handler then
        self:RecordFailure(action_type)
        return false, "Unknown action type: " .. action_type
    end

    -- 执行动作
    local success, result = pcall(function()
        return handler(self, action)
    end)

    if success and result then
        self.stats.executed = self.stats.executed + 1
        self.stats.by_type[action_type] = self.stats.by_type[action_type] + 1
        self.current_action = action
        self.last_action_time = GetTime()
        return true, result
    else
        self:RecordFailure(action_type)
        return false, result or "Action failed"
    end
end)

-- 移动到指定位置
function ActionExecutor:ExecuteMove(action)
    if not action.target then
        return false, "Move action requires target position"
    end

    local target = action.target
    local pos = Point(target.x, target.y or 0, target.z)

    if not self.inst.components.locomotor then
        return false, "No locomotor component"
    end

    self.inst.components.locomotor:GoToPoint(pos)
    return true, "Moving to position"
end)

-- 拾取物品
function ActionExecutor:ExecutePickup(action)
    local entity = self:FindEntityByRef(action.entity, action.position)
    if not entity then
        return false, "Entity not found: " .. tostring(action.entity)
    end

    if not entity.components.inventoryitem then
        return false, "Entity cannot be picked up"
    end

    -- 创建拾取动作
    local buffered_action = BufferedAction(self.inst, entity, ACTIONS.PICKUP)
    self.inst.components.locomotor:PushAction(buffered_action, true)

    return true, "Picking up " .. (entity.prefab or "item")
end)

-- 砍伐树木
function ActionExecutor:ExecuteChop(action)
    local entity = self:FindEntityByRef(action.entity, action.position, "choppable")
    if not entity then
        return false, "Choppable entity not found"
    end

    -- 检查是否有工具
    if not self:HasToolForAction(ACTIONS.CHOP) then
        return false, "No chopping tool equipped"
    end

    local buffered_action = BufferedAction(self.inst, entity, ACTIONS.CHOP)
    self.inst.components.locomotor:PushAction(buffered_action, true)

    return true, "Chopping " .. (entity.prefab or "tree")
end)

-- 挖掘岩石
function ActionExecutor:ExecuteMine(action)
    local entity = self:FindEntityByRef(action.entity, action.position, "mineable")
    if not entity then
        return false, "Mineable entity not found"
    end

    if not self:HasToolForAction(ACTIONS.MINE) then
        return false, "No mining tool equipped"
    end

    local buffered_action = BufferedAction(self.inst, entity, ACTIONS.MINE)
    self.inst.components.locomotor:PushAction(buffered_action, true)

    return true, "Mining " .. (entity.prefab or "rock")
end)

-- 挖掘
function ActionExecutor:ExecuteDig(action)
    local entity = self:FindEntityByRef(action.entity, action.position, "diggable")
    if not entity then
        return false, "Diggable entity not found"
    end

    if not self:HasToolForAction(ACTIONS.DIG) then
        return false, "No digging tool equipped"
    end

    local buffered_action = BufferedAction(self.inst, entity, ACTIONS.DIG)
    self.inst.components.locomotor:PushAction(buffered_action, true)

    return true, "Digging " .. (entity.prefab or "object")
end)

-- 攻击
function ActionExecutor:ExecuteAttack(action)
    local entity = self:FindEntityByRef(action.entity, action.position)
    if not entity then
        return false, "Target entity not found"
    end

    if not entity.components.health or not entity.components.health:IsValid() then
        return false, "Target cannot be attacked"
    end

    local buffered_action = BufferedAction(self.inst, entity, ACTIONS.ATTACK)
    self.inst.components.locomotor:PushAction(buffered_action, true)

    return true, "Attacking " .. (entity.prefab or "target")
end)

-- 进食
function ActionExecutor:ExecuteEat(action)
    local inventory = self.inst.components.inventory
    if not inventory then
        return false, "No inventory component"
    end

    -- 查找可食用物品
    local food = nil
    local best_hunger = 0

    for slot = 1, inventory:GetNumSlots() do
        local item = inventory:GetItemInSlot(slot)
        if item and item.components.edible then
            local hunger_restore = item.components.edible:GetHunger(self.inst) or 0
            if hunger_restore > best_hunger then
                best_hunger = hunger_restore
                food = item
            end
        end
    end

    if not food then
        return false, "No food available"
    end

    self.inst.components.eater:Eat(food)
    return true, "Eating " .. (food.prefab or "food")
end)

-- 装备物品
function ActionExecutor:ExecuteEquip(action)
    if not action.item then
        return false, "Equip action requires item name"
    end

    local inventory = self.inst.components.inventory
    if not inventory then
        return false, "No inventory component"
    end

    -- 在背包中查找物品
    local item = self:FindItemInInventory(action.item)
    if not item then
        return false, "Item not found in inventory: " .. action.item
    end

    -- 确定装备槽位
    local equip_slot = EQUIPSLOTS.HANDS  -- 默认手部
    if action.slot then
        if action.slot == "head" then
            equip_slot = EQUIPSLOTS.HEAD
        elseif action.slot == "body" then
            equip_slot = EQUIPSLOTS.BODY
        end
    end

    -- 装备物品
    if inventory:Equip(item, equip_slot) then
        return true, "Equipped " .. item.prefab
    else
        return false, "Failed to equip " .. item.prefab
    end
end)

-- 卸下装备
function ActionExecutor:ExecuteUnequip(action)
    local inventory = self.inst.components.inventory
    if not inventory then
        return false, "No inventory component"
    end

    local slot = action.slot or "hands"
    local equip_slot = EQUIPSLOTS.HANDS

    if slot == "head" then
        equip_slot = EQUIPSLOTS.HEAD
    elseif slot == "body" then
        equip_slot = EQUIPSLOTS.BODY
    end

    local equipped = inventory:GetEquippedItem(equip_slot)
    if not equipped then
        return false, "No item equipped in " .. slot
    end

    inventory:Unequip(equip_slot)
    return true, "Unequipped item from " .. slot
end)

-- 制作物品
function ActionExecutor:ExecuteCraft(action)
    if not action.item then
        return false, "Craft action requires recipe name"
    end

    local builder = self.inst.components.builder
    if not builder then
        return false, "No builder component"
    end

    local recipe = GetValidRecipe(action.item)
    if not recipe then
        return false, "Unknown recipe: " .. action.item
    end

    if not builder:CanBuild(action.item) then
        return false, "Cannot craft " .. action.item .. " (missing ingredients or tech)"
    end

    builder:MakeRecipe(recipe, self.inst:GetPosition())
    return true, "Crafting " .. action.item
end)

-- 建造/放置
function ActionExecutor:ExecuteBuild(action)
    if not action.item then
        return false, "Build action requires item name"
    end

    local inventory = self.inst.components.inventory
    if not inventory then
        return false, "No inventory component"
    end

    -- 查找要放置的物品
    local item = self:FindItemInInventory(action.item)
    if not item then
        return false, "Item not found: " .. action.item
    end

    -- 如果有指定位置，先移动到那里
    if action.position then
        local pos = Point(action.position.x, action.position.y or 0, action.position.z)

        -- 检查距离
        local inst_pos = self.inst:GetPosition()
        local dist = dist_sq(pos, inst_pos)

        if dist > 25 then  -- 超过5单位距离
            self.inst.components.locomotor:GoToPoint(pos)
            return true, "Moving to build location"
        end

        -- 放置物品
        if item.components.deployable then
            item.components.deployable:Deploy(self.inst, pos)
            return true, "Placed " .. item.prefab
        end
    end

    return false, "Cannot place item"
end)

-- 等待
function ActionExecutor:ExecuteWait(action)
    local duration = action.duration or 1
    -- 空操作，实际上不执行任何游戏动作
    return true, "Waiting " .. duration .. " seconds"
end)

-- 跟随实体
function ActionExecutor:ExecuteFollow(action)
    local entity = self:FindEntityByRef(action.entity, action.position)
    if not entity then
        return false, "Entity not found: " .. tostring(action.entity)
    end

    if not self.inst.components.locomotor then
        return false, "No locomotor component"
    end

    -- 开始跟随
    self.inst.components.locomotor:Follow(entity)
    return true, "Following " .. (entity.prefab or "entity")
end)

-- 复活 (幽灵状态专用)
function ActionExecutor:ExecuteRevive(action)
    if not self.inst:HasTag("ghost") then
        return false, "Not a ghost"
    end

    -- 查找复活设施
    local x, y, z = self.inst.Transform:GetWorldPosition()
    local entities = TheSim:FindEntities(x, y, z, 20)

    for _, ent in ipairs(entities) do
        if ent:IsValid() and ent.components.resurrector then
            if ent.components.resurrector:CanResurrect(self.inst) then
                ent.components.resurrector:Resurrect(self.inst)
                return true, "Resurrected at " .. (ent.prefab or "resurrector")
            end
        end
    end

    -- 检查是否有触摸石
    for _, ent in ipairs(entities) do
        if ent:IsValid() and ent.prefab == "resurrectionstone" then
            self.inst.components.locomotor:GoToPoint(ent:GetPosition())
            return true, "Moving to resurrection stone"
        end
    end

    return false, "No resurrection method nearby"
end)

-- ========== 辅助函数 ==========

-- 根据引用查找实体
function ActionExecutor:FindEntityByRef(entity_ref, position, tag)
    if not entity_ref and not position then
        return nil
    end

    local x, y, z = self.inst.Transform:GetWorldPosition()
    local search_radius = 30

    -- 如果有指定位置，在附近搜索
    if position then
        x, y, z = position.x, position.y or 0, position.z
        search_radius = 5
    end

    local entities = TheSim:FindEntities(x, y, z, search_radius)

    for _, ent in ipairs(entities) do
        if ent ~= self.inst and ent:IsValid() then
            -- 按prefab匹配
            if entity_ref and ent.prefab == entity_ref then
                if not tag or ent:HasTag(tag) then
                    return ent
                end
            end

            -- 按位置匹配（如果没有指定entity_ref）
            if not entity_ref and position then
                local ex, ey, ez = ent.Transform:GetWorldPosition()
                if math.abs(ex - position.x) < 1 and math.abs(ez - position.z) < 1 then
                    if not tag or ent:HasTag(tag) then
                        return ent
                    end
                end
            end
        end
    end

    return nil
end)

-- 检查是否有对应工具
function ActionExecutor:HasToolForAction(action)
    local inventory = self.inst.components.inventory
    if not inventory then
        return false
    end

    -- 检查装备
    local equipped = inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if equipped and equipped.components.tool then
        if equipped.components.tool:CanDoAction(action) then
            return true
        end
    end

    -- 检查背包中的工具
    for slot = 1, inventory:GetNumSlots() do
        local item = inventory:GetItemInSlot(slot)
        if item and item.components.tool and item.components.tool:CanDoAction(action) then
            return true
        end
    end

    return false
end)

-- 在背包中查找物品
function ActionExecutor:FindItemInInventory(item_name)
    local inventory = self.inst.components.inventory
    if not inventory then
        return nil
    end

    -- 搜索主动物品栏
    for slot = 1, inventory:GetNumSlots() do
        local item = inventory:GetItemInSlot(slot)
        if item and item:IsValid() then
            if item.prefab == item_name then
                return item
            end
        end
    end

    -- 搜索装备栏
    local equipped_items = {
        [EQUIPSLOTS.HANDS] = inventory:GetEquippedItem(EQUIPSLOTS.HANDS),
        [EQUIPSLOTS.HEAD] = inventory:GetEquippedItem(EQUIPSLOTS.HEAD),
        [EQUIPSLOTS.BODY] = inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    }

    for _, item in pairs(equipped_items) do
        if item and item:IsValid() and item.prefab == item_name then
            return item
        end
    end

    return nil
end)

-- 记录失败
function ActionExecutor:RecordFailure(action_type)
    self.stats.failed = self.stats.failed + 1
    if not self.stats.by_type[action_type] then
        self.stats.by_type[action_type] = 0
    end
end)

-- 获取统计信息
function ActionExecutor:GetStats()
    return self.stats
end)

-- 重置统计
function ActionExecutor:ResetStats()
    self.stats = {
        executed = 0,
        failed = 0,
        by_type = {}
    }
end)

return ActionExecutor
