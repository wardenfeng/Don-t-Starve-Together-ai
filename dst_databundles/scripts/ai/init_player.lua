-- DST AI Player - 玩家初始化（不使用 Class，避免加载问题）
-- 这个文件在玩家生成时被调用

local function InitAIForPlayer(inst)
    print("[DST AI] Initializing AI for player...")

    -- AI 控制器存储
    local ai_state = {
        enabled = false,
        frame_count = 0,
        update_interval = 10,
        state_output_interval = 30,
        last_state_output = 0
    }

    -- 加载通信模块
    local PROTOCOL = require("ai/communication/protocol")
    local FileBridge = require("ai/communication/file_bridge")
    local StateCollector = require("ai/core/state_collector")
    local ActionExecutor = require("ai/core/action_executor")
    local Json = require("ai/communication/json")

    -- 创建组件
    local file_bridge = FileBridge(inst)
    local state_collector = StateCollector(inst)
    local action_executor = ActionExecutor(inst)

    -- 启用函数
    local function Enable()
        if ai_state.enabled then
            return
        end
        ai_state.enabled = true
        ai_state.frame_count = 0
        print("[DST AI] ===== Enabled! =====")
    end

    -- 禁用函数
    local function Disable()
        ai_state.enabled = false
        if inst.components.locomotor then
            inst.components.locomotor:Stop()
        end
        print("[DST AI] Disabled")
    end

    -- 更新函数
    local function OnUpdate(dt)
        -- 检查控制命令
        local control_cmd = file_bridge:ReadControl()
        if control_cmd == "ENABLE" then
            Enable()
        elseif control_cmd == "DISABLE" then
            Disable()
        end

        -- 检查连接
        file_bridge:CheckConnection()

        ai_state.frame_count = ai_state.frame_count + 1

        -- 定期输出状态
        if ai_state.frame_count - ai_state.last_state_output >= ai_state.state_output_interval then
            local state = state_collector:CollectState()
            if state then
                local json_str = Json.encode_state(state)
                print("[DST_AI_STATE] " .. json_str)
            end
            ai_state.last_state_output = ai_state.frame_count
        end

        -- 执行命令
        if ai_state.enabled and ai_state.frame_count % ai_state.update_interval == 0 then
            local cmd = file_bridge:ReadCommand()
            if cmd then
                for _, action in ipairs(cmd.actions) do
                    action_executor:Execute(action)
                end
                file_bridge:ClearCommand()
            end
        end
    end

    -- 注册更新事件
    inst:ListenForEvent("onupdate", function(_, dt)
        OnUpdate(dt)
    end)

    -- 清理
    inst:ListenForEvent("onremove", function()
        rawset(_G, "DST_AI_ACTIVE", false)
    end)

    -- 全局标记
    rawset(_G, "DST_AI_ACTIVE", true)
    _G.ai_enable = Enable
    _G.ai_disable = Disable

    -- 自动启用
    Enable()
end

return InitAIForPlayer
