-- DST AI Mod - 实体扫描器
-- 负责扫描周围实体并分类

local EntityScanner = Class(function(self, inst)
    self.inst = inst
    self.scanRadius = 20  -- 扫描半径
end)

-- 实体类型分类表
local ENTITY_TAGS = {
    -- 可采集
    pickable = { "pickable", "harvestable" },
    -- 可砍伐
    chopable = { "workable", "axe" },
    -- 可开采
    mineable = { "workable", "pickaxe" },
    -- 可挖掘
    diggable = { "diggable" },
    -- 敌对生物
    hostile = { "hostile", "monster", "pig_gang", "spider", "frog" },
    -- 动物
    animal = { "animal", "pig", "beefalo", "rabbit", "bird" },
    -- 物品
    item = { "_inventoryitem", "pickable", "stackable" },
    -- 树木
    tree = { "tree", "evergreen", "deciduoustree", "mushtree" },
    -- 岩石
    rock = { "rock", "boulder", "petrification" },
    -- 浆果丛
    berry = { "berry", "berrybush" },
    -- 建筑
    structure = { "structure", "wall" }
}

-- 获取实体名称
local function GetEntityName(ent)
    if not ent then return "unknown" end

    -- 优先使用显示名称
    if ent.GetDisplayName and type(ent.GetDisplayName) == "function" then
        local name = ent:GetDisplayName()
        if name and name ~= "" and name ~= "MISSING NAME" then
            return name
        end
    end

    -- 使用 prefab 名称
    if ent.prefab then
        return ent.prefab
    end

    return "unknown"
end

-- 获取实体 prefab
local function GetEntityPrefab(ent)
    if not ent then return "unknown" end
    return ent.prefab or "unknown"
end

-- 检查实体是否可采集
local function IsPickable(ent)
    return ent.components.pickable ~= nil
        and ent.components.pickable:CanBePickable()
        and not ent.components.pickable:IsWithered()
end

-- 检查实体是否可砍伐
local function IsChopable(ent)
    return ent.components.workable ~= nil
        and ent.components.workable:GetWorkAction() == ACTIONS.CHOP
end

-- 检查实体是否可开采
local function IsMineable(ent)
    return ent.components.workable ~= nil
        and ent.components.workable:GetWorkAction() == ACTIONS.MINE
end

-- 检查实体是否可挖掘
local function IsDiggable(ent)
    return ent.components.workable ~= nil
        and ent.components.workable:GetWorkAction() == ACTIONS.DIG
end

-- 检查实体是否敌对
local function IsHostile(ent)
    if ent.components.combat == nil then return false end
    return ent.components.hostile or ent:HasTag("hostile") or ent:HasTag("monster")
end

-- 检查是否是掉落物品
local function IsPickupItem(ent)
    return ent.components.inventoryitem ~= nil
end

-- 生成实体备注
local function GetEntityNotes(ent)
    local notes = {}

    if IsPickable(ent) then table.insert(notes, "可采集") end
    if IsChopable(ent) then table.insert(notes, "可砍伐") end
    if IsMineable(ent) then table.insert(notes, "可开采") end
    if IsDiggable(ent) then table.insert(notes, "可挖掘") end
    if IsHostile(ent) then table.insert(notes, "敌对") end
    if IsPickupItem(ent) then table.insert(notes, "物品") end

    -- 检查特殊标签
    if ent:HasTag("fire") then table.insert(notes, "着火") end
    if ent:HasTag("burnable") then table.insert(notes, "易燃") end

    return table.concat(notes, ",")
end

-- 扫描周围实体
function EntityScanner:ScanNearby(radius)
    radius = radius or self.scanRadius

    if not self.inst or not self.inst:IsValid() then
        return {}
    end

    local pos = self.inst:GetPosition()
    local entities = TheSim:FindEntities(pos.x, pos.y, pos.z, radius)

    local results = {}

    for _, ent in ipairs(entities) do
        -- 跳过玩家自己
        if ent ~= self.inst and ent.entity and ent.entity:IsVisible() then
            local entPos = ent:GetPosition()
            local distance = math.sqrt(
                (entPos.x - pos.x)^2 + (entPos.z - pos.z)^2
            )

            -- 只收集距离内的实体
            if distance > 0.5 then  -- 排除太近的
                table.insert(results, {
                    prefab = GetEntityPrefab(ent),
                    name = GetEntityName(ent),
                    x = math.floor(entPos.x * 10) / 10,
                    z = math.floor(entPos.z * 10) / 10,
                    d = math.floor(distance * 10) / 10,
                    notes = GetEntityNotes(ent)
                })
            end
        end
    end

    -- 按距离排序
    table.sort(results, function(a, b)
        return a.d < b.d
    end)

    -- 限制返回数量
    local maxResults = 50
    if #results > maxResults then
        local trimmed = {}
        for i = 1, maxResults do
            trimmed[i] = results[i]
        end
        return trimmed
    end

    return results
end

-- 扫描特定类型的实体
function EntityScanner:ScanByTag(tag, radius)
    radius = radius or self.scanRadius

    if not self.inst or not self.inst:IsValid() then
        return {}
    end

    local pos = self.inst:GetPosition()
    local entities = TheSim:FindEntities(pos.x, pos.y, pos.z, radius, { tag })

    local results = {}

    for _, ent in ipairs(entities) do
        if ent ~= self.inst then
            local entPos = ent:GetPosition()
            local distance = math.sqrt(
                (entPos.x - pos.x)^2 + (entPos.z - pos.z)^2
            )

            table.insert(results, {
                prefab = GetEntityPrefab(ent),
                name = GetEntityName(ent),
                x = math.floor(entPos.x * 10) / 10,
                z = math.floor(entPos.z * 10) / 10,
                d = math.floor(distance * 10) / 10,
                notes = GetEntityNotes(ent)
            })
        end
    end

    return results
end

return EntityScanner
