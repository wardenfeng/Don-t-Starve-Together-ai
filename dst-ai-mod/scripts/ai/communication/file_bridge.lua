-- 文件通信桥接层
-- 封装所有文件I/O操作，提供状态写入和命令读取接口

local FileBridge = Class(function(self, inst, config)
    self.inst = inst
    self.sync_dir = config.sync_dir or "C:\\dst-ai-sync\\"

    -- 文件路径
    self.files = {
        state_out = self.sync_dir .. "state.txt",
        cmd_in = self.sync_dir .. "cmd.txt",
        status_in = self.sync_dir .. "status.txt",
        control_in = self.sync_dir .. "control.txt",
        stats_out = self.sync_dir .. "stats.txt"
    }

    -- 连接状态
    self.is_connected = false

    -- 写入限制
    self.write_interval = 0.1  -- 秒
    self.last_write_time = 0

    -- 序列号（用于命令去重）
    self.last_cmd_seq = 0

    -- 统计信息
    self.stats = {
        writes = 0,
        reads = 0,
        errors = 0
    }

    -- 延迟初始化（确保游戏已加载）
    self.inst:DoTaskInTime(0, function()
        self:CheckConnection()
    end)
end)

-- 检查连接状态
function FileBridge:CheckConnection()
    local file = io.open(self.files.status_in, "r")
    if not file then
        self.is_connected = false
        return false
    end

    local status = file:read("*all")
    file:close()

    self.is_connected = (status == "CONNECTED")
    return self.is_connected
end)

-- 获取连接状态
function FileBridge:IsConnected()
    return self.is_connected
end)

-- 写入状态文件
function FileBridge:WriteState(state_data)
    local current_time = GetTime()

    -- 限制写入频率
    if current_time - self.last_write_time < self.write_interval then
        return false
    end
    self.last_write_time = current_time

    -- 序列化状态
    local json_str = self:SerializeState(state_data)

    -- 写入文件
    local file = io.open(self.files.state_out, "w")
    if not file then
        self.stats.errors = self.stats.errors + 1
        return false
    end

    file:write(json_str)
    file:close()

    self.stats.writes = self.stats.writes + 1
    return true
end)

-- 读取命令文件
function FileBridge:ReadCommand()
    -- 检查连接状态
    self:CheckConnection()
    if not self.is_connected then
        return nil
    end

    local file = io.open(self.files.cmd_in, "r")
    if not file then
        return nil
    end

    local content = file:read("*all")
    file:close()

    if not content or content == "" then
        return nil
    end

    -- 解析命令
    local success, cmd = pcall(function()
        return self:DeserializeCommand(content)
    end)

    if success and cmd then
        -- 检查序列号，避免重复执行
        if cmd.seq and cmd.seq <= self.last_cmd_seq then
            return nil  -- 已执行过
        end

        if cmd.seq then
            self.last_cmd_seq = cmd.seq
        end

        self.stats.reads = self.stats.reads + 1
        return cmd
    end

    self.stats.errors = self.stats.errors + 1
    return nil
end)

-- 读取控制命令 (enable/disable)
function FileBridge:ReadControl()
    local file = io.open(self.files.control_in, "r")
    if not file then
        return nil
    end

    local content = file:read("*all")
    file:close()

    if not content or content == "" then
        return nil
    end

    -- 清空文件
    local clear_file = io.open(self.files.control_in, "w")
    if clear_file then
        clear_file:close()
    end

    local command = content:match("^%s*(%w+)%s*$")
    if command == "ENABLE" then
        return "enable"
    elseif command == "DISABLE" then
        return "disable"
    end

    return nil
end)

-- 写入统计信息
function FileBridge:WriteStats(enabled, stats)
    local stats_table = {
        enabled = enabled,
        cycles = stats.cycles or 0,
        actions = stats.actions_executed or 0,
        errors = stats.errors or 0,
        timestamp = GetTimeRealMS()
    }

    -- 简化JSON序列化
    local json_str = string.format(
        '{"enabled":%s,"cycles":%d,"actions":%d,"errors":%d,"timestamp":%d}',
        tostring(enabled),
        stats_table.cycles,
        stats_table.actions,
        stats_table.errors,
        stats_table.timestamp
    )

    local file = io.open(self.files.stats_out, "w")
    if file then
        file:write(json_str)
        file:close()
    end
end)

