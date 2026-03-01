-- DST AI Player - 手动初始化版本
print("[DST AI] ===== Module Loaded =====")
print("[DST AI] Type ai_init() to initialize AI controller")

local ai_controller = nil

-- 手动初始化命令
_G.ai_init = function()
    if ai_controller then
        print("[DST AI] Already initialized")
        return
    end

    local player = ThePlayer
    if not player then
        print("[DST AI] ERROR: No player entity")
        return
    end

    print("[DST AI] Initializing for: " .. (player:GetDisplayName() or "Unknown"))

    pcall(function()
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
        end)

        print("[DST AI] Controller initialized successfully")
    end)
end

_G.ai_help = function()
    print("[DST AI] Commands:")
    print("  ai_init()   - Initialize AI controller")
    print("  ai_enable() - Enable AI control")
    print("  ai_disable() - Disable AI control")
    print("  ai_status() - Show AI status")
end

_G.ai_enable = function()
    if ai_controller then
        ai_controller:Enable()
        print("[DST AI] Enabled")
    else
        print("[DST AI] ERROR: Not initialized. Run ai_init() first")
    end
end

_G.ai_disable = function()
    if ai_controller then
        ai_controller:Disable()
        print("[DST AI] Disabled")
    end
end

_G.ai_status = function()
    if ai_controller then
        local stats = ai_controller:GetStats()
        print("[DST AI] Enabled: " .. tostring(stats.enabled))
        print("[DST AI] Connected: " .. tostring(stats.connected))
    else
        print("[DST AI] Not initialized. Run ai_init() first")
    end
end

return {}
