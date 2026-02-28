-- AI主控制器
-- 协调状态采集、文件通信和动作执行

local FileBridge = require("ai/communication/file_bridge")
local StateCollector = require("ai/core/state_collector")
local ActionExecutor = require("ai/core/action_executor")

local AIController = Class(function(self, inst, config)
    self.inst = inst
    self.config = config or {}

    -- 初始化组件
    self.file_bridge = FileBridge.new(inst, config)
    self.state_collector = StateCollector.new(inst)
    self.action_executor = ActionExecutor.new(inst)

    -- 配置参数
    self.update_interval = self.config.update_interval or 10  -- 帧间隔
    self.state_collector:SetScanRadius(self.config.scan_radius or 20)
    self.state_collector:SetMaxEntities(self.config.max_entities or 15)

    -- 控制状态
    self.enabled = false
    self.frame_count = 0

    -- 统计信息
    self.stats = {
        cycles = 0,
        actions_executed = 0,
        errors = 0,
        last_state_time = 0,
        last_command_time = 0
    }

    -- 统计写入计时器
    self.stats_write_interval = 1  -- 秒
    self.last_stats_write = 0

    -- 连接状态检查计时器
    self.connection_check_interval = 2  -- 秒
    self.last_connection_check = 0
end)

-- 启用AI控制器
function AIController:Enable()
    if self.enabled then
        print("[DST AI] Already enabled")
        return
    end

    self.enabled = true
    self.frame_count = 0

    -- 监听游戏更新事件
    self.inst:ListenForEvent("onupdate", function(inst, dt)
        if self.enabled then
            self:OnUpdate(dt)
        end
    end)

    print("[DST AI] ========== Controller Enabled ==========")
    print("[DST AI] Update Interval: " .. self.update_interval .. " frames")
    print("[DST AI] Sync Directory: " .. self.file_bridge.sync_dir)
    print("[DST AI] Scan Radius: " .. self.state_collector.scan_radius)
    print("[DST AI] =======================================")
end)

-- 禁用AI控制器
function AIController:Disable()
    self.enabled = false

    -- 写入最终统计
    self:WriteStats()

    print("[DST AI] Controller Disabled")
    print("[DST AI] Final Stats - Cycles: " .. self.stats.cycles ..
          ", Actions: " .. self.stats.actions_executed ..
          ", Errors: " .. self.stats.errors)
end)

-- 检查是否启用
function AIController:IsEnabled()
    return self.enabled
end)

-- 检查连接状态
function AIController:IsConnected()
    return self.file_bridge:IsConnected()
end)

-- 游戏更新回调
function AIController:OnUpdate(dt)
    self.frame_count = self.frame_count + 1

    -- 控制更新频率
    if self.frame_count < self.update_interval then
        return
    end
    self.frame_count = 0

    -- 定期检查连接状态
    local current_time = GetTime()
    if current_time - self.last_connection_check >= self.connection_check_interval then
        self.file_bridge:CheckConnection()
        self.last_connection_check = current_time
    end

    -- 执行AI循环
    self:AICycle()

    -- 定期写入统计信息
    if current_time - self.last_stats_write >= self.stats_write_interval then
        self:WriteStats()
        self.last_stats_write = current_time
    end
end)

-- AI主循环
function AIController:AICycle()
    self.stats.cycles = self.stats.cycles + 1

    -- 1. 读取控制命令 (enable/disable)
    local control = self.file_bridge:ReadControl()
    if control == "disable" then
        self:Disable()
        return
    elseif control == "enable" then
        if not self.enabled then
            self:Enable()
        end
    end

    -- 2. 采集游戏状态
    local state = self.state_collector:CollectState()
    if not state then
        return
    end

    -- 3. 通过文件发送状态
    local written = self.file_bridge:WriteState(state)
    if not written then
        return
    end
    self.stats.last_state_time = GetTimeRealMS()

    -- 4. 读取AI命令
    local cmd = self.file_bridge:ReadCommand()
    if not cmd then
        return
    end

    -- 5. 执行动作
    if cmd.actions and #cmd.actions > 0 then
        for _, action in ipairs(cmd.actions) do
            self:ExecuteAction(action)
        end
        self.stats.last_command_time = GetTimeRealMS()
    end
end)

-- 执行单个动作
function AIController:ExecuteAction(action)
    local success, result = pcall(function()
        return self.action_executor:Execute(action)
    end)

    if success and result then
        self.stats.actions_executed = self.stats.actions_executed + 1
    else
        self.stats.errors = self.stats.errors + 1
        print("[DST AI] Action error: " .. tostring(action.type) .. " - " .. tostring(result))
    end
end)

-- 写入统计信息
function AIController:WriteStats()
    self.file_bridge:WriteStats(self.enabled, self.stats)
end)

-- 获取统计信息
function AIController:GetStats()
    local combined = {
        cycles = self.stats.cycles,
        actions_executed = self.stats.actions_executed,
        errors = self.stats.errors,
        enabled = self.enabled,
        connected = self:IsConnected(),
        last_state_time = self.stats.last_state_time,
        last_command_time = self.stats.last_command_time
    }

    -- 添加文件桥接统计
    local bridge_stats = self.file_bridge:GetStats()
    if bridge_stats then
        combined.file_writes = bridge_stats.writes
        combined.file_reads = bridge_stats.reads
        combined.file_errors = bridge_stats.errors
    end

    -- 添加动作执行器统计
    local executor_stats = self.action_executor:GetStats()
    if executor_stats then
        combined.executor_executed = executor_stats.executed
        combined.executor_failed = executor_stats.failed
        combined.actions_by_type = executor_stats.by_type
    end

    return combined
end)

-- 重置统计
function AIController:ResetStats()
    self.stats = {
        cycles = 0,
        actions_executed = 0,
        errors = 0,
        last_state_time = 0,
        last_command_time = 0
    }
    self.file_bridge:ResetStats()
    self.action_executor:ResetStats()
end)

-- 设置更新间隔
function AIController:SetUpdateInterval(interval)
    self.update_interval = interval or 10
    print("[DST AI] Update interval set to " .. self.update_interval .. " frames")
end)

-- 设置扫描半径
function AIController:SetScanRadius(radius)
    self.state_collector:SetScanRadius(radius)
    print("[DST AI] Scan radius set to " .. radius)
end)

-- 设置最大实体数
function AIController:SetMaxEntities(count)
    self.state_collector:SetMaxEntities(count)
    print("[DST AI] Max entities set to " .. count)
end)

-- 获取当前游戏状态（用于调试）
function AIController:GetCurrentState()
    return self.state_collector:CollectState()
end)

return AIController