-- 序列化状态 (简化JSON，不依赖外部库)
function FileBridge:SerializeState(state)
    local parts = {}

    -- 基本信息
    table.insert(parts, "\"v\":1")
    table.insert(parts, "\"t\":" .. tostring(GetTimeRealMS()))

    -- 玩家状态
    if state.player then
        local p = state.player
        local pos_str = string.format("[%0.1f,0,%0.1f]", p.position.x, p.position.z)
        local player_parts = {}
        table.insert(player_parts, "\"hp\":" .. string.format("%0.2f", p.health))
        table.insert(player_parts, "\"hu\":" .. string.format("%0.2f", p.hunger))
        table.insert(player_parts, "\"sa\":" .. string.format("%0.2f", p.sanity))
        table.insert(player_parts, "\"pos\":" .. pos_str)
        table.insert(parts, "\"p\":{" .. table.concat(player_parts, ",") .. "}")
    end

    -- 世界状态
    if state.world then
        local w = state.world
        local world_parts = {}
        table.insert(world_parts, "\"day\":" .. tostring(w.day or 0))
        table.insert(world_parts, "\"time\":" .. string.format("%0.2f", w.time or 0))
        table.insert(world_parts, "\"season\":\"" .. (w.season or "unknown") .. "\"")
        table.insert(world_parts, "\"isDay\":" .. tostring(w.isday))
        if w.moonphase then
            table.insert(world_parts, "\"moon\":\"" .. w.moonphase .. "\"")
        end
        table.insert(parts, "\"w\":{" .. table.concat(world_parts, ",") .. "}")
    end

    -- 实体列表
    if state.entities and #state.entities > 0 then
        local entity_parts = {}
        for _, e in ipairs(state.entities) do
            local pos_str = string.format("[%0.1f,0,%0.1f]", e.position.x, e.position.z)
            local entity_str = string.format(
                '{"p":"%s","pos":%s,"d":%0.1f}',
                e.prefab,
                pos_str,
                e.distance
            )
            table.insert(entity_parts, entity_str)
        end
        table.insert(parts, "\"e\":[" .. table.concat(entity_parts, ",") .. "]")
    else
        table.insert(parts, "\"e\":[]")
    end

    -- 背包物品
    if state.inventory and #state.inventory > 0 then
        local inv_parts = {}
        for _, i in ipairs(state.inventory) do
            local item_str = string.format('{"p":"%s","n":%d}', i.prefab, i.count)
            table.insert(inv_parts, item_str)
        end
        table.insert(parts, "\"i\":[" .. table.concat(inv_parts, ",") .. "]")
    else
        table.insert(parts, "\"i\":[]")
    end

    return "{" .. table.concat(parts, ",") .. "}"
end)

-- 反序列化命令
function FileBridge:DeserializeCommand(json_str)
    -- 使用DST内置的lume.jsondecode (如果可用)
    if lume and lume.jsondecode then
        return lume.jsondecode(json_str)
    end

    -- 简单的JSON解析
    local cmd = {
        actions = {},
        seq = nil
    }

    -- 提取序列号
    local seq_match = json_str:match('"seq"%s*:%s*(%d+)')
    if seq_match then
        cmd.seq = tonumber(seq_match)
    end

    -- 提取动作数组
    local actions_start = json_str:match('"a"%s*:%s*%[') or json_str:match('"actions"%s*:%s*%[')
    if actions_start then
        -- 查找actions数组的内容
        local array_content = json_str:match('%b[]')
        if array_content then
            -- 解析每个action对象
            for obj_str in array_content:gmatch('{[^}]*}') do
                local action = self:ParseAction(obj_str)
                if action then
                    table.insert(cmd.actions, action)
                end
            end
        end
    end

    return cmd
end)

-- 解析单个动作
function FileBridge:ParseAction(action_str)
    local type_match = action_str:match('"type"%s*:%s*"([^"]*)"')
    if not type_match then
        return nil
    end

    local action = { type = type_match }

    -- 解析目标位置 (用于move)
    if type_match == "move" then
        local target_str = action_str:match('"target"%s*:%s*%[([%d%.,%-%s]*)')
        if target_str then
            local coords = {}
            for num in target_str:gmatch("[-%d%.]+") do
                table.insert(coords, tonumber(num))
            end
            if #coords >= 3 then
                action.target = { x = coords[1], y = coords[2], z = coords[3] }
            end
        end
    end

    -- 解析实体引用
    local entity = action_str:match('"entity"%s*:%s*"([^"]*)"')
    if entity then
        action.entity = entity
    end

    return action
end)

-- 获取统计信息
function FileBridge:GetStats()
    return self.stats
end)

-- 重置统计
function FileBridge:ResetStats()
    self.stats = {
        writes = 0,
        reads = 0,
        errors = 0
    }
end

return FileBridge
