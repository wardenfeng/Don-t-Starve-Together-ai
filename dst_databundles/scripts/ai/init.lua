-- DST AI Player - 游戏脚本入口
-- 此模块在 main.lua 中被 require() 加载

print("[DST AI] ===== Initializing DST AI Player =====")

-- 全局 AI 控制器实例
local ai_controller = nil

-- 检查是否在服务端运行
local function IsServer()
    return TheWorld and TheWorld.ismastersim
end

-- 初始化 AI 控制器
local function InitializeAI()
    if not IsServer() then
        print("[DST AI] Running on client, skipping AI initialization")
        return
    end

    -- 延迟初始化，等待玩家生成
    TheWorld:DoTaskInTime(0, function()
        local player = ThePlayer or (ThePlayer and ThePlayer.entity:GetParent())
        if not player then
            -- 查找本地玩家
            local ents = TheSim:FindEntities(0, 0, 0, 9999, {"player"})
            for _, ent in ipairs(ents) do
                if ent and ent:IsValid() and ent.components.health then
                    player = ent
                    break
                end
            end
        end

        if player then
            print("[DST AI] Found player: " .. (player:GetDisplayName() or "Unknown"))

            -- 加载 AI 控制器
            local AIController = require("ai/core/controller")
            ai_controller = AIController(player, {
                update_interval = 10,
                scan_radius = 20,
                state_output_interval = 30
            })

            -- 注册更新回调
            player:ListenForEvent("onupdate", function(inst, dt)
                if ai_controller then
                    ai_controller:OnUpdate(dt)
                end
            end)

            print("[DST AI] AI Controller initialized (disabled by default)")
            print("[DST AI] Type ai_help() for available commands")
        else
            print("[DST AI] No player found, will retry...")
            -- 1秒后重试
            TheWorld:DoTaskInTime(1, InitializeAI)
        end
    end)
end

-- 监听玩家生成事件
AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then
        return
    end

    if not inst.components.health then
        return
    end

    print("[DST AI] Player post-init: " .. (inst:GetDisplayName() or "Unknown"))

    -- 创建 AI 控制器
    local AIController = require("ai/core/controller")
    ai_controller = AIController(inst, {
        update_interval = 10,
        scan_radius = 20,
        state_output_interval = 30
    })

    -- 注册更新回调
    inst:ListenForEvent("onupdate", function(inst, dt)
        if ai_controller then
            ai_controller:OnUpdate(dt)
        end
    end)

    print("[DST AI] AI Controller initialized (disabled by default)")
end)

-- ========== 全局控制台命令 ==========

GLOBAL.ai_enable = function()
    if ai_controller then
        ai_controller:Enable()
        print("[DST AI] === AI CONTROL ENABLED ===")
    else
        print("[DST AI] ERROR: Controller not initialized")
    end
end

GLOBAL.ai_disable = function()
    if ai_controller then
        ai_controller:Disable()
        print("[DST AI] === AI CONTROL DISABLED ===")
    else
        print("[DST AI] ERROR: Controller not initialized")
    end
end

GLOBAL.ai_status = function()
    if not ai_controller then
        print("[DST AI] ERROR: Controller not initialized")
        return
    end

    local stats = ai_controller:GetStats()
    local state = ai_controller:GetCurrentState()

    print("[DST AI] ===== STATUS =====")
    print("[DST AI] Enabled: " .. tostring(stats.enabled))
    print("[DST AI] Connected: " .. tostring(stats.connected))
    print("[DST AI] Cycles: " .. tostring(stats.cycles))
    print("[DST AI] Actions: " .. tostring(stats.actions_executed))
    print("[DST AI] Errors: " .. tostring(stats.errors))

    if state then
        print("[DST AI] ===== PLAYER =====")
        print("[DST AI] Health: " .. tostring(math.floor(state.hp * 100)) .. "%")
        print("[DST AI] Hunger: " .. tostring(math.floor(state.hu * 100)) .. "%")
        print("[DST AI] Sanity: " .. tostring(math.floor(state.sa * 100)) .. "%")
        print("[DST AI] Position: (" .. tostring(state.x) .. ", " .. tostring(state.z) .. ")")
        print("[DST AI] Day: " .. tostring(state.day))
    end
    print("[DST AI] =================")
end

GLOBAL.ai_output = function()
    if ai_controller then
        ai_controller:ForceOutputState()
        print("[DST AI] State output forced")
    else
        print("[DST AI] ERROR: Controller not initialized")
    end
end

GLOBAL.ai_pos = function()
    if ai_controller then
        local pos = ai_controller:GetPlayerPosition()
        print("[DST AI] Position: (" .. tostring(pos.x) .. ", " .. tostring(pos.y) .. ", " .. tostring(pos.z) .. ")")
        return pos
    else
        print("[DST AI] ERROR: Controller not initialized")
    end
end

GLOBAL.ai_nearby = function(radius)
    if ai_controller then
        local entities = ai_controller:FindNearbyEntities(radius)
        print("[DST AI] Found " .. #entities .. " nearby entities")
        return entities
    else
        print("[DST AI] ERROR: Controller not initialized")
    end
end

GLOBAL.ai_interval = function(frames)
    if ai_controller then
        ai_controller:SetUpdateInterval(frames)
        print("[DST AI] Update interval set to " .. tostring(frames) .. " frames")
    else
        print("[DST AI] ERROR: Controller not initialized")
    end
end

GLOBAL.ai_do = function(action_str)
    if not ai_controller then
        print("[DST AI] ERROR: Controller not initialized")
        return
    end

    if not action_str then
        print("[DST AI] Usage: ai_do('{\"type\":\"move\",\"target\":[x,y,z]}')")
        return
    end

    local success = ai_controller:ExecuteActionString(action_str)
    if success then
        print("[DST AI] Action executed successfully")
    else
        print("[DST AI] Action failed")
    end
end

GLOBAL.ai_help = function()
    print("[DST AI] ===== AVAILABLE COMMANDS =====")
    print("[DST AI] ai_enable()    - Enable AI control")
    print("[DST AI] ai_disable()   - Disable AI control")
    print("[DST AI] ai_status()    - Show AI status and game state")
    print("[DST AI] ai_output()    - Force output state to log")
    print("[DST AI] ai_pos()       - Get player position")
    print("[DST AI] ai_nearby(r)   - List nearby entities")
    print("[DST AI] ai_interval(f) - Set update interval in frames")
    print("[DST AI] ai_do(str)     - Execute action from JSON string")
    print("[DST AI] ===============================")
end

print("[DST AI] ===== Module Loaded =====")
print("[DST AI] Type ai_help() for available commands")

-- 返回模块表
return {
    controller = ai_controller,
    InitializeAI = InitializeAI
}
