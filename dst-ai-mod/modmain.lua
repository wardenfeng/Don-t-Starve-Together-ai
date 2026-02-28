-- DST AI Player - MCP版本
-- Mod入口文件

local AIGlobal = {}

-- 全局AI实例表
AIGlobal.controllers = {}

-- 获取配置
local function GetConfig()
    local config = {}
    local modinfo = KnownModIndex:GetModInfo(modname)
    if modinfo and modinfo.configuration_options then
        for _, option in ipairs(modinfo.configuration_options) do
            local options = option.options or {}
            local default = option.default or
                (option.options and option.options[1] and option.options[1].data)
            config[option.name] = GetModConfigData(option.name) or default
        end
    end

    -- 默认值
    config.sync_dir = config.sync_dir or "C:\\dst-ai-sync\\"
    config.update_interval = config.update_interval or 10
    config.scan_radius = config.scan_radius or 20
    config.max_entities = config.max_entities or 15

    return config
end

-- 为玩家创建AI控制器
local function CreatePlayerController(player)
    if not player or not player:IsValid() then
        return
    end

    local userid = player.userid or tostring(player.GUID)
    if AIGlobal.controllers[userid] then
        return
    end

    local config = GetConfig()

    -- 延迟加载模块
    local AIController = require("ai/core/controller")

    -- 创建控制器
    local controller = AIController(player, config)
    AIGlobal.controllers[userid] = controller

    print("[DST AI] Created AI controller for player: " .. (player.name or "Unknown"))
end

-- 监听玩家生成事件
AddPlayerPostInit(function(player)
    if not TheWorld:IsMasterSim() then
        return
    end

    player:ListenForEvent("ms_respawnedfromghost", function()
        CreatePlayerController(player)
    end)

    player:DoTaskInTime(1, function()
        CreatePlayerController(player)
    end)
end)

-- 控制台命令：查看AI状态
function ai_status()
    local player = ThePlayer or ConsoleCommandPlayer()
    if not player then
        print("[DST AI] No player found")
        return
    end

    local userid = player.userid or tostring(player.GUID)
    local controller = AIGlobal.controllers[userid]

    if not controller then
        print("[DST AI] No AI controller found for this player")
        print("[DST AI] Available controllers: " .. tostring(table.getCount(AIGlobal.controllers)))
        return
    end

    local stats = controller:GetStats()
    local enabled = controller:IsEnabled() or false

    print("========== DST AI Status ==========")
    print("Enabled: " .. tostring(enabled))
    print("Connected: " .. tostring(controller:IsConnected()))
    print("Cycles: " .. tostring(stats.cycles))
    print("Actions Executed: " .. tostring(stats.actions_executed))
    print("Errors: " .. tostring(stats.errors))
    print("===================================")
end

-- 控制台命令：启用AI
function ai_enable()
    local player = ThePlayer or ConsoleCommandPlayer()
    if not player then
        print("[DST AI] No player found")
        return
    end

    local userid = player.userid or tostring(player.GUID)
    local controller = AIGlobal.controllers[userid]

    if not controller then
        print("[DST AI] No AI controller found. Run after player spawns.")
        return
    end

    controller:Enable()
    print("[DST AI] AI control enabled")
end

-- 控制台命令：禁用AI
function ai_disable()
    local player = ThePlayer or ConsoleCommandPlayer()
    if not player then
        print("[DST AI] No player found")
        return
    end

    local userid = player.userid or tostring(player.GUID)
    local controller = AIGlobal.controllers[userid]

    if not controller then
        print("[DST AI] No AI controller found")
        return
    end

    controller:Disable()
    print("[DST AI] AI control disabled")
end

-- Mod加载完成
print("[DST AI] DST AI Player (MCP) loaded")
print("[DST AI] Commands: ai_status(), ai_enable(), ai_disable()")
