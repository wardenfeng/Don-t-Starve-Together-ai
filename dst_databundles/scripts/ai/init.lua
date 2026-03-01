-- DST AI Player - 智能自动初始化版本
print("[DST AI] ===== Module Loaded =====")

local ai_controller = nil
local check_count = 0

-- 包装控制器函数，自动初始化
local function EnsureController()
    if ai_controller then
        return ai_controller
    end

    local player = ThePlayer
    if not player or not player:IsValid() then
        return nil
    end

    print("[DST AI] Auto-initializing...")

    local success, err = pcall(function()
        local AIController = require("ai/core/controller")
        ai_controller = AIController(player, {
            update_interval = 10,
            scan_radius = 20,
            state_output_interval = 30
        })

        player:ListenForEvent("onupdate", function(_, dt)
            if ai_controller and ai_controller:IsEnabled() then
                ai_controller:OnUpdate(dt)
            end
        end)

        player:ListenForEvent("onremove", function()
            ai_controller = nil
            check_count = 0
        end)

        -- 自动启用
        ai_controller:Enable()
        print("[DST AI] Auto-initialized and enabled!")
    end)

    if not success then
        print("[DST AI] Init error: " .. tostring(err))
    end

    return ai_controller
end

-- 包装命令，自动初始化
_G.ai_enable = function()
    local ctrl = EnsureController()
    if ctrl then
        print("[DST AI] Already enabled")
    else
        print("[DST AI] ERROR: Could not initialize")
    end
end

_G.ai_disable = function()
    if ai_controller then
        ai_controller:Disable()
        print("[DST AI] Disabled")
    end
end

_G.ai_status = function()
    local ctrl = EnsureController()
    if ctrl then
        local stats = ctrl:GetStats()
        print("[DST AI] Enabled: " .. tostring(stats.enabled))
        print("[DST AI] Connected: " .. tostring(stats.connected))
    else
        print("[DST AI] Not ready - make sure you're in-game")
    end
end

_G.ai_help = function()
    print("[DST AI] ===== Auto-Init AI =====")
    print("[DST AI] AI will automatically initialize when you enter the game")
    print("[DST AI] Commands:")
    print("  ai_status() - Show AI status")
    print("  ai_disable() - Disable AI")
end

return {}
