-- DST AI Player - 简化 JSON 序列化/反序列化
-- DST Lua 环境中没有内置 JSON，需要手动实现

local Json = {}

-- 协议版本常量 (避免循环依赖)
local PROTOCOL_VERSION = 1

-- 字符转义
local function escape_char(c)
    local escapes = {
        ['"'] = '\\"',
        ['\\'] = '\\\\',
        ['\b'] = '\\b',
        ['\f'] = '\\f',
        ['\n'] = '\\n',
        ['\r'] = '\\r',
        ['\t'] = '\\t'
    }
    return escapes[c] or string.format('\\u%04x', string.byte(c))
end

-- 转义字符串
local function escape_string(s)
    return s:gsub('[%c\\"]', escape_char)
end

-- 序列化 (简化版，仅支持协议需要的数据结构)
function Json.encode(data)
    local t = type(data)

    if t == "nil" then
        return "null"
    elseif t == "string" then
        return '"' .. escape_string(data) .. '"'
    elseif t == "number" then
        -- 检查是否是整数
        if data == math.floor(data) then
            return tostring(math.floor(data))
        else
            return string.format("%.6g", data)
        end
    elseif t == "boolean" then
        return data and "true" or "false"
    elseif t == "table" then
        -- 判断是数组还是对象
        local is_array = true
        local max_index = 0
        local has_keys = false

        for k, v in pairs(data) do
            if type(k) ~= "number" then
                is_array = false
                has_keys = true
                break
            end
            max_index = math.max(max_index, k)
        end

        -- 检查数组是否连续
        if is_array and max_index > 0 then
            for i = 1, max_index do
                if data[i] == nil then
                    is_array = false
                    break
                end
            end
        end

        local parts = {}

        if is_array then
            -- 数组格式
            for i = 1, max_index do
                table.insert(parts, Json.encode(data[i]))
            end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            -- 对象格式
            for k, v in pairs(data) do
                local key = type(k) == "string" and '"' .. escape_string(k) .. '"' or tostring(k)
                table.insert(parts, key .. ":" .. Json.encode(v))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    else
        return "null"
    end
end

-- 简化的 JSON 解析 (使用 DST 内置的 lume 如果可用)
function Json.decode(str)
    -- 尝试使用 DST 内置的 lume (如果可用)
    if lume and lume.jsondecode then
        local success, result = pcall(lume.jsondecode, str)
        if success then
            return result
        end
    end

    -- 简单的手动解析 (仅支持基础格式)
    local function parse_value(s, pos)
        local char = s:sub(pos, pos)

        -- 跳过空白
        while char and char:match("%s") do
            pos = pos + 1
            char = s:sub(pos, pos)
        end

        -- null
        if s:sub(pos, pos + 3) == "null" then
            return nil, pos + 4
        end

        -- true
        if s:sub(pos, pos + 3) == "true" then
            return true, pos + 4
        end

        -- false
        if s:sub(pos, pos + 4) == "false" then
            return false, pos + 5
        end

        -- 字符串
        if char == '"' then
            local end_pos = pos + 1
            while true do
                end_pos = s:find('"', end_pos)
                if not end_pos then return nil, pos end
                -- 检查是否转义
                if s:sub(end_pos - 1, end_pos - 1) ~= '\\' then
                    break
                end
                end_pos = end_pos + 1
            end
            local str = s:sub(pos + 1, end_pos - 1)
            -- 处理转义字符 (简化版)
            str = str:gsub('\\"', '"'):gsub('\\n', '\n'):gsub('\\t', '\t'):gsub('\\\\', '\\')
            return str, end_pos + 1
        end

        -- 数字
        if char:match("[%d%-]") then
            local num_end = pos
            while s:sub(num_end + 1, num_end + 1):match("[%d%.eE%+%-%]") do
                num_end = num_end + 1
            end
            local num_str = s:sub(pos, num_end)
            local num = tonumber(num_str)
            return num, num_end + 1
        end

        -- 数组
        if char == '[' then
            local arr = {}
            pos = pos + 1
            while s:sub(pos, pos) and s:sub(pos, pos) ~= ']' do
                local val, new_pos = parse_value(s, pos)
                if val ~= nil or new_pos > pos then
                    table.insert(arr, val)
                end
                pos = new_pos
                if s:sub(pos, pos) == ',' then
                    pos = pos + 1
                end
            end
            return arr, pos + 1
        end

        -- 对象
        if char == '{' then
            local obj = {}
            pos = pos + 1
            while s:sub(pos, pos) and s:sub(pos, pos) ~= '}' do
                local key, new_pos = parse_value(s, pos)
                pos = new_pos
                if s:sub(pos, pos) == ':' then
                    pos = pos + 1
                end
                local val, new_pos2 = parse_value(s, pos)
                obj[key] = val
                pos = new_pos2
                if s:sub(pos, pos) == ',' then
                    pos = pos + 1
                end
            end
            return obj, pos + 1
        end

        return nil, pos
    end

    local result, end_pos = parse_value(str, 1)
    return result
end

-- 格式化状态为协议格式 (缩写字段)
function Json.encode_state(state)
    local obj = {
        v = state.v or PROTOCOL_VERSION,
        hp = state.hp or 1,
        hu = state.hu or 1,
        sa = state.sa or 1,
        x = state.x or 0,
        z = state.z or 0,
        day = state.day or 1,
        time = state.time or 0
    }

    -- 添加实体列表 (如果有)
    if state.entities and #state.entities > 0 then
        obj.e = {}
        for _, ent in ipairs(state.entities) do
            table.insert(obj.e, {
                p = ent.p or ent.prefab or "unknown",
                n = ent.n or ent.name or "",
                x = ent.x or 0,
                z = ent.z or 0,
                d = ent.d or ent.distance or 0,
                notes = ent.notes or ""
            })
        end
    end

    -- 添加背包物品 (如果有)
    if state.inventory and #state.inventory > 0 then
        obj.i = {}
        for _, item in ipairs(state.inventory) do
            table.insert(obj.i, {
                p = item.p or item.prefab or "unknown",
                n = item.n or item.name or "",
                s = item.s or item.stack or 1
            })
        end
    end

    return Json.encode(obj)
end

return Json
