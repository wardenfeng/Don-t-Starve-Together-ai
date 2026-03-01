-- DST AI Player - 文件I/O测试
-- 验证客户端Mod是否可以读写文件

local SYNC_DIR = "C:\\dst-ai-sync\\"
local TEST_FILE = SYNC_DIR .. "test.txt"

-- 检查是否在客户端环境
local function IsClient()
    -- 方法1: 检查 ThePlayer 是否存在（仅客户端）
    if ThePlayer then return true end

    -- 方法2: 检查 TheNet
    if TheNet and not TheNet:GetIsServer() then
        return true
    end

    return false
end

-- 测试写入文件
local function TestWrite()
    if not IsClient() then
        print("[DST AI] Not on client, skipping file I/O test")
        return false
    end

    print("[DST AI] Attempting to write to: " .. TEST_FILE)
    print("[DST AI] io exists: " .. tostring(io ~= nil))

    local file, err = io.open(TEST_FILE, "w")
    print("[DST AI] io.open result: " .. tostring(file))
    print("[DST AI] io.open error: " .. tostring(err))

    if file then
        file:write("Hello from DST Mod!\n")
        file:close()
        print("[DST AI] SUCCESS: Wrote to file")

        -- 验证文件
        local read_file = io.open(TEST_FILE, "r")
        if read_file then
            local content = read_file:read("*all")
            read_file:close()
            print("[DST AI] File content: " .. content)
        end

        return true
    else
        print("[DST AI] ERROR: Could not open file for writing")
        return false
    end
end

-- 只在客户端执行
AddPlayerPostInit(function(player)
    print("[DST AI] AddPlayerPostInit - Player: " .. (player.name or "Unknown"))
    print("[DST AI] IsClient(): " .. tostring(IsClient()))
    print("[DST AI] ThePlayer: " .. tostring(ThePlayer ~= nil))

    -- 延迟执行测试
    player:DoTaskInTime(1, function()
        print("[DST AI] ===== Starting File I/O Test =====")
        TestWrite()
        print("[DST AI] ===== Test Complete =====")
    end)
end)

-- Mod加载完成
print("[DST AI] DST AI Player (File I/O Test) loaded")
print("[DST AI] IsClient at load: " .. tostring(IsClient()))
