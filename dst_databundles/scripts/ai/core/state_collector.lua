-- DST AI Player - 状态采集器
-- 从游戏中采集 AI 需要的所有状态信息

local PROTOCOL = require("ai/communication/protocol")
local PREFAB_ALIASES = require("ai/data/prefab_aliases")

local StateCollector = Class(function(self, inst)
    self.inst = inst
    self.scan_radius = PROTOCOL.SCAN_RADIUS
    self.max_entities = PROTOCOL.MAX_ENTITIES
end)

-- 采集完整游戏状态
function StateCollector:CollectState()
    local player = self.inst
    if not player or not player:IsValid() then
        return nil
    end

    local state = {
        v = PROTOCOL.VERSION,
        hp = 1,
        hu = 1,
        sa = 1,
        x = 0,
        z = 0,
        day = 1,
        time = 0,
        e = {},
        i = {}
    }

    -- 采集玩家状态
    local player_state = self:CollectPlayerState(player)
    if player_state then
        state.hp = player_state.health
        state.hu = player_state.hunger
        state.sa = player_state.sanity
        state.x = player_state.x
        state.z = player_state.z
    end

    -- 采集世界状态
    local world_state = self:CollectWorldState()
    if world_state then
        state.day = world_state.day
        state.time = world_state.time
        state.season = world_state.season
        state.isDay = world_state.isDay
    end

    -- 采集附近实体
    state.e = self:CollectNearbyEntities(player)

    -- 采集背包物品
    state.i = self:CollectInventory(player)

    return state
end)

-- 采集玩家状态
function StateCollector:CollectPlayerState(player)
    local pos = player:GetPosition()

    -- 生命值
    local health = 1
    if player.components.health then
        health = player.components.health:GetPercent() or 1
    end

    -- 饥饿值
    local hunger = 1
    if player.components.hunger then
        hunger = player.components.hunger:GetPercent() or 1
    end

    -- 理智值
    local sanity = 1
    if player.components.sanity then
        sanity = player.components.sanity:GetPercent() or 1
    end

    return {
        health = math.max(0, math.min(1, health)),
        hunger = math.max(0, math.min(1, hunger)),
        sanity = math.max(0, math.min(1, sanity)),
        x = pos.x or 0,
        z = pos.z or 0
    }
end)

-- 采集世界状态
function StateCollector:CollectWorldState()
    if not TheWorld then
        return { day = 1, time = 0 }
    end

    local state = TheWorld.state

    return {
        day = state.cycles or 1,
        time = state.time or 0,
        season = state.season or "autumn",
        isDay = state.isday or false,
        isDusk = state.isdusk or false,
        isNight = state.isnight or false,
        moonphase = state.moonphase or "new"
    }
end)

-- 采集附近实体
function StateCollector:CollectNearbyEntities(player)
    local entities = {}
    local pos = player:GetPosition()

    -- 查找附近所有实体
    local nearby_ents = TheSim:FindEntities(
        pos.x, pos.y, pos.z,
        self.scan_radius,
        nil, -- any tag
        nil, -- must have tags
        { "FX", "NOCLICK", "DECOR", "INLIMBO" } -- can't have tags
    )

    -- 按距离排序并限制数量
    local player_info = { x = pos.x, z = pos.z }

    for _, ent in ipairs(nearby_ents) do
        if #entities >= self.max_entities then
            break
        end

        -- 跳过玩家自己
        if ent == player then
            goto continue
        end

        local ent_pos = ent:GetPosition()
        local dist = math.sqrt((ent_pos.x - pos.x)^2 + (ent_pos.z - pos.z)^2)

        -- 只采集距离内的实体
        if dist <= self.scan_radius then
            local entity_info = self:CollectEntityInfo(ent, dist, pos)
            if entity_info then
                table.insert(entities, entity_info)
            end
        end

        ::continue::
    end

    -- 按距离排序
    table.sort(entities, function(a, b)
        return (a.d or 0) < (b.d or 0)
    end)

    return entities
end)

-- 采集单个实体信息
function StateCollector:CollectEntityInfo(ent, dist, player_pos)
    if not ent or not ent:IsValid() then
        return nil
    end

    local prefab = ent.prefab or "unknown"

    -- 使用别名简化 prefab 名称
    local simple_name = PREFAB_ALIASES[prefab] or prefab

    -- 收集实体标签和属性
    local notes = {}
    local tags_to_check = {
        { tag = "pickable", note = "可采集" },
        { tag = "choppable", note = "可砍伐" },
        { tag = "mineable", note = "可开采" },
        { tag = "diggable", note = "可挖掘" },
        { tag = "hostile", note = "敌对" },
        { tag = "inventoryitem", note = "物品" },
        { tag = "creature", note = "生物" },
        { tag = "NPC", note = "NPC" }
    }

    for _, tag_info in ipairs(tags_to_check) do
        if ent:HasTag(tag_info.tag) then
            table.insert(notes, tag_info.note)
        end
    end

    -- 特殊检查：是否有可以拾取的物品
    if ent.components.inventoryitem and not ent.components.inventoryitem:IsHeld() then
        table.insert(notes, "可拾取")
    end

    -- 获取显示名称
    local name = ent:GetDisplayName() or simple_name

    local ent_pos = ent:GetPosition()

    return {
        p = simple_name,
        n = name,
        x = math.floor(ent_pos.x * 10) / 10,
        z = math.floor(ent_pos.z * 10) / 10,
        d = math.floor(dist * 10) / 10,
        notes = table.concat(notes, ",")
    }
end)

-- 采集背包物品
function StateCollector:CollectInventory(player)
    local items = {}

    if not player.components.inventory then
        return items
    end

    -- 获取所有物品槽
    local all_items = player.components.inventory:FindItems(function(item)
        return item ~= nil and item:IsValid()
    end)

    -- 统计物品数量
    local item_counts = {}
    for _, item in ipairs(all_items) do
        local prefab = item.prefab or "unknown"
        local simple_name = PREFAB_ALIASES[prefab] or prefab

        if item_counts[simple_name] then
            -- 堆叠物品
            if item.components.stackable then
                item_counts[simple_name].s = item_counts[simple_name].s + (item.components.stackable:StackSize() or 1)
            else
                item_counts[simple_name].s = item_counts[simple_name].s + 1
            end
        else
            -- 新物品
            local stack_size = 1
            if item.components.stackable then
                stack_size = item.components.stackable:StackSize() or 1
            end

            item_counts[simple_name] = {
                p = simple_name,
                n = item:GetDisplayName() or simple_name,
                s = stack_size
            }
        end
    end

    -- 转换为数组
    for _, item_info in pairs(item_counts) do
        table.insert(items, item_info)
    end

    return items
end)

-- 获取玩家当前位置
function StateCollector:GetPlayerPosition()
    if not self.inst or not self.inst:IsValid() then
        return { x = 0, y = 0, z = 0 }
    end

    local pos = self.inst:GetPosition()
    return { x = pos.x, y = pos.y, z = pos.z }
end)

-- 获取玩家健康状态
function StateCollector:GetPlayerHealth()
    if not self.inst or not self.inst.components.health then
        return { percent = 1, current = 100, max = 100 }
    end

    local health = self.inst.components.health
    return {
        percent = health:GetPercent() or 1,
        current = health:GetCurrent() or 100,
        max = health:GetMax() or 100
    }
end

return StateCollector
