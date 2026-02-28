-- DST AI Player - 服务器端Mod，读取命令文件并执行

print("[DST AI] Loading mod...")

-- 实体名称映射
local ENTITY_NAMES = {
    ["evergreen"] = "松树", ["evergreen_sparse"] = "稀疏松树",
    ["deciduoustree"] = "桦树", ["marsh_tree"] = "触手树",
    ["rock1"] = "岩石", ["rock2"] = "岩石", ["rock_ice"] = "冰岩石",
    ["rock_flintless"] = "无燧石岩石", ["berrybush"] = "浆果丛",
    ["berrybush2"] = "浆果丛", ["carrot_planted"] = "胡萝卜",
    ["flower"] = "花", ["flower_evil"] = "邪恶花",
    ["grass"] = "草", ["sapling"] = "树苗",
    ["red_mushroom"] = "红蘑菇", ["green_mushroom"] = "绿蘑菇",
    ["blue_mushroom"] = "蓝蘑菇", ["pigman"] = "猪人",
    ["rabbit"] = "兔子", ["crow"] = "乌鸦", ["robin"] = "红雀",
    ["butterfly"] = "蝴蝶", ["bee"] = "蜜蜂",
    ["spider"] = "蜘蛛", ["spider_warrior"] = "蜘蛛战士",
    ["spider_hider"] = "洞穴蜘蛛", ["tentacle"] = "触手",
    ["hound"] = "猎狗", ["firehound"] = "火猎狗",
    ["icehound"] = "冰猎狗", ["chest"] = "箱子",
    ["treasure_chest"] = "宝箱", ["campfire"] = "营火",
    ["firepit"] = "石火坑", ["coldfire"] = "冷火",
    ["coldfirepit"] = "冷火坑", ["skeleton"] = "骨头",
    ["meat"] = "肉", ["cookedmeat"] = "熟肉",
    ["log"] = "木头", ["flint"] = "燧石",
    ["rock"] = "石头", ["nitre"] = "硝石",
    ["goldnugget"] = "金块", ["twigs"] = "树枝",
    ["cutgrass"] = "草", ["berries"] = "浆果",
    ["cookedberries"] = "烤浆果", ["carrot"] = "胡萝卜",
    ["cookedcarrot"] = "烤胡萝卜",
}

local function GetEntityName(prefab)
    return ENTITY_NAMES[prefab] or prefab
end

-- 收集附近实体信息
local function CollectNearbyEntities(inst)
    local pos = inst:GetPosition()
    local radius = 20
    local entities = TheSim:FindEntities(pos.x, pos.y, pos.z, radius)

    local nearby = {}
    local count = 0
    local max_entities = 30

    for i, ent in ipairs(entities) do
        if count >= max_entities then break end
        if ent ~= inst and ent.entity and ent.entity:IsVisible() then
            local prefab = ent.prefab or "unknown"
            local entPos = ent:GetPosition()
            local distance = math.sqrt((entPos.x - pos.x)^2 + (entPos.z - pos.z)^2)

            local interesting = false
            local notes = {}

            if ent:HasTag("pickable") then
                interesting = true
                table.insert(notes, "可采集")
            end
            if ent:HasTag("choppable") then
                interesting = true
                table.insert(notes, "可砍伐")
            end
            if ent:HasTag("mineable") then
                interesting = true
                table.insert(notes, "可开采")
            end
            if ent:HasTag("digable") then
                interesting = true
                table.insert(notes, "可挖掘")
            end
            if ent:HasTag("hostile") or ent:HasTag("monster") then
                interesting = true
                table.insert(notes, "敌对")
            end
            if ent:HasTag("inventoryitem") then
                interesting = true
                table.insert(notes, "物品")
            end

            if ent.components and ent.components.health then
                interesting = true
            end

            if ENTITY_NAMES[prefab] then
                interesting = true
            end

            if interesting or distance < 5 then
                count = count + 1
                table.insert(nearby, {
                    prefab = prefab,
                    name = GetEntityName(prefab),
                    x = math.floor(entPos.x),
                    z = math.floor(entPos.z),
                    distance = math.floor(distance * 10) / 10,
                    notes = table.concat(notes, ","),
                })
            end
        end
    end

    return nearby
end

-- 查找最近的实体
local function FindNearestEntity(inst, prefab)
    local pos = inst:GetPosition()
    local radius = 30
    local entities = TheSim:FindEntities(pos.x, pos.y, pos.z, radius)

    local nearest = nil
    local nearestDist = radius

    for i, ent in ipairs(entities) do
        if ent ~= inst and ent.entity and ent.entity:IsVisible() then
            if ent.prefab == prefab or (prefab == "pickup" and ent:HasTag("inventoryitem")) then
                local entPos = ent:GetPosition()
                local dist = math.sqrt((entPos.x - pos.x)^2 + (entPos.z - pos.z)^2)
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = ent
                end
            end
        end
    end

    return nearest
end

