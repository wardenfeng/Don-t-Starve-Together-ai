-- DST AI Player - AI 主控制器
-- 协调状态采集、文件通信和动作执行

local PROTOCOL = require("ai/communication/protocol")
local FileBridge = require("ai/communication/file_bridge")
local StateCollector = require("ai/core/state_collector")
local ActionExecutor = require("ai/core/action_executor")
local Json = require("ai/communication/json")

local AIController = Class(function(self, inst, config)
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
    self.state_output_interval = self.config.state_output_interval or 30  -- 约 0.5 秒
    self.last_state_output = 0

    PROTOCOL.log("AI Controller initialized")
end)

-- 启用 AI 控制器
function AIController:Enable()
    if self.enabled then
        PROTOCOL.log("AI already enabled")
        return
    end

    self.enabled = true
    self.frame_count = 0

    PROTOCOL.log("AI Controller enabled")

    -- 立即输出一次状态
    self:OutputState()
end)

-- 禁用 AI 控制器
function AIController:Disable()
    if not self.enabled then
        return
    end

    self.enabled = false

    -- 停止移动
    if self.inst.components.locomotor then
        self.inst.components.locomotor:Stop()
    end

    PROTOCOL.log("AI Controller disabled")
end)

-- 检查是否启用
function AIController:IsEnabled()
    return self.enabled
end)

-- 游戏更新回调
function AIController:OnUpdate(dt)
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
        -- 即使未启用，也定期输出状态以保持连接
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

    -- 定期写入统计信息
    if self.frame_count % 60 == 0 then  -- 每秒一次
        self:WriteStats()
    end
end)

-- AI 主循环
function AIController:AICycle()
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
end)

-- 执行单个动作
function AIController:ExecuteAction(action)
    local success = self.action_executor:Execute(action)

    if success then
        self.stats.actions_executed = self.stats.actions_executed + 1
    else
        self.stats.errors = self.stats.errors + 1
    end

    return success
end)

-- 输出状态到日志
function AIController:OutputState()
    -- 采集游戏状态
    local state = self.state_collector:CollectState()
    if not state then
        return
    end

    -- 序列化为 JSON
    local json_str = Json.encode_state(state)

    -- 输出到日志 (MCP 服务器会解析)
    print("[DST_AI_STATE] " .. json_str)

    self.stats.last_state_time = GetTime() or 0
end)

-- 写入统计信息
function AIController:WriteStats()
    local action_stats = self.action_executor:GetStats()

    local stats = {
        cycles = self.stats.cycles,
        actions = self.stats.actions_executed,
        errors = self.stats.errors
    }

    self.file_bridge:WriteStats(self.enabled, stats)
end)

-- 获取统计信息
function AIController:GetStats()
    local action_stats = self.action_executor:GetStats()
    local connected = self.file_bridge:IsConnected()

    return {
        enabled = self.enabled,
        connected = connected,
        cycles = self.stats.cycles,
        actions_executed = self.stats.actions_executed,
        errors = self.stats.errors,
        action_stats = action_stats
    }
end)

-- 手动触发状态输出
function AIController:ForceOutputState()
    self:OutputState()
end)

-- 手动执行动作
function AIController:ExecuteActionString(action_str)
    local Json = require("ai/communication/json")
    local success, action = pcall(Json.decode, action_str)

    if success and action then
        return self:ExecuteAction(action)
    end

    return false
end)

-- 获取当前状态
function AIController:GetCurrentState()
    return self.state_collector:CollectState()
end)

-- 设置更新间隔
function AIController:SetUpdateInterval(interval)
    self.update_interval = interval or PROTOCOL.UPDATE_INTERVAL
    PROTOCOL.log("Update interval set to " .. self.update_interval .. " frames")
end)

-- 获取玩家位置
function AIController:GetPlayerPosition()
    return self.state_collector:GetPlayerPosition()
end)

-- 查找附近实体
function AIController:FindNearbyEntities(radius)
    local pos = self.inst:GetPosition()
    local search_radius = radius or 20

    local entities = TheSim:FindEntities(
        pos.x, pos.y, pos.z,
        search_radius,
        nil, -- any tag
        nil, -- must have tags
        { "FX", "NOCLICK", "DECOR", "INLIMBO" }
    )

    local result = {}
    for _, ent in ipairs(entities) do
        if ent ~= self.inst then
            table.insert(result, {
                prefab = ent.prefab,
                name = ent:GetDisplayName(),
                position = ent:GetPosition()
            })
        end
    end

    return result
end)

return AIController
