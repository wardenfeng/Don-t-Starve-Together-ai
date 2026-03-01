-- DST AI Player - 单文件版本（不使用 require 加载子模块）
-- 避免路径分隔符问题

print("[DST AI] ===== Module Loaded =====")
print("[DST AI] Enter game world and run: ai_enable()")

local ai_controller = nil
local ai_enabled = false

-- 协议常量
local SYNC_DIR = "C:\\Users\\Administrator\\dst-ai-sync\\"
local UPDATE_INTERVAL = 10
local STATE_OUTPUT_INTERVAL = 30

-- 辅助函数
local function trim(s)
    if type(s) ~= "string" then return s end
    return s:gsub("^%s*(.-)%s*$", "%1")
end

-- 读取文件 (从 databundles 目录)
local function ReadFile(filename)
    local filepath = "databundles/" .. filename
    local file = io.open(filepath, "r")
    if not file then return nil end
    local content = file:read("*all")
    file:close()
    return content
end

-- 写入文件 (到 databundles 目录)
local function WriteFile(filename, content)
    local filepath = "databundles/" .. filename
    local file = io.open(filepath, "w")
    if not file then return false end
    file:write(content)
    file:close()

    -- 同时输出到日志供 MCP 解析
    local prefix = filename:gsub("%.txt$", ""):gsub("%.lua$", ""):upper()
    print("[DST_AI_" .. prefix .. "] " .. content)
    return true
end

-- 采集游戏状态
local function CollectState(inst)
    if not inst or not inst:IsValid() then
        return nil
    end

    local pos = inst:GetPosition()

    -- 玩家状态
    local health = 1
    if inst.components.health then
        health = inst.components.health:GetPercent() or 1
    end

    local hunger = 1
    if inst.components.hunger then
        hunger = inst.components.hunger:GetPercent() or 1
    end

    local sanity = 1
    if inst.components.sanity then
        sanity = inst.components.sanity:GetPercent() or 1
    end

    -- 世界状态
    local day = 1
    local time = 0
    local season = "autumn"
    local isDay = false

    if TheWorld and TheWorld.state then
        day = TheWorld.state.cycles or 1
        time = TheWorld.state.time or 0
        season = TheWorld.state.season or "autumn"
        isDay = TheWorld.state.isday or false
    end

    -- 附近实体
    local entities = {}
    local nearby_ents = TheSim:FindEntities(
        pos.x, pos.y, pos.z,
        20,
        nil, nil,
        { "FX", "NOCLICK", "DECOR", "INLIMBO" }
    )

    for _, ent in ipairs(nearby_ents) do
        if ent ~= inst then
            local ent_pos = ent:GetPosition()
            local dist = math.sqrt((ent_pos.x - pos.x)^2 + (ent_pos.z - pos.z)^2)
            if dist <= 20 then
                table.insert(entities, {
                    p = ent.prefab or "unknown",
                    x = math.floor(ent_pos.x * 10) / 10,
                    z = math.floor(ent_pos.z * 10) / 10,
                    d = math.floor(dist * 10) / 10
                })
            end
        end
    end

    return {
        v = 1,
        hp = health,
        hu = hunger,
        sa = sanity,
        x = pos.x or 0,
        z = pos.z or 0,
        day = day,
        time = time,
        season = season,
        isDay = isDay,
        e = entities
    }
end

-- 简单 JSON 编码
local function EncodeState(state)
    if not state then return nil end

    local function encode(val)
        local t = type(val)
        if t == "nil" then
            return "null"
        elseif t == "string" then
            return '"' .. val:gsub('"', '\\"') .. '"'
        elseif t == "number" then
            return tostring(val)
        elseif t == "boolean" then
            return val and "true" or "false"
        elseif t == "table" then
            local is_array = true
            local max_index = 0
            for k in pairs(val) do
                if type(k) ~= "number" or k > max_index then
                    is_array = false
                    break
                end
                max_index = k
            end

            if is_array then
                local result = {}
                for i = 1, max_index do
                    table.insert(result, encode(val[i]))
                end
                return "[" .. table.concat(result, ",") .. "]"
            else
                local result = {}
                for k, v in pairs(val) do
                    table.insert(result, '"' .. k .. '":' .. encode(v))
                end
                return "{" .. table.concat(result, ",") .. "}"
            end
        end
        return "null"
    end

    return encode(state)
end