-- 执行动作
local function ExecuteAction(inst, action)
    local actionType = action.type

    if actionType == "move" and action.target then
        local x = action.target.x or 0
        local z = action.target.z or 0
        if inst.components.locomotor then
            inst.components.locomotor:GoToPoint(Point(x, 0, z))
            print("[DST AI] Moving to (" .. x .. ", " .. z .. ")")
        end

    elseif actionType == "pickup" then
        local target = FindNearestEntity(inst, "pickup")
        if target and inst.components.locomotor then
            local pos = target:GetPosition()
            if pos then
                inst.components.locomotor:GoToPoint(Point(pos.x, 0, pos.z))
            end
            local bufferedAction = BufferedAction(inst, target, ACTIONS.PICKUP)
            inst.components.locomotor:PushAction(bufferedAction, true)
            print("[DST AI] Picking up " .. (target.prefab or "item"))
        end

    elseif actionType == "chop" then
        local target = FindNearestEntity(inst, action.entity or "evergreen")
        if target and inst.components.locomotor then
            local pos = target:GetPosition()
            if pos then
                inst.components.locomotor:GoToPoint(Point(pos.x, 0, pos.z))
            end
            local bufferedAction = BufferedAction(inst, target, ACTIONS.CHOP)
            inst.components.locomotor:PushAction(bufferedAction, true)
            print("[DST AI] Chopping " .. (target.prefab or "tree"))
        end

    elseif actionType == "mine" then
        local target = FindNearestEntity(inst, action.entity or "rock1")
        if target and inst.components.locomotor then
            local pos = target:GetPosition()
            if pos then
                inst.components.locomotor:GoToPoint(Point(pos.x, 0, pos.z))
            end
            local bufferedAction = BufferedAction(inst, target, ACTIONS.MINE)
            inst.components.locomotor:PushAction(bufferedAction, true)
            print("[DST AI] Mining " .. (target.prefab or "rock"))
        end

    elseif actionType == "attack" then
        local target = FindNearestEntity(inst, action.entity or "spider")
        if target and inst.components.locomotor and inst.components.combat then
            local pos = target:GetPosition()
            if pos then
                inst.components.locomotor:GoToPoint(Point(pos.x, 0, pos.z))
            end
            inst.components.combat:DoAttack(target)
            print("[DST AI] Attacking " .. (target.prefab or "enemy"))
        end

    elseif actionType == "eat" then
        if inst.components.eater then
            local inventory = inst.components.inventory or inst.replica.inventory
            if inventory then
                local item = inventory:GetItemInSlot(1)
                if item and inst.components.eater:CanEat(item) then
                    inst.components.eater:Eat(item)
                    print("[DST AI] Eating " .. (item.prefab or "food"))
                end
            end
        end
    end
end

-- 命令处理（从文件读取）
local CMD_FILE = "C:\\Users\\Administrator\\dst-ai-sync\\cmd.txt"
local lastCmdSeq = 0
local lastCmdContent = ""

local function ProcessCommands(inst)
    local file = io.open(CMD_FILE, "r")
    if file then
        local content = file:read("*all")
        file:close()

        -- 只在内容变化时处理
        if content ~= "" and content ~= lastCmdContent then
            lastCmdContent = content

            -- 解析JSON命令（简单正则匹配）
            local seq = content:match('"seq"%s*:%s*(%d+)')
            if seq then
                seq = tonumber(seq)
                if seq > lastCmdSeq then
                    lastCmdSeq = seq
                    print("[DST AI] Executing command seq: " .. seq)

                    -- 解析动作类型
                    for actionType in content:gmatch('"type"%s*:%s*"([^"]+)"') do
                        local action = { type = actionType }
                        ExecuteAction(inst, action)
                    end

                    -- 清空命令文件
                    local clearFile = io.open(CMD_FILE, "w")
                    if clearFile then
                        clearFile:write("")
                        clearFile:close()
                    end
                end
            end
        end
    end
end

AddPlayerPostInit(function(inst)
    print("[DST AI] Player initialized: " .. (inst.prefab or "unknown"))

    -- 每0.5秒打印一次状态
    inst:DoPeriodicTask(0.5, function()
        local hp = inst.components.health and inst.components.health:GetPercent() or 0
        local hu = inst.components.hunger and inst.components.hunger:GetPercent() or 0
        local sa = inst.components.sanity and inst.components.sanity:GetPercent() or 0
        local pos = inst:GetPosition()
        local day = TheWorld and TheWorld.state and TheWorld.state.cycles or 0
        local time = TheWorld and TheWorld.state and TheWorld.state.time or 0

        -- 处理命令
        ProcessCommands(inst)

        -- 获取附近实体
        local entities = CollectNearbyEntities(inst)

        -- 获取背包物品
        local inv_items = {}
        if inst.components.inventory then
            local inv = inst.components.inventory
            if inv.GetNumSlots then
                for slot = 0, inv:GetNumSlots() - 1 do
                    local item = inv:GetItemInSlot(slot)
                    if item then
                        local item_prefab = item.prefab or "unknown"
                        local item_name = GetEntityName(item_prefab)
                        local stack_size = item.components.stackable and item.components.stackable:StackSize() or 1
                        table.insert(inv_items, string.format(
                            '{"p":"%s","n":"%s","s":%d}',
                            item_prefab, item_name, stack_size
                        ))
                    end
                end
            end
        end

        -- 构建JSON
        local entity_list = ""
        for i, ent in ipairs(entities) do
            if i > 1 then entity_list = entity_list .. "," end
            entity_list = entity_list .. string.format(
                '{"p":"%s","n":"%s","x":%d,"z":%d,"d":%.1f,"notes":"%s"}',
                ent.prefab, ent.name, ent.x, ent.z, ent.distance, ent.notes or ""
            )
        end

        local inv_list = table.concat(inv_items, ",")
        local json = string.format(
            'DST_AI_STATE {"v":2,"hp":%.2f,"hu":%.2f,"sa":%.2f,"x":%d,"z":%d,"day":%d,"time":%.2f,"e":[%s],"i":[%s]}',
            hp, hu, sa, math.floor(pos.x), math.floor(pos.z), day, time, entity_list, inv_list
        )
        print(json)
    end)
end)

function ai_status()
    print("[DST AI] Status: Running")
    print("[DST AI] Last command seq: " .. lastCmdSeq)
end

print("[DST AI] Mod loaded successfully")
