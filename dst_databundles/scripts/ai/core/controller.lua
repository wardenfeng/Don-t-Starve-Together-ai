-- DST AI Player - AI 主控制器（不使用 Class）
-- 协调状态采集、文件通信和动作执行

local PROTOCOL = require("ai/communication/protocol")
local FileBridge = require("ai/communication/file_bridge")
local StateCollector = require("ai/core/state_collector")
local ActionExecutor = require("ai/core/action_executor")
local Json = require("ai/communication/json")

-- 创建 AI 控制器
local function CreateAIController(inst, config)
    local self = {}
    self.inst = inst
    self.config = config or {}

    -- 创建子组件
    self.file_bridge = FileBridge(inst)
    self.state_collector = StateCollector(inst)
    self.action_executor = ActionExecutor(inst)

    -- 状态
    self.enabled = false
    self.frame_count = 0
    self.update_interval = self.config.update_interval or PROTOCOL.UPDATE_INTERVAL

    -- 统计信息
    self.stats = {
        cycles = 0,
        actions_executed = 0,
        errors = 0,
        last_state_time = 0
    }

    -- 状态输出间隔 (帧)
    self.state_output_interval = self.config.state_output_interval or 30
    self.last_state_output = 0

    -- 启用 AI 控制器
    function self:Enable()
        if self.enabled then
            PROTOCOL.log("AI already enabled")
            return
        end

        self.enabled = true
        self.frame_count = 0
        PROTOCOL.log("AI Controller enabled")
        self:OutputState()
    end

    -- 禁用 AI 控制器
    function self:Disable()
        if not self.enabled then
            return
        end

        self.enabled = false

        -- 停止移动
        if self.inst.components.locomotor then
            self.inst.components.locomotor:Stop()
        end

        PROTOCOL.log("AI Controller disabled")
    end

    -- 检查是否启用
    function self:IsEnabled()
        return self.enabled
    end

    -- 游戏更新回调
    function self:OnUpdate(dt)
        -- 检查控制命令
        local control_cmd = self.file_bridge:ReadControl()
        if control_cmd == "ENABLE" then
            self:Enable()
        elseif control_cmd == "DISABLE" then
            self:Disable()
        end

        -- 检查连接状态
        self.file_bridge:CheckConnection()

        -- 如果未启用，只输出状态
        if not self.enabled then
            self.frame_count = self.frame_count + 1
            if self.frame_count - self.last_state_output >= self.state_output_interval then
                self:OutputState()
                self.last_state_output = self.frame_count
            end
            return
        end

        -- AI 主循环
        self.frame_count = self.frame_count + 1

        if self.frame_count % self.update_interval == 0 then
            self:AICycle()
        end

        -- 定期输出状态
        if self.frame_count - self.last_state_output >= self.state_output_interval then
            self:OutputState()
            self.last_state_output = self.frame_count
        end
    end

    -- AI 主循环
    function self:AICycle()
        self.stats.cycles = self.stats.cycles + 1

        -- 读取并执行命令
        local cmd = self.file_bridge:ReadCommand()
        if cmd then
            PROTOCOL.log("Processing command seq=" .. tostring(cmd.seq))

            -- 执行所有动作
            for _, action in ipairs(cmd.actions) do
                self:ExecuteAction(action)
            end

            -- 清空命令文件
            self.file_bridge:ClearCommand()
        end
    end

    -- 执行单个动作
    function self:ExecuteAction(action)
        local success = self.action_executor:Execute(action)

        if success then
            self.stats.actions_executed = self.stats.actions_executed + 1
        else
            self.stats.errors = self.stats.errors + 1
        end

        return success
    end

    -- 输出状态到日志
    function self:OutputState()
        local state = self.state_collector:CollectState()
        if not state then
            return
        end

        local json_str = Json.encode_state(state)
        print("[DST_AI_STATE] " .. json_str)
        self.stats.last_state_time = GetTime() or 0
    end

    -- 获取统计信息
    function self:GetStats()
        local connected = self.file_bridge:IsConnected()

        return {
            enabled = self.enabled,
            connected = connected,
            cycles = self.stats.cycles,
            actions_executed = self.stats.actions_executed,
            errors = self.stats.errors
        }
    end

    PROTOCOL.log("AI Controller initialized")
    return self
end

return CreateAIController