-- 执行动作
local function ExecuteAction(inst, action)
    if not action or not action.type then
        return false
    end

    local atype = action.type:lower()

    if atype == "move" and action.target then
        if inst.components.locomotor then
            local pos = Vector3(action.target.x or 0, 0, action.target.z or 0)
            inst.components.locomotor:GoToPoint(pos)
            return true
        end
    elseif atype == "pickup" and action.entity then
        -- 查找附近实体
        local pos = inst:GetPosition()
        local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 10, nil, nil, nil)
        for _, ent in ipairs(ents) do
            if ent.prefab == action.entity and ent.components.inventoryitem then
                inst.components.inventory:PickupAction(ent, inst)
                return true
            end
        end
    elseif atype == "enable" then
        ai_enabled = true
        print("[DST AI] Enabled")
        return true
    elseif atype == "disable" then
        ai_enabled = false
        if inst.components.locomotor then
            inst.components.locomotor:Stop()
        end
        print("[DST AI] Disabled")
        return true
    end

    return false
end

-- 处理命令 (执行多个动作)
local function ProcessCommand(inst, cmd)
    if not cmd or not cmd.actions then
        return false
    end

    local executed = 0
    for _, action in ipairs(cmd.actions) do
        if ExecuteAction(inst, action) then
            executed = executed + 1
        end
    end

    if executed > 0 then
        print("[DST AI] Executed " .. executed .. " action(s), seq=" .. tostring(cmd.seq or "?"))
    end

    return executed > 0
end

-- 全局命令接收接口 (供 cmd.lua 使用)
_G._DST_AI_SetCommand = function(cmd)
    if not ai_controller then
        print("[DST AI] Error: AI not initialized")
        return false
    end

    local player = ThePlayer
    if not player or not player:IsValid() then
        print("[DST AI] Error: No valid player")
        return false
    end

    return ProcessCommand(player, cmd)
end

-- 查询接口：获取附近实体
local function QueryNearby(player)
    local pos = player:GetPosition()
    local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 20, nil, nil, { "FX", "NOCLICK", "DECOR", "INLIMBO" })

    local result = {}
    for i, ent in ipairs(ents) do
        if ent ~= player then
            local ent_pos = ent:GetPosition()
            local dist = math.sqrt((ent_pos.x - pos.x)^2 + (ent_pos.z - pos.z)^2)
            local prefab = ent.prefab or "unknown"

            -- 收集标签
            local notes = {}
            if ent:HasTag("pickable") then table.insert(notes, "可采集") end
            if ent:HasTag("choppable") then table.insert(notes, "可砍伐") end
            if ent:HasTag("mineable") then table.insert(notes, "可开采") end
            if ent:HasTag("diggable") then table.insert(notes, "可挖掘") end
            if ent:HasTag("hostile") then table.insert(notes, "敌对") end
            if ent.components.inventoryitem and not ent.components.inventoryitem:IsHeld() then
                table.insert(notes, "可拾取")
            end

            table.insert(result, {
                prefab = prefab,
                name = ent:GetDisplayName() or prefab,
                x = math.floor(ent_pos.x * 10) / 10,
                z = math.floor(ent_pos.z * 10) / 10,
                distance = math.floor(dist * 10) / 10,
                notes = table.concat(notes, ",")
            })
        end
    end

    -- 按距离排序
    table.sort(result, function(a, b) return a.distance < b.distance end)

    return result
end

-- 查询接口：获取背包物品
local function QueryInventory(player)
    if not player.components.inventory then
        return {}
    end

    local items = player.components.inventory:FindItems(function(item)
        return item ~= nil and item:IsValid()
    end)

    local result = {}
    for _, item in ipairs(items) do
        local prefab = item.prefab or "unknown"
        local stack_size = 1
        if item.components.stackable then
            stack_size = item.components.stackable:StackSize()
        end

        table.insert(result, {
            prefab = prefab,
            name = item:GetDisplayName() or prefab,
            count = stack_size
        })
    end

    return result
end

