-- 状态采集器
-- 负责从游戏中采集AI需要的所有状态信息

local StateCollector = Class(function(self, inst)
    self.inst = inst

    -- 缓存配置
    self.scan_radius = 20        -- 扫描周围实体的半径
    self.max_entities = 15       -- 最多采集实体数量

    -- Prefab名称简化映射 (去掉过长前缀)
    self.prefab_aliases = {
        -- 资源类
        ["evergreen"] = "tree",
        ["evergreen_sparse"] = "tree",
        ["deciduous_tree"] = "birch",
        ["marsh_tree"] = "marsh_tree",
        ["rock1"] = "rock",
        ["rock2"] = "rock",
        ["rock_ice"] = "ice_rock",
        ["rock_flintless"] = "rock",
        ["goldnugget"] = "gold",
        ["flint"] = "flint",
        ["nitre"] = "nitre",
        ["cutgrass"] = "grass",
        ["twigs"] = "twigs",
        ["log"] = "log",
        ["charcoal"] = "charcoal",
        -- 食物类
        ["berrybush"] = "berry",
        ["berrybush2"] = "berry",
        ["berrybush_juicy"] = "berry_juicy",
        ["carrot"] = "carrot",
        ["carrot_planted"] = "carrot",
        ["mandrake"] = "mandrake",
        -- 生物类
        ["rabbit"] = "rabbit",
        ["pigman"] = "pig",
        ["spider"] = "spider",
        ["spider_warrior"] = "spider_warrior",
        ["spider_hider"] = "spider_hider",
        ["spider_spitter"] = "spider_spitter",
        ["koalefant"] = "koalefant",
        ["beefalo"] = "beefalo",
        ["penguin"] = "penguin",
        ["merm"] = "merm",
        ["frog"] = "frog",
        ["bat"] = "bat",
        ["hound"] = "hound",
        ["firehound"] = "fire_hound",
        ["icehound"] = "ice_hound",
        -- 敌对生物
        ["spiderqueen"] = "spider_queen",
        ["leif"] = "leif",
        ["leif_sparse"] = "leif",
        ["bee"] = "bee",
        ["killerbee"] = "killerbee",
        ["tallbird"] = "tallbird",
        ["teenbird"] = "teenbird",
        ["smallbird"] = "smallbird",
        ["walrus"] = "walrus",
        ["little_walrus"] = "walrus_small",
        ["moose"] = "moose",
        ["dragonfly"] = "dragonfly",
        ["deerclops"] = "deerclops",
        ["bearger"] = "bearger",
        ["moose_nest"] = "moose_nest",
        -- 结构
        ["campfire"] = "campfire",
        ["firepit"] = "firepit",
        ["coldfire"] = "coldfire",
        ["coldfirepit"] = "coldfirepit",
        ["cookpot"] = "cookpot",
        ["portablecookpot"] = "cookpot",
        ["spiderden"] = "spider_den",
        ["rabbithole"] = "rabbithole",
        ["pigtorch"] = "pig_torch",
        ["mermhouse"] = "merm_house",
        ["tent"] = "tent",
        ["siestahut"] = "siesta_hut",
        ["researchlab"] = "science_machine",
        ["researchlab2"] = "alchemy_engine",
        ["researchlab3"] = "prospecter",
        ["researchlab4"] = "obsidian_workbench",
        -- 落地物品
        ["flint"] = "flint",
        ["axe"] = "axe",
        ["pickaxe"] = "pickaxe",
        ["spear"] = "spear",
        ["grass"] = "grass",
        ["sapling"] = "sapling",
        ["reeds"] = "reeds",
        ["cactus"] = "cactus",
        ["marsh_bush"] = "marsh_bush",
        ["bamboo"] = "bamboo",
        -- 其他
        ["chest"] = "chest",
        ["treasurechest"] = "chest",
        ["skullchest"] = "chest",
        ["pandoraschest"] = "chest",
        ["minotaurchest"] = "chest",
        ["icebox"] = "icebox",
    }
end)

-- 配置参数
function StateCollector:SetScanRadius(radius)
    self.scan_radius = radius or 20
end

function StateCollector:SetMaxEntities(count)
    self.max_entities = count or 15
end)

-- 采集完整游戏状态
function StateCollector:CollectState()
    local player = self.inst

    -- 验证玩家
    if not player or not player:IsValid() then
        return nil
    end

    -- 采集各部分状态
    local player_state = self:CollectPlayerState(player)
    if not player_state then
        return nil
    end

    local world_state = self:CollectWorldState()
    local entities = self:CollectNearbyEntities(player)
    local inventory = self:CollectInventory(player)

    return {
        player = player_state,
        world = world_state,
        entities = entities,
        inventory = inventory
    }
end)

-- 采集玩家状态
function StateCollector:CollectPlayerState(player)
    -- 获取位置
    local x, y, z = player.Transform:GetWorldPosition()

    local state = {
        position = {
            x = math.floor(x * 10) / 10,
            y = math.floor(y * 10) / 10,
            z = math.floor(z * 10) / 10
        },
        health = 1.0,
        hunger = 1.0,
        sanity = 1.0,
        isGhost = false
    }

    -- 检查是否是幽灵状态
    if player:HasTag("ghost") then
        state.isGhost = true
        return state
    end

    -- 生命值
    if player.components.health then
        state.health = player.components.health:GetPercent()
    end

    -- 饥饿值
    if player.components.hunger then
        state.hunger = player.components.hunger:GetPercent()
    end

    -- 理智值
    if player.components.sanity then
        state.sanity = player.components.sanity:GetPercent()
    end

    return state
