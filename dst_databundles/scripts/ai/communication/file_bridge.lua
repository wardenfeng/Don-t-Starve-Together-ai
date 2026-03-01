-- DST AI Player - 文件通信桥接器
-- 封装所有文件 I/O 操作，与 MCP 服务器通信

local PROTOCOL = require("ai/communication/protocol")

local FileBridge = Class(function(self, inst)
    self.inst = inst
    self.sync_dir = PROTOCOL.SYNC_DIR
    self.connected = false
    self.last_command_seq = 0

    -- 文件内容缓存
    self.file_cache = {
        [PROTOCOL.FILES.CMD_IN] = { content = "", mtime = 0 },
        [PROTOCOL.FILES.STATUS_IN] = { content = "", mtime = 0 },
        [PROTOCOL.FILES.CONTROL_IN] = { content = "", mtime = 0 }
    }

    PROTOCOL.log("FileBridge initialized with sync dir: " .. self.sync_dir)
end

-- 检查连接状态 (读取 status.txt)
function FileBridge:CheckConnection()
    local content = self:ReadFile(PROTOCOL.FILES.STATUS_IN)
    if content and PROTOCOL.trim(content) == PROTOCOL.CONNECTION_STATUS.CONNECTED then
        if not self.connected then
            PROTOCOL.log("Connected to MCP server")
        end
        self.connected = true
    else
        if self.connected then
            PROTOCOL.log("Disconnected from MCP server")
        end
        self.connected = false
    end
    return self.connected
end

-- 获取连接状态
function FileBridge:IsConnected()
    return self.connected
end

-- 读取文件内容 (带缓存)
function FileBridge:ReadFile(filename)
    local filepath = self.sync_dir .. filename

    local file = io.open(filepath, "r")
    if not file then
        return nil
    end

    local content = file:read("*all")
    file:close()

    -- 更新缓存
    if self.file_cache[filename] then
        self.file_cache[filename].content = content
        self.file_cache[filename].mtime = GetTime() or 0
    end

    return content
end

-- 检查文件是否变化
function FileBridge:HasFileChanged(filename)
    local filepath = self.sync_dir .. filename

    local file = io.open(filepath, "r")
    if not file then
        return false
    end

    local content = file:read("*all")
    file:close()

    local cached = self.file_cache[filename]
    if not cached then
        return true
    end

    return content ~= cached.content
end

-- 读取命令文件
function FileBridge:ReadCommand()
    if not self:HasFileChanged(PROTOCOL.FILES.CMD_IN) then
        return nil
    end

    local content = self:ReadFile(PROTOCOL.FILES.CMD_IN)
    if not content or PROTOCOL.trim(content) == "" then
        return nil
    end

    -- 解析 JSON 命令
    local Json = require("ai/communication/json")
    local success, cmd = pcall(Json.decode, content)

    if not success or not cmd then
        PROTOCOL.error("Failed to parse command: " .. tostring(content))
        return nil
    end

    -- 检查序列号，防止重复执行
    if cmd.seq and cmd.seq <= self.last_command_seq then
        -- 已处理过的命令
        return nil
    end

    -- 更新序列号
    if cmd.seq then
        self.last_command_seq = cmd.seq
    end

    -- 解析动作列表 (支持简写 'a' 和完整 'actions')
    local actions = cmd.a or cmd.actions
    if not actions then
        return nil
    end

    PROTOCOL.log("Received command seq=" .. tostring(cmd.seq) .. " with " .. #actions .. " action(s)")

    return {
        seq = cmd.seq,
        actions = actions
    }
end

-- 读取控制命令
function FileBridge:ReadControl()
    if not self:HasFileChanged(PROTOCOL.FILES.CONTROL_IN) then
        return nil
    end

    local content = self:ReadFile(PROTOCOL.FILES.CONTROL_IN)
    if not content then
        return nil
    end

    local cmd = PROTOCOL.trim(content):upper()
    if cmd == PROTOCOL.CONTROL_COMMANDS.ENABLE then
        PROTOCOL.log("Received ENABLE command")
        return "ENABLE"
    elseif cmd == PROTOCOL.CONTROL_COMMANDS.DISABLE then
        PROTOCOL.log("Received DISABLE command")
        return "DISABLE"
    end

    return nil
end

-- 写入统计信息
function FileBridge:WriteStats(enabled, stats)
    local filepath = self.sync_dir .. PROTOCOL.FILES.STATS_OUT

    local data = {
        enabled = enabled,
        connected = self.connected,
        cycles = stats.cycles or 0,
        actions = stats.actions or 0,
        errors = stats.errors or 0,
        timestamp = math.floor((GetTime() or 0) * 1000)
    }

    local Json = require("ai/communication/json")
    local content = Json.encode(data)

    local file = io.open(filepath, "w")
    if not file then
        PROTOCOL.error("Failed to write stats to " .. filepath)
        return false
    end

    file:write(content)
    file:close()

    return true
end

-- 清空命令文件 (确认已处理)
function FileBridge:ClearCommand()
    local filepath = self.sync_dir .. PROTOCOL.FILES.CMD_IN

    local file = io.open(filepath, "w")
    if not file then
        return false
    end

    file:write("")
    file:close()

    -- 更新缓存
    self.file_cache[PROTOCOL.FILES.CMD_IN].content = ""

    return true
end

return FileBridge