-- 查询接口：获取玩家状态
local function QueryStatus(player)
    local health = 1
    if player.components.health then
        health = player.components.health:GetPercent() or 1
    end

    local hunger = 1
    if player.components.hunger then
        hunger = player.components.hunger:GetPercent() or 1
    end

    local sanity = 1
    if player.components.sanity then
        sanity = player.components.sanity:GetPercent() or 1
    end

    local pos = player:GetPosition()

    -- 装备
    local equipment = {}
    if player.components.inventory then
        local equip = player.components.inventory
        local head = equip:GetEquippedItem(EQUIPSLOTS.HEAD)
        local body = equip:GetEquippedItem(EQUIPSLOTS.BODY)
        local hands = equip:GetEquippedItem(EQUIPSLOTS.HANDS)

        if head then equipment.head = head.prefab end
        if body then equipment.body = body.prefab end
        if hands then equipment.hands = hands.prefab end
    end

    return {
        health = math.floor(health * 100),
        hunger = math.floor(hunger * 100),
        sanity = math.floor(sanity * 100),
        position = { x = math.floor(pos.x), z = math.floor(pos.z) },
        equipment = equipment
    }
end

-- 查询接口：获取世界状态
local function QueryWorld()
    if not TheWorld or not TheWorld.state then
        return { day = 1, time = 0, phase = "unknown" }
    end

    local phase = "day"
    if TheWorld.state.isnight then
        phase = "night"
    elseif TheWorld.state.isdusk then
        phase = "dusk"
    end

    return {
        day = TheWorld.state.cycles or 1,
        time = TheWorld.state.time or 0,
        phase = phase,
        season = TheWorld.state.season or "autumn"
    }
end

-- 全局查询接口
_G._DST_AI_Query = function(query)
    if not query or not query.type then
        return { error = "Invalid query" }
    end

    local player = ThePlayer
    if not player or not player:IsValid() then
        return { error = "No valid player" }
    end

    local result = {}

    if query.type == "get_nearby" then
        result.nearby = QueryNearby(player)

    elseif query.type == "get_inventory" then
        result.inventory = QueryInventory(player)

    elseif query.type == "get_status" then
        result.status = QueryStatus(player)

    elseif query.type == "get_world" then
        result.world = QueryWorld()

    elseif query.type == "get_all" then
        result.nearby = QueryNearby(player)
        result.inventory = QueryInventory(player)
        result.status = QueryStatus(player)
        result.world = QueryWorld()
    end

    -- 写入响应文件
    local response_json = EncodeState(result)
    if response_json then
        WriteFile("response.txt", response_json)
        print("[DST AI] Query response written to response.txt")
    end

    return result
end

-- 初始化 AI
local function InitAI(inst)
    if ai_controller then
        return ai_controller
    end

    print("[DST AI] Initializing...")

    local frame_count = 0
    local last_output = 0

    -- 更新函数
    local function OnUpdate(dt)
        frame_count = frame_count + 1

        -- 定期输出状态
        if frame_count - last_output >= STATE_OUTPUT_INTERVAL then
            local state = CollectState(inst)
            if state then
                local json = EncodeState(state)
                if json then
                    print("[DST_AI_STATE] " .. json)
                    WriteFile("state.txt", json)
                end
            end
            last_output = frame_count
        end

        -- 处理查询请求 (query.lua - 始终响应，无需启用 AI)
        if frame_count % UPDATE_INTERVAL == 0 then
            local query_lua = ReadFile("query.lua")
            if query_lua and #query_lua > 0 then
                local query_func = loadstring(query_lua)
                if query_func then
                    local success, result = pcall(query_func)
                    if success and result then
                        -- 执行查询
                        _G._DST_AI_Query(result)
                        WriteFile("query.lua", "")
                    end
                end
            end
        end

        -- 执行命令 (从 databundles/cmd.txt 读取)
        if ai_enabled and frame_count % UPDATE_INTERVAL == 0 then
            local cmd_str = ReadFile("cmd.txt")
            if cmd_str and #cmd_str > 0 then
                local cmd_func = loadstring("return " .. cmd_str)
                if cmd_func then
                    local success, cmd = pcall(cmd_func)
                    if success and cmd and cmd.actions then
                        ProcessCommand(inst, cmd)
                        WriteFile("cmd.txt", "")
                    elseif success and cmd and cmd.type then
                        ExecuteAction(inst, cmd)
                        WriteFile("cmd.txt", "")
                    end
                end
            end
        end
    end

    inst:ListenForEvent("onupdate", OnUpdate)
    inst:ListenForEvent("onremove", function()
        ai_controller = nil
        ai_enabled = false
    end)

    ai_controller = { enabled = true }
    ai_enabled = true
    print("[DST AI] ===== Started! =====")

    return ai_controller
