-- DST AI Player - 通信协议常量定义
-- 定义所有与 MCP 服务器通信相关的常量

local PROTOCOL = {}

-- 辅助函数：trim 字符串 (DST Lua 没有原生 trim)
local function trim(s)
    if type(s) ~= "string" then return s end
    return s:gsub("^%s*(.-)%s*$", "%1")
end
PROTOCOL.trim = trim

-- 协议版本
PROTOCOL.VERSION = 1

-- 同步目录 (硬编码，因为 DST Lua 环境无 os.getenv)
PROTOCOL.SYNC_DIR = "C:\\Users\\Administrator\\dst-ai-sync\\"

-- 文件名常量
PROTOCOL.FILES = {
    CMD_IN = "cmd.txt",           -- 命令输入 (MCP -> 游戏)
    STATUS_IN = "status.txt",     -- 连接状态 (MCP -> 游戏)
    CONTROL_IN = "control.txt",   -- 控制命令 (MCP -> 游戏)
    STATS_OUT = "stats.txt",      -- 统计输出 (游戏 -> MCP)
}

-- 动作类型枚举
PROTOCOL.ACTION_TYPES = {
    MOVE = "move",
    PICKUP = "pickup",
    CHOP = "chop",
    MINE = "mine",
    DIG = "dig",
    ATTACK = "attack",
    EAT = "eat",
    EQUIP = "equip",
    UNEQUIP = "unequip",
    CRAFT = "craft",
    BUILD = "build",
    WAIT = "wait",
    FOLLOW = "follow",
    REVIVE = "revive"
}

-- 装备槽位映射
PROTOCOL.EQUIP_SLOTS = {
    HANDS = "hands",
    HEAD = "head",
    BODY = "body"
}

-- DST EQUIPSLOTS 常量映射 (延迟加载，因为 EQUIPSLOTS 在模块加载时可能不存在)
function PROTOCOL.GetDSTEquipSlot(slot_name)
    if not EQUIPSLOTS then
        return 1
    end
    if slot_name == PROTOCOL.EQUIP_SLOTS.HANDS then
        return EQUIPSLOTS.HANDS or 1
    elseif slot_name == PROTOCOL.EQUIP_SLOTS.HEAD then
        return EQUIPSLOTS.HEAD or 2
    elseif slot_name == PROTOCOL.EQUIP_SLOTS.BODY then
        return EQUIPSLOTS.BODY or 3
    end
    return 1
end

-- 控制命令
PROTOCOL.CONTROL_COMMANDS = {
    ENABLE = "ENABLE",
    DISABLE = "DISABLE"
}

-- 连接状态
PROTOCOL.CONNECTION_STATUS = {
    CONNECTED = "CONNECTED",
    DISCONNECTED = "DISCONNECTED"
}

-- 日志前缀
PROTOCOL.LOG_PREFIX = "[DST_AI_STATE]"

-- 实体标签 (用于查找和分类)
PROTOCOL.ENTITY_TAGS = {
    -- 可采集
    PICKABLE = "pickable",
    -- 可砍伐
    CHOPPABLE = "choppable",
    -- 可开采
    MINEABLE = "mineable",
    -- 可挖掘
    DIGGABLE = "diggable",
    -- 可拾取
    PICKUP_ITEM = "inventoryitem",
    -- 敌对
    HOSTILE = "hostile",
    -- 战利品
    LOOT = "loot",
    -- 树木
    TREE = "tree",
    -- 岩石
    ROCK = "rock",
    -- 草
    GRASS = "grass",
    -- 树枝
    SAPLING = "sapling",
    -- 浆果丛
    BERRYBUSH = "berrybush",
    -- 生物
    CREATURE = "creature",
    -- 玩家
    PLAYER = "player"
}

-- 状态更新间隔 (帧数)
PROTOCOL.UPDATE_INTERVAL = 10  -- 约 0.16 秒 (60 FPS)

-- 实体扫描半径
PROTOCOL.SCAN_RADIUS = 20

-- 最大实体数量
PROTOCOL.MAX_ENTITIES = 15

-- 日志开关
PROTOCOL.DEBUG = true

-- 辅助函数：打印调试日志
function PROTOCOL.log(msg)
    if PROTOCOL.DEBUG then
        print("[DST AI] " .. tostring(msg))
    end
end

-- 辅助函数：打印错误日志
function PROTOCOL.error(msg)
    print("[DST AI ERROR] " .. tostring(msg))
end

-- 辅助函数：获取完整文件路径
function PROTOCOL.get_path(filename)
    return PROTOCOL.SYNC_DIR .. filename
end

return PROTOCOL
