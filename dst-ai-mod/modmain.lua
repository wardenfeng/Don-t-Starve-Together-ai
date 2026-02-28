-- DST AI Player - Mod主入口
-- AI控制游戏角色，通过MCP协议与外部通信

local SYNC_DIR = "C:\\Users\\Administrator\\dst-ai-sync\\"

-- 获取玩家实例
local function GetPlayer()
    return ThePlayer
end

-- 写入状态文件
local function WriteState()
    local player = GetPlayer()
    if not player then return end

    local data = {}
    data.v = 1

    -- 玩家状态
    if player.components.health then
        data.hp = player.components.health:GetPercent()
    end
    if player.components.hunger then
        data.hu = player.components.hunger:GetPercent()
    end
    if player.components.sanity then
        data.sa = player.components.sanity:GetPercent()
    end

    -- 位置
    local pos = player:GetPosition()
    if pos then
        data.x = math.floor(pos.x)
        data.y = math.floor(pos.y)
        data.z = math.floor(pos.z)
    end

    -- 世界状态
    if TheWorld and TheWorld.state then
        data.day = TheWorld.state.cycles or 0
        data.time = TheWorld.state.time or 0
        data.isday = TheWorld.state.isday or false
    end

    -- 序列化为简单JSON
    local json = string.format(
        '{"v":1,"hp":%.2f,"hu":%.2f,"sa":%.2f,"x":%d,"z":%d,"day":%d}',
        data.hp or 1, data.hu or 1, data.sa or 1,
        data.x or 0, data.z or 0, data.day or 0
    )

    local file = io.open(SYNC_DIR .. "state.txt", "w")
    if file then
        file:write(json)
        file:close()
    end
end

-- 玩家初始化
AddPlayerPostInit(function(inst)
    print("[DST AI] Player initialized")
end)

-- 每帧更新（每0.5秒写入一次状态）
local updateTimer = 0
AddUpdateFunction(function(dt)
    updateTimer = updateTimer + dt
    if updateTimer >= 0.5 then
        updateTimer = 0
        WriteState()
    end
end)

-- 全局函数
function ai_status()
    print("[DST AI] Status: Running")
    local player = GetPlayer()
    if player then
        print("[DST AI] Player: " .. (player:GetDisplayName() or "Unknown"))
    end
end

function ai_enable()
    print("[DST AI] Always active in current version")
end

function ai_disable()
    print("[DST AI] Cannot disable in current version")
end

print("[DST AI] Mod loaded successfully")