end

-- 启用 AI
_G.ai_enable = function()
    if not ai_controller then
        local player = ThePlayer
        if player and player:IsValid() then
            InitAI(player)
        else
            print("[DST AI] No valid player")
        end
    else
        ai_enabled = true
        print("[DST AI] Enabled")
    end
end

-- 禁用 AI
_G.ai_disable = function()
    ai_enabled = false
    if ThePlayer and ThePlayer.components.locomotor then
        ThePlayer.components.locomotor:Stop()
    end
    print("[DST AI] Disabled")
end

-- 查看状态
_G.ai_status = function()
    print("[DST AI] Enabled: " .. tostring(ai_enabled))

    local player = ThePlayer
    if not player or not player:IsValid() then
        print("  No valid player")
        return
    end

    -- 基本状态
    local health = player.components.health and player.components.health:GetPercent() or 1
    local hunger = player.components.hunger and player.components.hunger:GetPercent() or 1
    local sanity = player.components.sanity and player.components.sanity:GetPercent() or 1
    local pos = player:GetPosition()

    print("  Health: " .. tostring(math.floor(health * 100)) .. "%")
    print("  Hunger: " .. tostring(math.floor(hunger * 100)) .. "%")
    print("  Sanity: " .. tostring(math.floor(sanity * 100)) .. "%")
    print("  Position: " .. tostring(math.floor(pos.x)) .. ", " .. tostring(math.floor(pos.z)))

    -- 装备栏
    print("  Equipment:")
    if player.components.inventory then
        local equip = player.components.inventory
        local head_item = equip:GetEquippedItem(EQUIPSLOTS.HEAD)
        local body_item = equip:GetEquippedItem(EQUIPSLOTS.BODY)
        local hand_item = equip:GetEquippedItem(EQUIPSLOTS.HANDS)

        print("    Head: " .. tostring(head_item and head_item.prefab or "empty"))
        print("    Body: " .. tostring(body_item and body_item.prefab or "empty"))
        print("    Hand: " .. tostring(hand_item and hand_item.prefab or "empty"))

        -- 背包物品
        local items = player.components.inventory:FindItems(function(item)
            return item ~= nil and item:IsValid()
        end)

        print("  Inventory (" .. #items .. " items):")
        for _, item in ipairs(items) do
            local prefab = item.prefab or "unknown"
            local stack_size = 1
            if item.components.stackable then
                stack_size = item.components.stackable:StackSize()
            end
            print("    - " .. prefab .. " x" .. stack_size)
        end
    end
end

-- 帮助
_G.ai_help = function()
    print("[DST AI] Commands:")
    print("  ai_enable() - Start AI")
    print("  ai_disable() - Stop AI")
    print("  ai_status() - Check status")
    print("  ai_nearby() - Show nearby entities")
end

-- 显示附近实体
_G.ai_nearby = function()
    local player = ThePlayer
    if not player or not player:IsValid() then
        print("[DST AI] No valid player")
        return
    end

    local pos = player:GetPosition()
    local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 20, nil, nil, { "FX", "NOCLICK", "DECOR", "INLIMBO" })

    print("[DST AI] Nearby entities (radius 20):")
    for i, ent in ipairs(ents) do
        if ent ~= player and i <= 20 then
            local ent_pos = ent:GetPosition()
            local dist = math.sqrt((ent_pos.x - pos.x)^2 + (ent_pos.z - pos.z)^2)
            local prefab = ent.prefab or "unknown"
            local name = ent:GetDisplayName() or prefab

            -- 收集标签
            local tags = {}
            if ent:HasTag("pickable") then table.insert(tags, "可采集") end
            if ent:HasTag("choppable") then table.insert(tags, "可砍伐") end
            if ent:HasTag("mineable") then table.insert(tags, "可开采") end
            if ent:HasTag("diggingable") then table.insert(tags, "可挖掘") end
            if ent:HasTag("hostile") then table.insert(tags, "敌对") end
            if ent:HasTag("inventoryitem") then table.insert(tags, "物品") end
            if ent:HasTag("tree") then table.insert(tags, "树") end

            local tag_str = #tags > 0 and " [" .. table.concat(tags, ",") .. "]" or ""
            print(string.format("  %s %s (%.1f m)%s", prefab, name, dist, tag_str))
        end
    end
    print("  Total: " .. #ents .. " entities")
end

return {}
