-- DST AI Player - Client Mod
-- 通过向日志写入游戏状态，与MCP服务器通信

print("[DST AI] Mod loaded!")

-- 全局变量
_G.DST_AI = {
    enabled = true,
    updateInterval = 10,  -- 更新帧数间隔（约每10帧更新一次）
    scanRadius = 20,
    frameCount = 0,
    player = nil,
    stats = {
        cycles = 0,
        writes = 0,
        errors = 0
    }
}

-- 序列化数组
local function SerializeArray(arr)
    if not arr or #arr == 0 then return "[]" end

    local result = {}
    for i, v in ipairs(arr) do
        local vType = type(v)
        if vType == "table" then
            local parts = {}
            for k, val in pairs(v) do
                local valType = type(val)
                if valType == "string" then
                    table.insert(parts, string.format('"%s":"%s"', k, val:gsub('"', '\\"')))
                elseif valType == "number" then
                    table.insert(parts, string.format('"%s":%s', k, tostring(val)))
                end
            end
            table.insert(result, "{" .. table.concat(parts, ",") .. "}")
        elseif vType == "string" then
            table.insert(result, string.format('"%s"', v:gsub('"', '\\"')))
        else
            table.insert(result, tostring(v))
        end
    end
    return "[" .. table.concat(result, ",") .. "]"
end

-- 写入游戏状态到日志
local function WriteGameState(playerState, worldState, entities, inventory)
    local json = string.format(
        '{"v":2,"hp":%s,"hu":%s,"sa":%s,"x":%s,"z":%s,"day":%s,"time":%s,"e":%s,"i":%s}',
        tostring(playerState.hp),
        tostring(playerState.hu),
        tostring(playerState.sa),
        tostring(playerState.x),
        tostring(playerState.z),
        tostring(worldState.day),
        tostring(worldState.time),
        SerializeArray(entities),
        SerializeArray(inventory)
    )

    print("[DST_AI_STATE] " .. json)
    _G.DST_AI.stats.writes = _G.DST_AI.stats.writes + 1
end

-- 获取实体名称
local function GetEntityName(ent)
    if ent and ent.GetDisplayName then
        local name = ent:GetDisplayName()
        if name and name ~= "" and name ~= "MISSING NAME" then
            return name
        end
    end
    return ent and ent.prefab or "unknown"
end

-- 生成实体备注
local function GetEntityNotes(ent)
    local notes = {}
    if ent.components.pickable and ent.components.pickable:CanBePickable() then
        table.insert(notes, "可采集")
    end
    if ent.components.workable then
        local action = ent.components.workable:GetWorkAction()
        if action == ACTIONS.CHOP then
            table.insert(notes, "可砍伐")
        elseif action == ACTIONS.MINE then
            table.insert(notes, "可开采")
        elseif action == ACTIONS.DIG then
            table.insert(notes, "可挖掘")
        end
    end
    if ent:HasTag("hostile") or ent:HasTag("monster") then
        table.insert(notes, "敌对")
    end
    if ent.components.inventoryitem then
        table.insert(notes, "物品")
    end
    return table.concat(notes, ",")
end

-- 扫描周围实体
local function ScanNearbyEntities(inst, radius)
    local pos = inst:GetPosition()
    local entities = TheSim:FindEntities(pos.x, pos.y, pos.z, radius)

    local results = {}
    for _, ent in ipairs(entities) do
        if ent ~= inst and ent.entity and ent.entity:IsVisible() then
            local entPos = ent:GetPosition()
            local distance = math.sqrt((entPos.x - pos.x)^2 + (entPos.z - pos.z)^2)

            if distance > 0.5 then
                table.insert(results, {
                    prefab = ent.prefab or "unknown",
                    name = GetEntityName(ent),
                    x = math.floor(entPos.x * 10) / 10,
                    z = math.floor(entPos.z * 10) / 10,
                    d = math.floor(distance * 10) / 10,
                    notes = GetEntityNotes(ent)
                })
            end
        end
    end

    table.sort(results, function(a, b) return a.d < b.d end)
    if #results > 50 then
        local trimmed = {}
        for i = 1, 50 do
            trimmed[i] = results[i]
        end
        results = trimmed
    end
    return results
end

-- 扫描背包
local function ScanInventory(inst)
    local items = {}
    local inv = inst.components.inventory
    if not inv then return items end

    local slots = inv:GetNumSlots()
    local seen = {}

    for slot = 0, slots - 1 do
        local item = inv:GetItemInSlot(slot)
        if item then
            local prefab = item.prefab or "unknown"
            local stack = item.components.stackable and item.components.stackable:StackSize() or 1

            if not seen[prefab] then
                seen[prefab] = {
                    p = prefab,
                    n = GetEntityName(item),
                    s = stack
                }
            else
                seen[prefab].s = seen[prefab].s + stack
            end
        end
    end

    for _, item in pairs(seen) do
        table.insert(items, item)
    end
    return items
end

-- 更新函数
local function DoUpdate()
    if not _G.DST_AI.enabled then
        return
    end

    _G.DST_AI.frameCount = _G.DST_AI.frameCount + 1
    if _G.DST_AI.frameCount < _G.DST_AI.updateInterval then
        return
    end
    _G.DST_AI.frameCount = 0

    _G.DST_AI.stats.cycles = _G.DST_AI.stats.cycles + 1

    -- 获取玩家
    local player = ThePlayer
    if not player or not player:IsValid() then
        return
    end

    _G.DST_AI.player = player

    -- 获取玩家状态
    local pos = player:GetPosition()
    local playerState = {
        hp = 1,
        hu = 1,
        sa = 1,
        x = math.floor(pos.x * 10) / 10,
        z = math.floor(pos.z * 10) / 10
    }

    if player.components.health then
        playerState.hp = math.floor(player.components.health:GetPercent() * 100) / 100
    end
    if player.components.hunger then
        playerState.hu = math.floor(player.components.hunger:GetPercent() * 100) / 100
    end
    if player.components.sanity then
        playerState.sa = math.floor(player.components.sanity:GetPercent() * 100) / 100
    end

    -- 获取世界状态
    local worldState = {
        day = TheWorld.state.cycles or 0,
        time = TheWorld.state.time or 0
    }

    -- 扫描周围实体
    local entities = ScanNearbyEntities(player, _G.DST_AI.scanRadius)

    -- 扫描背包
    local inventory = ScanInventory(player)

    -- 写入日志
    WriteGameState(playerState, worldState, entities, inventory)
end

-- 使用客户端更新循环
AddClientModRPCHandler("dst_ai", "Update", DoUpdate)

-- 使用 UpdateSim初始化
local old_UpdateSim = UpdateSim
function UpdateSim(dt)
    if old_UpdateSim then
        old_UpdateSim(dt)
    end
    DoUpdate()
end

print("[DST AI] Update system initialized!")

-- 控制台命令
function ai_status()
    print("=== DST AI Status ===")
    print("Enabled: " .. tostring(_G.DST_AI.enabled))
    print("Cycles: " .. _G.DST_AI.stats.cycles)
    print("Writes: " .. _G.DST_AI.stats.writes)

    if _G.DST_AI.player and _G.DST_AI.player:IsValid() then
        print("Player: " .. _G.DST_AI.player:GetDisplayName())
    else
        print("Player: Not in game")
    end
end

function ai_enable()
    _G.DST_AI.enabled = true
    print("[DST AI] Enabled")
end

function ai_disable()
    _G.DST_AI.enabled = false
    print("[DST AI] Disabled")
end
