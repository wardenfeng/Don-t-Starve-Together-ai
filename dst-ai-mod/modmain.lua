name = "DST AI Player"
description = "AI controls your DST character through MCP."
author = "AI Assistant"
version = "1.0.0"

forumthread = ""
api_version = 10
dst_compatible = true
all_clients_require_mod = false
client_only_mod = true

server_filter_tags = {"character", "utility"}

configuration_options = {}

-- 测试：Mod加载时写入测试文件
AddPlayerPostInit(function(player)
    print("[DST AI] Mod loaded for player: " .. (player.name or "Unknown"))

    -- 测试写入文件
    local sync_dir = os.getenv("USERPROFILE") .. "\\dst-ai-sync\\"

    -- 写入测试状态
    local test_json = "{\\"v\\":1,\\"t\\":" .. tostring(GetTimeRealMS()) .. ",\\"test\\":true}"
    local file = io.open(sync_dir .. "state.txt", "w")
    if file then
        file:write(test_json)
        file:close()
        print("[DST AI] Test state written!")
    else
        print("[DST AI] ERROR: Could not write to: " .. sync_dir .. "state.txt")
    end
end)