end)

-- 采集世界状态
function StateCollector:CollectWorldState()
    local world = TheWorld
    if not world then
        return { day = 0, time = 0, season = "unknown", isday = false }
    end

    local state = world.state
    if not state then
        return { day = 0, time = 0, season = "unknown", isday = false }
    end

    local world_state = {
        day = state.cycles or 0,
        time = state.time or 0,
        season = state.season or "autumn",
        isday = state.isday or false,
        isnight = state.isnight or false,
        isdusk = state.isdusk or false,
        moonphase = "new"
    }

    -- 月相计算
    local moon_phase = state.moonphase or 0
    local moon_phases = {"new", "quarter", "half", "threequarter", "full"}
    world_state.moonphase = moon_phases[moon_phase + 1] or "new"

    -- 下雨状态
    if state.israining then
        world_state.israining = true
    else
        world_state.israining = false
    end

    -- 季节剩余天数
    if state.seasonremaining then
        world_state.seasonremaining = math.floor(state.seasonremaining)
    end

    return world_state
end)

-- 采集附近实体
function StateCollector:CollectNearbyEntities(player)
    local x, y, z = player.Transform:GetWorldPosition()

    -- 查找范围内所有实体
    local entities = TheSim:FindEntities(x, y, z, self.scan_radius)

    if not entities or #entities == 0 then
        return {}
    end

    local result = {}
    local count = 0

    for _, ent in ipairs(entities) do
        if count >= self.max_entities then
            break
        end

        -- 跳过玩家自己
        if ent == player then
            goto continue
        end

        -- 跳过无效实体
        if not ent:IsValid() then
            goto continue
        end

        -- 获取实体信息
        local prefab = ent.prefab
        if not prefab then
            goto continue
        end

        -- 简化prefab名称
        local simple_prefab = self.prefab_aliases[prefab] or prefab
        -- 限制长度
        if #simple_prefab > 20 then
            simple_prefab = string.sub(simple_prefab, 1, 20)
        end

        -- 获取位置
        local ex, ey, ez = ent.Transform:GetWorldPosition()

        -- 计算距离
        local dx = ex - x
        local dz = ez - z
        local distance = math.sqrt(dx * dx + dz * dz)

        -- 收集实体信息
        local entity_info = {
            prefab = simple_prefab,
            position = {
                x = math.floor(ex * 10) / 10,
                y = math.floor(ey * 10) / 10,
                z = math.floor(ez * 10) / 10
            },
            distance = math.floor(distance * 10) / 10
        }

        -- 添加额外有用信息
        -- 检查是否可采集
        if ent.components.pickable then
            entity_info.pickable = true
            if ent.components.pickable.caninteractwith then
                entity_info.canpick = ent.components.pickable:CanBePicked(player)
            else
                entity_info.canpick = true
            end
        end

        -- 检查是否可砍
        if ent.components.workable then
            entity_info.workable = true
            local work_action = ent.components.workable:GetWorkAction()
            if work_action == ACTIONS.CHOP then
                entity_info.choppable = true
            elseif work_action == ACTIONS.MINE then
                entity_info.mineable = true
            elseif work_action == ACTIONS.DIG then
                entity_info.diggable = true
            end
        end

        -- 检查是否可攻击
        if ent.components.health and ent:HasTag("hostile") then
            entity_info.hostile = true
        end

        -- 检查是否可拾取
        if ent.components.inventoryitem then
            entity_info.pickup_item = true
        end

        table.insert(result, entity_info)
        count = count + 1

        ::continue::
    end

    -- 按距离排序
    table.sort(result, function(a, b)
        return a.distance < b.distance
    end)

    return result
end)

-- 采集背包物品
function StateCollector:CollectInventory(player)
    local inventory = player.components.inventory
    if not inventory then
        return {}
    end

    local result = {}

    -- 获取主动物品栏
    local items = inventory:GetItemSlots()
    if items then
        for slot, item in pairs(items) do
            if item and item:IsValid() then
                local prefab = item.prefab
                local simple_prefab = self.prefab_aliases[prefab] or prefab

                -- 检查是否已有此物品
                local found = false
                for _, existing in ipairs(result) do
                    if existing.prefab == simple_prefab then
                        existing.count = existing.count + 1
                        found = true
                        break
                    end
                end

                if not found then
                    table.insert(result, {
                        prefab = simple_prefab,
                        count = 1
                    })
                end
            end
        end
    end

    -- 获取装备栏物品
    local equip_slot = inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if equip_slot then
        table.insert(result, {
            prefab = self.prefab_aliases[equip_slot.prefab] or equip_slot.prefab,
            count = 1,
            equipped = "hands"
        })
    end

    local head_slot = inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
    if head_slot then
        table.insert(result, {
            prefab = self.prefab_aliases[head_slot.prefab] or head_slot.prefab,
            count = 1,
            equipped = "head"
        })
    end

    local body_slot = inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    if body_slot then
        table.insert(result, {
            prefab = self.prefab_aliases[body_slot.prefab] or body_slot.prefab,
            count = 1,
            equipped = "body"
        })
    end

    return result
end)

return StateCollector
