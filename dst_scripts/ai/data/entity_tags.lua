-- DST AI Player - 实体标签定义
-- 定义游戏中常用的实体标签及其用途

local EntityTags = {
    -- === 交互标签 ===

    -- 可采集 (浆果丛、草等)
    PICKABLE = {
        "pickable",
        "harvestable"
    },

    -- 可砍伐 (树木)
    CHOPPABLE = {
        "choppable",
        "workable"
    },

    -- 可开采 (岩石、金矿等)
    MINEABLE = {
        "mineable",
        "workable"
    },

    -- 可挖掘 (树根、坟墓等)
    DIGGABLE = {
        "diggable",
        "workable"
    },

    -- 可拾取 (掉落物)
    PICKUP = {
        "inventoryitem",
        "_inventoryitem"
    },

    -- === 战斗标签 ===

    -- 敌对生物
    HOSTILE = {
        "hostile",
        "monster",
        "epic"
    },

    -- Boss
    BOSS = {
        "epic",
        "largecreature"
    },

    -- 生物 (动物)
    CREATURE = {
        "creature",
        "animal"
    },

    -- === 功能标签 ===

    -- 玩家
    PLAYER = {
        "player"
    },

    -- 跟随者
    FOLLOWER = {
        "follower",
        "companion"
    },

    -- NPC
    NPC = {
        "NPC",
        "character"
    },

    -- === 建筑标签 ===

    -- 可燃物
    BURNABLE = {
        "burnable",
        "fire"
    },

    -- 可点燃
    IGNITABLE = {
        "ignitable",
        "canlight"
    },

    -- 可熄灭
    EXTINGUISHABLE = {
        "extinguishable"
    },

    -- === 特殊标签 ===

    -- 不予理睬
    IGNORE = {
        "FX",
        "NOCLICK",
        "DECOR",
        "INLIMBO",
        "ghost",
        "playerghost"
    },

    -- 光源
    LIGHTSOURCE = {
        "lightsource"
    }
}

-- 实体类型到标签的映射
local EntityTagMap = {
    -- 资源
    ["evergreen"] = {"choppable", "workable"},
    ["evergreen_sparse"] = {"choppable", "workable"},
    ["deciduous_tree"] = {"choppable", "workable"},
    ["rock1"] = {"mineable", "workable"},
    ["rock2"] = {"mineable", "workable"},
    ["rock_flintless"] = {"mineable", "workable"},
    ["grass"] = {"pickable"},
    ["sapling"] = {"pickable"},
    ["berrybush"] = {"pickable"},
    ["berrybush2"] = {"pickable"},
    ["carrot_planted"] = {"pickable"},
    ["flower"] = {"pickable"},
    ["red_mushroom"] = {"pickable"},
    ["green_mushroom"] = {"pickable"},
    ["blue_mushroom"] = {"pickable"},
    ["cactus"] = {"pickable"},
    ["reeds"] = {"pickable"},

    -- 生物
    ["spider"] = {"hostile", "monster", "creature"},
    ["spider_warrior"] = {"hostile", "monster", "creature"},
    ["spider_hider"] = {"hostile", "monster", "creature"},
    ["spider_spitter"] = {"hostile", "monster", "creature"},
    ["spider_den"] = {"hostile"},
    ["bat"] = {"hostile", "creature"},
    ["frog"] = {"hostile", "creature"},
    ["hound"] = {"hostile", "creature"},
    ["firehound"] = {"hostile", "creature"},
    ["icehound"] = {"hostile", "creature"},
    ["merm"] = {"hostile", "creature"},
    ["pigman"] = {"creature", "NPC"},
    ["pig_guard"] = {"hostile", "creature"},
    ["butterfly"] = {"creature"},
    ["rabbit"] = {"creature"},
    ["mole"] = {"creature"},
    ["crow"] = {"creature"},
    ["robin"] = {"creature"},
    ["beefalo"] = {"creature"},
    ["catcoon"] = {"creature"},
    ["koalefant"] = {"creature"},
    ["slurper"] = {"hostile", "creature"},

    -- Boss
    ["spider_queen"] = {"hostile", "epic", "largecreature"},
    ["leif"] = {"hostile", "epic", "largecreature"},
    ["leif_sparse"] = {"hostile", "epic", "largecreature"},
    ["deerclops"] = {"hostile", "epic", "largecreature"},
    ["bearger"] = {"hostile", "epic", "largecreature"},
    ["moose"] = {"hostile", "epic", "largecreature"},
    ["dragonfly"] = {"hostile", "epic", "largecreature"},
    ["bee_queen"] = {"hostile", "epic", "largecreature"},
    ["klaus"] = {"hostile", "epic", "largecreature"},
    ["toadstool"] = {"hostile", "epic", "largecreature"},

    -- 建筑
    ["firepit"] = {"burnable", "lightsource"},
    ["coldfirepit"] = {"burnable", "lightsource"},
    ["campfire"] = {"burnable", "lightsource"},
    ["torch"] = {"burnable", "lightsource"},
    ["lantern"] = {"lightsource"},
    ["lighter"] = {"burnable", "lightsource"},
}

-- 根据 prefab 获取标签
function EntityTags:GetTagsForPrefab(prefab)
    return EntityTagMap[prefab] or {}
end

-- 检查实体是否有指定标签类别
function EntityTags:HasTagCategory(ent, category)
    local tags_to_check = EntityTags[category]
    if not tags_to_check then
        return false
    end

    for _, tag in ipairs(tags_to_check) do
        if ent:HasTag(tag) then
            return true
        end
    end

    return false
end

-- 获取实体的所有相关标签
function EntityTags:GetAllEntityTags(ent)
    local tags = {}

    for category, tag_list in pairs(EntityTags) do
        if type(tag_list) == "table" and category ~= "GetTagsForPrefab" and category ~= "HasTagCategory" and category ~= "GetAllEntityTags" then
            for _, tag in ipairs(tag_list) do
                if ent:HasTag(tag) then
                    table.insert(tags, category)
                    break
                end
            end
        end
    end

    return tags
end

return EntityTags
