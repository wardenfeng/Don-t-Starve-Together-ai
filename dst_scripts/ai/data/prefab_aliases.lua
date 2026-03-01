-- DST AI Player - Prefab 名称映射表
-- 将复杂的 prefab 名称映射为简化的别名

local aliases = {
    -- === 资源类 ===

    -- 树木
    ["evergreen"] = "tree",
    ["evergreen_sparse"] = "birch",
    ["evergreen_normal"] = "tree",
    ["deciduous_tree"] = "birch",
    ["marsh_tree"] = "marsh_tree",
    ["pinecone"] = "pinecone",

    -- 岩石/矿物
    ["rock1"] = "rock",
    ["rock2"] = "rock",
    ["rock_ice"] = "ice_rock",
    ["rock_flintless"] = "rock",
    ["meteor"] = "meteor",
    ["cave_rock"] = "cave_rock",
    ["nitre"] = "nitre",
    ["goldnugget"] = "gold",
    ["flint"] = "flint",
    ["rocks"] = "rocks",

    -- 草/树枝/浆果
    ["grass"] = "grass",
    ["depleted_grass"] = "grass",
    ["sapling"] = "sapling",
    ["depleted_sapling"] = "sapling",
    ["berrybush"] = "berrybush",
    ["berrybush2"] = "berrybush_juicy",
    ["berrybush_juicy"] = "berrybush_juicy",
    ["berry_juicy"] = "berry_juicy",
    ["berries"] = "berries",
    ["berries_juicy"] = "berries_juicy",
    ["carrot"] = "carrot",
    ["carrot_planted"] = "carrot",

    -- 采集物
    ["flower"] = "flower",
    ["flower_evil"] = "flower_evil",
    ["red_mushroom"] = "mushroom",
    ["green_mushroom"] = "mushroom",
    ["blue_mushroom"] = "mushroom",
    ["cactus"] = "cactus",
    ["cactus_flower"] = "cactus_flower",
    ["reeds"] = "reeds",
    ["bamboo"] = "bamboo",
    ["marsh_bush"] = "marsh_bush",

    -- 食物
    ["meat"] = "meat",
    ["cookedmeat"] = "cooked_meat",
    ["monstermeat"] = "monster_meat",
    ["cookedmonstermeat"] = "cooked_monster_meat",
    ["meat_dried"] = "jerky",
    ["monstermeat_dried"] = "monster_jerky",
    ["smallmeat"] = "small_meat",
    ["cookedsmallmeat"] = "cooked_small_meat",
    ["smallmeat_dried"] = "small_jerky",
    ["fish"] = "fish",
    ["fish_cooked"] = "cooked_fish",
    ["froglegs"] = "frog_legs",
    ["froglegs_cooked"] = "cooked_frog_legs",
    ["batwing"] = "bat_wing",
    ["batwing_cooked"] = "cooked_bat_wing",

    -- === 工具/武器 ===

    -- 斧头
    ["axe"] = "axe",
    ["goldenaxe"] = "golden_axe",
    ["moonglassaxe"] = "moonglass_axe",

    -- 镐
    ["pickaxe"] = "pickaxe",
    ["goldenpickaxe"] = "golden_pickaxe",

    -- 铲子
    ["shovel"] = "shovel",
    ["goldenshovel"] = "golden_shovel",

    -- 武器
    ["spear"] = "spear",
    ["spear_wathgrithr"] = "battle_spear",
    ["nightsword"] = "night_sword",
    ["batbat"] = "batbat",
    ["tentaclespike"] = "tentacle_spike",
    ["ruins_bat"] = "ruins_bat",
    ["hambat"] = "ham_bat",
    ["trap"] = "trap",
    ["bugnet"] = "bug_net",

    -- 护甲
    ["armorgrass"] = "grass_armor",
    ["armorwood"] = "wood_armor",
    ["armormarble"] = "marble_armor",
    ["armor_sanity"] = "night_armor",
    ["armordragonfly"] = "dragonfly_armor",
    ["armorruins"] = "ruins_armor",
    ["armorsnurtleshell"] = "shell_armor",

    -- === 杂物 ===

    -- 材料
    ["cutgrass"] = "grass",
    ["twigs"] = "twigs",
    ["log"] = "log",
    ["livinglog"] = "living_log",
    ["boards"] = "boards",
    ["cutstone"] = "cut_stone",
    ["rope"] = "rope",
    ["papyrus"] = "papyrus",
    ["character_other"] = "heart",
    ["transistor"] = "transistor",
    ["gears"] = "gears",

    -- 种子
    ["seeds"] = "seeds",

    -- === 生物 ===

    -- 敌对生物
    ["spider"] = "spider",
    ["spider_warrior"] = "spider_warrior",
    ["spider_hider"] = "spider_hider",
    ["spider_spitter"] = "spider_spitter",
    ["spider_den"] = "spider_den",
    ["spider_den_2"] = "spider_den_large",
    ["spider_den_3"] = "spider_den_huge",

    ["bat"] = "bat",
    ["frog"] = "frog",
    ["hound"] = "hound",
    ["firehound"] = "fire_hound",
    ["icehound"] = "ice_hound",
    ["merm"] = "merm",
    ["pigman"] = "pig",
    ["pig_guard"] = "pig_guard",
    ["penguin"] = "penguin",
    ["krampus"] = "krampus",
    ["bee"] = "bee",
    ["killerbee"] = "killer_bee",
    ["mosquito"] = "mosquito",

    -- Boss
    ["spider_queen"] = "spider_queen",
    ["leif"] = "leif",
    ["leif_sparse"] = "leif_sparse",
    ["deerclops"] = "deerclops",
    ["bearger"] = "bearger",
    ["moose"] = "moose",
    ["dragonfly"] = "dragonfly",
    ["bee_queen"] = "bee_queen",
    ["antlion"] = "antlion",
    ["klaus"] = "klaus",
    ["toadstool"] = "toadstool",

    -- 中立生物
    ["butterfly"] = "butterfly",
    ["butterflywings"] = "butterfly_wings",
    ["rabbit"] = "rabbit",
    ["mole"] = "mole",
    ["crow"] = "crow",
    ["robin"] = "robin",
    ["robin_winter"] = "robin_winter",
    ["canary"] = "canary",
    ["beefalo"] = "beefalo",
    ["pigman"] = "pig",
    ["catcoon"] = "catcoon",
    ["koalefant"] = "koalefant",
    ["lightninggoat"] = "volt_goat",
    ["slurper"] = "slurper",

    -- === 建筑 ===

    -- 火源
    ["firepit"] = "firepit",
    ["coldfirepit"] = "cold_firepit",
    ["campfire"] = "campfire",
    ["coldfire"] = "cold_fire",

    -- 科学
    ["researchlab"] = "science_machine",
    ["researchlab2"] = "alchemy_engine",
    ["researchlab3"] = "shadow_manipulator",
    ["ancient_altar"] = "precursor_assembly",
    ["ancient_altar_broken"] = "broken_precursor",

    -- 食物制作
    ["cookpot"] = "cooking_pot",
    ["portablecookpot"] = "portable_cooking_pot",
    ["spider_cooker"] = "spider_cooker",

    -- 建造
    ["treasurechest"] = "chest",
    ["pandoraschest"] = "treasure_chest",
    ["skullchest"] = "skull_chest",
    ["icebox"] = "ice_box",
    ["tent"] = "tent",
    ["siestahut"] = "siesta_hut",
    ["slow_farmplot"] = "slow_farm",
    ["fast_farmplot"] = "fast_farm",
    ["meatrack"] = "meat_rack",
    ["birdcage"] = "bird_cage",
    ["homesign"] = "sign",
    ["rangerstation"] = "ranger_station",

    -- === 其他 ===

    -- 道具
    ["torch"] = "torch",
    ["lantern"] = "lantern",
    ["lighter"] = "lighter",
    ["maxwelllight"] = "shadow_light",
    ["campfirefire"] = "campfire_fire",

    -- 生存
    ["healingsalve"] = "healing_salve",
    ["bandage"] = "bandage",
    ["lifeinjector"] = "life_injector",
    ["reviver"] = "telltale_heart",

    -- 魔法
    ["amulet"] = "life_amulet",
    ["blueamulet"] = "chill_amulet",
    ["purpleamulet"] = "nightmare_amulet",
    ["yellowamulet"] = "magiluminescence",
    ["orangeamulet"] = "amulet",
    ["greenamulet"] = "construction_amulet",
    ["redgem"] = "red_gem",
    ["bluegem"] = "blue_gem",
    ["purplegem"] = "purple_gem",
    ["greengem"] = "green_gem",
    ["orangegem"] = "orange_gem",
    ["yellowgem"] = "yellow_gem",

    -- 传送
    ["wormhole"] = "wormhole",
    ["wormhole_limited_1"] = "wormhole",

    -- 刷新点
    ["spawnpoint_master"] = "spawnpoint",
    ["multiplayer_portal"] = "portal",
    ["forest_arena"] = "boss_arena",
}

return aliases
