name = "DST AI Player (MCP)"
description = "让AI通过MCP协议自动玩饥荒联机版。Mod加载后自动启用AI控制。"
author = "AI Assistant"
version = "1.0.0"

forumthread = ""
api_version = 10

dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false
all_clients_require_mod = false
client_only_mod = true

server_filter_tags = {"character", "utility"}

configuration_options =
{
    {
        name = "sync_dir",
        label = "同步目录",
        hover = "与MCP服务器通信的文件同步目录",
        options =
        {
            {description = "%USERPROFILE%\\dst-ai-sync\\", data = "%USERPROFILE%\\dst-ai-sync\\"},
        },
        default = "%USERPROFILE%\\dst-ai-sync\\",
    },
    {
        name = "update_interval",
        label = "更新间隔(帧)",
        hover = "状态采集和命令检查的间隔帧数",
        options =
        {
            {description = "1帧 (最快)", data = 1},
            {description = "5帧", data = 5},
            {description = "10帧 (推荐)", data = 10},
            {description = "20帧", data = 20},
        },
        default = 10,
    },
    {
        name = "scan_radius",
        label = "扫描半径",
        hover = "采集周围实体的扫描范围",
        options =
        {
            {description = "10单位", data = 10},
            {description = "15单位", data = 15},
            {description = "20单位 (推荐)", data = 20},
            {description = "30单位", data = 30},
        },
        default = 20,
    },
    {
        name = "max_entities",
        label = "最大实体数",
        hover = "最多采集的周围实体数量",
        options =
        {
            {description = "10个", data = 10},
            {description = "15个 (推荐)", data = 15},
            {description = "20个", data = 20},
            {description = "30个", data = 30},
        },
        default = 15,
    },
}
